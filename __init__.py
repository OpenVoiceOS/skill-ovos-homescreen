# Copyright 2022, OpenVoiceOS.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import datetime
import os
import tempfile
from typing import Dict, List, Tuple

from ovos_bus_client import Message
from ovos_config.locations import get_xdg_cache_save_path
from ovos_date_parser import get_date_strings
from ovos_utils import classproperty
from ovos_utils.lang import standardize_lang_tag
from ovos_utils.log import LOG
from ovos_utils.process_utils import RuntimeRequirements
from ovos_utils.time import now_local
from ovos_workshop.decorators import intent_handler, resting_screen_handler
from ovos_workshop.skills.api import SkillApi
from ovos_workshop.skills.ovos import OVOSSkill


class OVOSHomescreenSkill(OVOSSkill):
    def __init__(self, *args, **kwargs):
        self.notifications_storage_model = []
        self.selected_wallpaper_path = None
        self.selected_wallpaper = None
        self.default_provider_set = False
        self.wallpaper_collection = []
        self.rtlMode = None  # Get from config after __init__ is done

        # Populate skill IDs to use for data sources
        self.datetime_api = None
        self.skill_info_api = None

        # Media State Tracking For Widget
        # Needed for setting qml button state
        self.media_widget_player_state = None

        # Offline / Online State
        self.system_connectivity = None

        # Bus apis for skills to register with homescreen, ovos-workshop provides util methods
        # "skill_id": {"lang-code": ["utterance"]}
        self.skill_examples: Dict[str, Dict[str, List[str]]] = {}
        # "skill_id": {"icon": "xx.png", "event": "emit.this.bus.event", "name": "app name"}
        self.homescreen_apps: Dict[str, Dict[str, str]] = {}

        super().__init__(*args, **kwargs)

    @classproperty
    def runtime_requirements(self):
        return RuntimeRequirements(internet_before_load=False,
                                   network_before_load=False,
                                   gui_before_load=True,
                                   requires_internet=False,
                                   requires_network=False,
                                   requires_gui=True,
                                   no_internet_fallback=True,
                                   no_network_fallback=True,
                                   no_gui_fallback=False)

    def initialize(self):
        self.rtlMode = 1 if self.config_core.get("rtl", False) else 0

        callback_time = now_local() + datetime.timedelta(seconds=60)
        self.schedule_repeating_event(self.update_dt, callback_time, 10)

        # Handle metadata registration from skills
        self.add_event("homescreen.register.examples", self.handle_register_sample_utterances)
        self.add_event("homescreen.register.app", self.handle_register_homescreen_app)
        self.add_event("detach_skill", self.handle_deregister_skill)

        self.bus.emit(Message("homescreen.metadata.get"))

        # Handler Registration For Notifications
        self.add_event("homescreen.wallpaper.set", self.handle_set_wallpaper)
        self.add_event("ovos.notification.update_counter", self.handle_notification_widget_update)
        self.add_event("ovos.notification.update_storage_model", self.handle_notification_storage_model_update)
        self.gui.register_handler("homescreen.swipe.change.wallpaper", self.change_wallpaper)
        self.add_event("mycroft.ready", self.handle_mycroft_ready)

        # Handler Registration For Widgets
        self.add_event("ovos.widgets.timer.update", self.handle_timer_widget_manager)
        self.add_event("ovos.widgets.timer.display", self.handle_timer_widget_manager)
        self.add_event("ovos.widgets.timer.remove", self.handle_timer_widget_manager)
        self.add_event("ovos.widgets.alarm.update", self.handle_alarm_widget_manager)
        self.add_event("ovos.widgets.alarm.display", self.handle_alarm_widget_manager)
        self.add_event("ovos.widgets.alarm.remove", self.handle_alarm_widget_manager)

        # Handler For Weather Response
        self.bus.on("skill-ovos-weather.openvoiceos.weather.response", self.update_weather_response)

        # Handler For OCP Player State Tracking
        self.bus.on("gui.player.media.service.sync.status", self.handle_media_player_state_update)
        self.bus.on("ovos.common_play.track_info.response", self.handle_media_player_widget_update)

        # Handler For Offline Widget
        self.bus.on("mycroft.network.connected", self.on_network_connected)
        self.bus.on("mycroft.internet.connected", self.on_internet_connected)
        self.bus.on("enclosure.notify.no_internet", self.on_no_internet)

        # Handle Screenshot Response
        self.bus.on("ovos.display.screenshot.get.response", self.screenshot_taken)

        self.collect_wallpapers()
        SkillApi.connect_bus(self.bus)
        self._load_skill_apis()

        self.schedule_repeating_event(self.update_weather, callback_time, 900)
        self.schedule_repeating_event(self.update_examples, callback_time, 900)

        self.bus.on("ovos.wallpaper.manager.loaded", self.register_homescreen_wallpaper_provider)
        self.bus.on(f"{self.skill_id}.get.wallpaper.collection", self.supply_wallpaper_collection)
        self.bus.on("ovos.wallpaper.manager.setup.default.provider.response", self.handle_default_provider_response)

        # We can't depend on loading order, so send a registration request
        # Regardless on startup
        self.register_homescreen_wallpaper_provider()

        # Get / Set the default wallpaper
        # self.selected_wallpaper = self.settings.get(
        #     "wallpaper") or "default.jpg"

        self.bus.emit(Message("mycroft.device.show.idle"))

    #############
    # bus apis
    def handle_register_sample_utterances(self, message: Message):
        """a skill is registering utterance examples to render on idle screen"""
        lang = standardize_lang_tag(message.data["lang"])
        skill_id = message.data["skill_id"]
        examples = message.data["utterances"]
        if skill_id not in self.skill_examples:
            self.skill_examples[skill_id] = {}
        self.skill_examples[skill_id][lang] = examples
        LOG.info(f"Registered utterance examples from: {skill_id}")

    def handle_register_homescreen_app(self, message: Message):
        """a skill is registering an icon + bus event to show in app drawer (bottom pill button)"""
        skill_id = message.data["skill_id"]
        icon = message.data["icon"]
        event = message.data["event"]
        name = message.data["name"]
        self.homescreen_apps[skill_id] = {"icon": icon, "event": event, "name": name}
        LOG.info(f"Registered homescreen app from: {skill_id}")

    def handle_deregister_skill(self, message: Message):
        """skill unloaded, stop showing it's example utterances and app launcher icon"""
        skill_id = message.data["skill_id"]
        if skill_id in self.skill_examples:
            self.skill_examples.pop(skill_id)
        if skill_id in self.homescreen_apps:
            self.homescreen_apps.pop(skill_id)

    #############
    # skill properties
    @property
    def examples_enabled(self):
        # A variable to turn on/off the example text
        return self.settings.get("examples_enabled",
                                 self.settings.get("examples_skill") is not None)

    @property
    def examples_skill_id(self):
        if not self.examples_enabled:
            return None
        return self.settings.get("examples_skill")

    @property
    def datetime_skill_id(self):
        return self.settings.get("datetime_skill")

    #####################################################################
    # Homescreen Registration & Handling
    @resting_screen_handler("OVOSHomescreen")
    def handle_idle(self, message):
        self._load_skill_apis()
        LOG.debug('Activating OVOSHomescreen')
        apps = self.build_voice_applications_model()
        self.gui['wallpaper_path'] = self.selected_wallpaper_path
        self.gui['selected_wallpaper'] = self.selected_wallpaper
        self.gui['notification'] = {}
        self.gui["notification_model"] = self.notifications_storage_model
        self.gui["system_connectivity"] = "offline"
        self.gui["applications_model"] = apps
        self.gui["persistent_menu_hint"] = self.settings.get("persistent_menu_hint", False)
        self.gui["apps_enabled"] = bool(apps)

        try:
            self.update_dt()
        except Exception as e:
            LOG.error(f"Failed to update homescreen datetime: {e}")

        try:
            self.update_weather()
        except Exception as e:
            LOG.error(f"Failed to update homescreen weather: {e}")

        try:
            self.update_examples()
        except Exception as e:
            LOG.error(f"Failed to update homescreen skill examples: {e}")

        self.gui['rtl_mode'] = self.rtlMode
        self.gui['dateFormat'] = self.config_core.get("date_format") or "DMY"
        self.gui.show_page("idle")
        self.bus.emit(Message("ovos.homescreen.displayed"))

    def update_examples(self):
        """
        Loads or updates skill examples via the skill_info_api.
        """
        examples = []
        if self.skill_info_api:
            examples = self.skill_info_api.skill_info_examples()
        elif self.settings.get("examples_enabled"):
            for _skill_id, data in self.skill_examples.items():
                examples += data.get(self.lang, [])

        if examples:
            self.gui['skill_examples'] = {"examples": examples}
            self.gui['skill_info_enabled'] = self.examples_enabled
        else:
            LOG.warning("no utterance examples registered with homescreen")
            self.gui['skill_info_enabled'] = False
        self.gui['skill_info_prefix'] = self.settings.get("examples_prefix", False)

    def _update_datetime_from_api(self):
        """
        Update the GUI with date/time from the configured Skill API
        """
        LOG.debug("Getting date info via skill api")
        time_string = self.datetime_api.get_display_current_time()
        date_string = self.datetime_api.get_display_date()
        weekday_string = self.datetime_api.get_weekday()
        # The datetime skill decides what order day and month are returned
        day_string, month_string = \
            self.datetime_api.get_month_date().split(maxsplit=1)
        year_string = self.datetime_api.get_year()
        self.gui["time_string"] = time_string
        self.gui["date_string"] = date_string
        self.gui["weekday_string"] = weekday_string
        self.gui['day_string'] = day_string
        self.gui["month_string"] = month_string
        self.gui["year_string"] = year_string

    def update_dt(self):
        """
        Loads or updates date/time via the datetime_api.
        """
        if not self.datetime_api and self.datetime_skill_id:
            LOG.debug("Requested update before datetime API loaded")
            self._load_skill_apis()
        if self.datetime_api:
            try:
                self._update_datetime_from_api()
                return
            except Exception as e:
                LOG.exception(f"Skill API error: {e}")

        date_string_object = get_date_strings(dt=now_local(),
                                              date_format=self.config_core.get("date_format", "DMY"),
                                              time_format=self.config_core.get("time_format", "full"),
                                              lang=self.lang)
        # LOG.debug(f"Date info {self.lang}: {date_string_object}")
        time_string = date_string_object.get("time_string")
        date_string = date_string_object.get("date_string")
        weekday_string = date_string_object.get("weekday_string")
        day_string = date_string_object.get("day_string")
        month_string = date_string_object.get("month_string")
        year_string = date_string_object.get("year_string")

        self.gui["time_string"] = time_string
        self.gui["date_string"] = date_string
        self.gui["weekday_string"] = weekday_string
        self.gui['day_string'] = day_string
        self.gui["month_string"] = month_string
        self.gui["year_string"] = year_string

    def update_weather(self):
        """
        Loads or updates weather via the weather_api.
        """
        self.bus.emit(Message("skill-ovos-weather.openvoiceos.weather.request"))

    def update_weather_response(self, message=None):
        """
        Weather Update Response
        """
        current_weather_report = message.data.get("report")
        if current_weather_report:
            self.gui["weather_api_enabled"] = True
            self.gui["weather_code"] = current_weather_report.get("weather_code")
            self.gui["weather_temp"] = current_weather_report.get("weather_temp")
        else:
            self.gui["weather_api_enabled"] = False

    def on_network_connected(self, message):
        self.system_connectivity = "network"
        self.gui["system_connectivity"] = self.system_connectivity

    def on_internet_connected(self, message):
        self.system_connectivity = "online"
        self.gui["system_connectivity"] = self.system_connectivity

    def on_no_internet(self, message):
        self.system_connectivity = "offline"
        self.gui["system_connectivity"] = self.system_connectivity

    #####################################################################
    # Homescreen Wallpaper Provider and Consumer Handling
    # Follows OVOS PHAL Wallpaper Manager API
    def collect_wallpapers(self):
        # this path is hardcoded in ovos_gui.constants and follows XDG spec
        GUI_CACHE_PATH = get_xdg_cache_save_path('ovos_gui')

        def_wallpaper_collection = []

        for fn in os.listdir(f'{self.root_dir}/gui/qt5/wallpapers'):
            # we use cache path to ensure files are available to other docker containers etc
            # on load the full "gui" folder is cached in the standard dir "{GUI_CACHE_PATH}/{self.skill_id}"
            def_wallpaper_collection.append(f"{GUI_CACHE_PATH}/{self.skill_id}/qt5/wallpapers/{fn}")

        self.wallpaper_collection = def_wallpaper_collection

    def register_homescreen_wallpaper_provider(self, message=None):
        self.bus.emit(Message("ovos.wallpaper.manager.register.provider", {
            "provider_name": self.skill_id,
            "provider_display_name": "OVOSHomescreen"
        }))

    def supply_wallpaper_collection(self, message):
        self.bus.emit(Message("ovos.wallpaper.manager.collect.collection.response", {
            "provider_name": self.skill_id,
            "wallpaper_collection": self.wallpaper_collection
        }))
        # We need to call this here as we know wallpaper collection is ready
        if not self.default_provider_set:
            self.setup_default_provider()

    def setup_default_provider(self):
        self.bus.emit(Message("ovos.wallpaper.manager.setup.default.provider", {
            "provider_name": self.skill_id,
            "default_wallpaper_name": self.settings.get("wallpaper", "default.jpg")
        }))

    def handle_default_provider_response(self, message):
        self.default_provider_set = True
        url = message.data.get("url")
        self.selected_wallpaper_path, self.selected_wallpaper = self.extract_wallpaper_info(url)
        self.gui['wallpaper_path'] = self.selected_wallpaper_path
        self.gui['selected_wallpaper'] = self.selected_wallpaper

    @intent_handler("change.wallpaper.intent")
    def change_wallpaper(self, _):
        self.bus.emit(Message("ovos.wallpaper.manager.change.wallpaper"))

    def get_wallpaper_idx(self, filename):
        try:
            index_element = self.wallpaper_collection.index(filename)
            return index_element
        except ValueError:
            return None

    def handle_set_wallpaper(self, message):
        url = message.data.get("url")
        self.selected_wallpaper_path, self.selected_wallpaper = self.extract_wallpaper_info(url)
        self.gui['wallpaper_path'] = self.selected_wallpaper_path
        self.gui['selected_wallpaper'] = self.selected_wallpaper

    @staticmethod
    def extract_wallpaper_info(wallpaper: str) -> Tuple[str, str]:
        wallpaper_split = wallpaper.rsplit('/', 1)
        wallpaper_path = wallpaper_split[0] + "/"
        wallpaper_filename = wallpaper_split[1]
        return wallpaper_path, wallpaper_filename

    #####################################################################
    # Manage notifications widget

    def handle_notification_widget_update(self, message):
        # Receives notification counter update
        # Emits request to update storage model on counter update
        notifcation_count = message.data.get("notification_counter", "")
        self.gui["notifcation_counter"] = notifcation_count
        self.bus.emit(Message("ovos.notification.api.request.storage.model"))

    def handle_notification_storage_model_update(self, message):
        # Receives updated storage model and forwards it to widget
        self.notifications_storage_model = message.data.get("notification_model", "")
        self.gui["notification_model"] = self.notifications_storage_model

    #####################################################################
    # Misc
    def shutdown(self):
        self.cancel_all_repeating_events()

    def handle_mycroft_ready(self, message):
        self._load_skill_apis()

    def _load_skill_apis(self):
        """
        Loads weather, date/time, and examples skill APIs
        """
        # Import Date Time Skill As Date Time Provider if configured (default LF)
        try:
            if not self.datetime_api and self.datetime_skill_id:
                self.datetime_api = SkillApi.get(self.datetime_skill_id)
                assert self.datetime_api.get_display_current_time is not None
                assert self.datetime_api.get_display_date is not None
                assert self.datetime_api.get_weekday is not None
                assert self.datetime_api.get_year is not None
        except AssertionError as e:
            LOG.error(f"missing API method: {e}")
            self.datetime_api = None
        except Exception as e:
            LOG.error(f"Failed to import DateTime Skill: {e}")
            self.datetime_api = None

        # Import Skill Info Skill if configured (default OSM)
        if not self.skill_info_api and self.examples_skill_id:
            try:
                self.skill_info_api = SkillApi.get(self.examples_skill_id)
                assert self.skill_info_api.skill_info_examples is not None
            except AssertionError as e:
                LOG.error(f"missing API method: {e}")
                self.skill_info_api = None
            except Exception as e:
                LOG.error(f"Failed to import Info Skill: {e}")
                self.skill_info_api = None

    def build_voice_applications_model(self) -> List[Dict[str, str]]:
        """Build a list of voice applications for the GUI model.

           Returns:
                List[Dict[str, str]]: List of application metadata containing
                    name, thumbnail path, and action event
        """
        return [{"name": data["name"], "thumbnail": data["icon"], "action": data["event"]}
                for skill_id, data in self.homescreen_apps.items()]

    #####################################################################
    # Handle Widgets
    def handle_timer_widget_manager(self, message):
        timerWidget = message.data.get("widget", {})
        self.gui.send_event("ovos.timer.widget.manager.update", timerWidget)

    def handle_alarm_widget_manager(self, message):
        alarmWidget = message.data.get("widget", {})
        self.gui.send_event("ovos.alarm.widget.manager.update", alarmWidget)

    #### Media Player Widget UI Handling - Replaces Examples UI Bar ####
    def handle_media_player_state_update(self, message):
        """
        Handles OCP State Updates
        """
        player_state = message.data.get("state")
        if player_state == 1:
            self.bus.emit(Message("ovos.common_play.track_info"))
            self.media_widget_player_state = "playing"
            self.gui.send_event("ovos.media.widget.manager.update", {
                "enabled": True,
                "widget": {},
                "state": "playing"
            })
        elif player_state == 0:
            self.media_widget_player_state = "stopped"
            self.gui.send_event("ovos.media.widget.manager.update", {
                "enabled": False,
                "widget": {},
                "state": "stopped"
            })
        elif player_state == 2:
            self.bus.emit(Message("ovos.common_play.track_info"))
            self.media_widget_player_state = "paused"
            self.gui.send_event("ovos.media.widget.manager.update", {
                "enabled": True,
                "widget": {},
                "state": "paused"
            })

    def handle_media_player_widget_update(self, message=None):
        self.gui.send_event("ovos.media.widget.manager.update", {
            "enabled": True,
            "widget": message.data,
            "state": self.media_widget_player_state
        })

    ######################################################################
    # Handle Screenshot
    @intent_handler("take.screenshot.intent")
    def take_screenshot(self, message):
        folder_path = self.settings.get("screenshot_folder", "")

        if not folder_path:
            folder_path = os.path.expanduser('~') + "/Pictures"

        if not os.path.exists(folder_path):
            try:
                os.makedirs(folder_path, exist_ok=True)
            except OSError as e:
                LOG.error("Could not create screenshot folder: " + str(e))
                folder_path = tempfile.gettempdir()

        self.bus.emit(Message("ovos.display.screenshot.get", {"folderpath": folder_path}))

    def screenshot_taken(self, message):
        result = message.data.get("result")
        display_message = f"Screenshot saved to {result}"
        self.gui.show_notification(display_message)
