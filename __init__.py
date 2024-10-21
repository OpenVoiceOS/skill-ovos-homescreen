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
from os import environ, listdir, path

from lingua_franca.format import get_date_strings
from ovos_bus_client import Message
from ovos_config.locations import get_xdg_cache_save_path
from ovos_utils import classproperty
from ovos_utils.log import LOG
from ovos_utils.time import now_local
from ovos_utils.process_utils import RuntimeRequirements
from ovos_workshop.decorators import intent_handler, resting_screen_handler
from ovos_workshop.skills.api import SkillApi
from ovos_workshop.skills.ovos import OVOSSkill


class OVOSHomescreenSkill(OVOSSkill):
    def __init__(self, *args, **kwargs):
        self.notifications_storage_model = []
        self.loc_wallpaper_folder = None
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
        self.loc_wallpaper_folder = self.file_system.path + '/wallpapers/'
        self.rtlMode = 1 if self.config_core.get("rtl", False) else 0

        callback_time = now_local() + datetime.timedelta(seconds=60)
        self.schedule_repeating_event(self.update_dt, callback_time, 10)

        # Handler Registration For Notifications
        self.add_event("homescreen.wallpaper.set",
                       self.handle_set_wallpaper)
        self.add_event("ovos.notification.update_counter",
                       self.handle_notification_widget_update)
        self.add_event("ovos.notification.update_storage_model",
                       self.handle_notification_storage_model_update)
        self.gui.register_handler("homescreen.swipe.change.wallpaper",
                                  self.change_wallpaper)
        self.add_event("mycroft.ready", self.handle_mycroft_ready)

        # Handler Registration For Widgets
        self.add_event("ovos.widgets.timer.update",
                       self.handle_timer_widget_manager)
        self.add_event("ovos.widgets.timer.display",
                       self.handle_timer_widget_manager)
        self.add_event("ovos.widgets.timer.remove",
                       self.handle_timer_widget_manager)

        self.add_event("ovos.widgets.alarm.update",
                       self.handle_alarm_widget_manager)
        self.add_event("ovos.widgets.alarm.display",
                       self.handle_alarm_widget_manager)
        self.add_event("ovos.widgets.alarm.remove",
                       self.handle_alarm_widget_manager)

        if not self.file_system.exists("wallpapers"):
            os.mkdir(path.join(self.file_system.path, "wallpapers"))

        # Handler For Weather Response
        self.bus.on("skill-ovos-weather.openvoiceos.weather.response", self.update_weather_response)

        # Handler For OCP Player State Tracking
        self.bus.on("gui.player.media.service.sync.status",
                    self.handle_media_player_state_update)
        self.bus.on("ovos.common_play.track_info.response",
                    self.handle_media_player_widget_update)

        # Handler For Offline Widget
        self.bus.on("mycroft.network.connected", self.on_network_connected)
        self.bus.on("mycroft.internet.connected", self.on_internet_connected)
        self.bus.on("enclosure.notify.no_internet", self.on_no_internet)

        # Handle Screenshot Response
        self.bus.on("ovos.display.screenshot.get.response",
                    self.screenshot_taken)

        self.collect_wallpapers()
        SkillApi.connect_bus(self.bus)
        self._load_skill_apis()

        self.schedule_repeating_event(self.update_weather, callback_time, 900)
        self.schedule_repeating_event(self.update_examples, callback_time, 900)

        self.bus.on("ovos.wallpaper.manager.loaded",
                    self.register_homescreen_wallpaper_provider)
        
        self.bus.on(f"{self.skill_id}.get.wallpaper.collection",
                    self.supply_wallpaper_collection)
        
        self.bus.on("ovos.wallpaper.manager.setup.default.provider.response",
                    self.handle_default_provider_response)
        
        # We can't depend on loading order, so send a registration request
        # Regardless on startup
        self.register_homescreen_wallpaper_provider()

        # Get / Set the default wallpaper
        # self.selected_wallpaper = self.settings.get(
        #     "wallpaper") or "default.jpg"

        self.bus.emit(Message("mycroft.device.show.idle"))

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
        self.gui['wallpaper_path'] = self.selected_wallpaper_path
        self.gui['selected_wallpaper'] = self.selected_wallpaper
        self.gui['notification'] = {}
        self.gui["notification_model"] = self.notifications_storage_model
        self.gui["system_connectivity"] = "offline"
        self.gui["applications_model"] = self.build_voice_applications_model()
        self.gui["persistent_menu_hint"] = self.settings.get("persistent_menu_hint", False)

        try:
            self.update_dt()
            self.update_weather()
            self.update_examples()
        except Exception as e:
            LOG.error(e)

        self.gui['rtl_mode'] = self.rtlMode
        self.gui['dateFormat'] = self.config_core.get("date_format") or "DMY"
        self.gui.show_page("idle")
        self.bus.emit(Message("ovos.homescreen.displayed"))

    def update_examples(self):
        """
        Loads or updates skill examples via the skill_info_api.
        """
        if self.skill_info_api:
            self.gui['skill_examples'] = {"examples": self.skill_info_api.skill_info_examples()}
        else:
            try:
                from ovos_skills_manager.utils import get_skills_examples
                skill_examples = get_skills_examples(randomize=self.settings.get("randomize_examples", True))
                self.gui['skill_examples'] = {"examples": skill_examples}
            except ImportError:
                self.settings["examples_enabled"] = False

        self.gui['skill_info_enabled'] = self.examples_enabled
        self.gui['skill_info_prefix'] = self.settings.get("examples_prefix", False)

    def _update_datetime_from_api(self):
        """
        Update the GUI with date/time from the configured Skill API
        """
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

        date_string_object = get_date_strings(
            date_format=self.config_core.get("date_format", "MDY"),
            time_format=self.config_core.get("time_format", "full"),
            lang=self.lang)
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

        def_wallpaper_collection, loc_wallpaper_collection = [], []

        for _, _, filenames in os.walk(f'{self.root_dir}/ui/wallpapers/'):
            # we use cache path to ensure files are available to other docker containers etc
            # on load the full "ui" folder is cached in the standard dir
            def_wallpaper_collection = [f"{GUI_CACHE_PATH}/qt5/wallpapers/{wallpaper}"
                                        for wallpaper in filenames]

        for root, _, filenames in os.walk(self.loc_wallpaper_folder):
            loc_wallpaper_collection = [os.path.join(root, wallpaper) for wallpaper in filenames]

        self.wallpaper_collection = def_wallpaper_collection + loc_wallpaper_collection
        
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
        self.selected_wallpaper_path = self.extract_wallpaper_info(url)[0] 
        self.selected_wallpaper = self.extract_wallpaper_info(url)[1]
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
        self.selected_wallpaper_path = self.extract_wallpaper_info(url)[0] 
        self.selected_wallpaper = self.extract_wallpaper_info(url)[1]
        self.gui['wallpaper_path'] = self.selected_wallpaper_path
        self.gui['selected_wallpaper'] = self.selected_wallpaper

    def extract_wallpaper_info(self, wallpaper):
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

    #####################################################################
    # Build Voice Applications Model
    # TODO - handle this via bus, this was a standard from plasma bigscreen which we never really adopted,
    #  and they dropped "voice apps" so there is nothing left to be compatible with

    def find_icon_full_path(self, icon_name):
        localuser = environ.get('USER')
        folder_search_paths = ["/usr/share/icons/", "/usr/local/share/icons/",
                               f"/home/{localuser}/.local/share/icons/"]
        for folder_search_path in folder_search_paths:
            # SVG extension
            icon_full_path = folder_search_path + icon_name + ".svg"
            if path.exists(icon_full_path):
                return icon_full_path
            # PNG extension
            icon_full_path = folder_search_path + icon_name + ".png"
            if path.exists(icon_full_path):
                return icon_full_path
            # JPEG extension
            icon_full_path = folder_search_path + icon_name + ".jpg"
            if path.exists(icon_full_path):
                return icon_full_path

    def parse_desktop_file(self, file_path):
        # TODO - handle this via bus, this was a standard from plasma bigscreen which we never really adopted,
        #  and they dropped "voice apps" so there is nothing left to be compatible with
        if path.isfile(file_path) and path.splitext(file_path)[1] == ".desktop":

            if path.isfile(file_path) and path.isfile(file_path) and path.getsize(file_path) > 0:

                with open(file_path, "r") as f:
                    file_contents = f.read()

                    name_start = file_contents.find("Name=")
                    name_end = file_contents.find("\n", name_start)
                    name = file_contents[name_start + 5:name_end]

                    icon_start = file_contents.find("Icon=")
                    icon_end = file_contents.find("\n", icon_start)
                    icon_name = file_contents[icon_start + 5:icon_end]
                    icon = self.find_icon_full_path(icon_name)

                    exec_start = file_contents.find("Exec=")
                    exec_end = file_contents.find("\n", exec_start)
                    exec_line = file_contents[exec_start + 5:exec_end]
                    exec_array = exec_line.split(" ")
                    for arg in exec_array:
                        if arg.find("--skill=") == 0:
                            skill_name = arg.split("=")[1]
                            break
                        else:
                            skill_name = "None"
                    exec_path = skill_name

                    categories_start = file_contents.find("Categories=")
                    categories_end = file_contents.find("\n", categories_start)
                    categories = file_contents[categories_start +
                                               11:categories_end]

                    categories_list = categories.split(";")

                    if "VoiceApp" in categories_list:
                        app_entry = {
                            "name": name,
                            "thumbnail": icon,
                            "action": exec_path
                        }
                        return app_entry
                    else:
                        return None
            else:
                return None
        else:
            return None

    def build_voice_applications_model(self):
        voiceApplicationsList = []
        localuser = environ.get('USER')
        file_list = ["/usr/share/applications/", "/usr/local/share/applications/",
                     f"/home/{localuser}/.local/share/applications/"]
        for file_path in file_list:
            if os.path.isdir(file_path):
                files = listdir(file_path)
                for file in files:
                    app_dict = self.parse_desktop_file(file_path + file)
                    if app_dict is not None:
                        voiceApplicationsList.append(app_dict)

        try:
            sort_on = "name"
            decorated = [(dict_[sort_on], dict_)
                         for dict_ in voiceApplicationsList]
            decorated.sort()
            return [dict_ for (key, dict_) in decorated]

        except Exception:
            return voiceApplicationsList

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

