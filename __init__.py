import datetime
import os
import time
import requests
import json

from os import path, listdir, environ
from mycroft_bus_client import Message
from ovos_utils.log import LOG
from ovos_utils.skills import get_skills_folder

from mycroft.skills.core import resting_screen_handler, intent_file_handler, MycroftSkill
from mycroft.skills.skill_loader import load_skill_module
from mycroft.skills.api import SkillApi


class OVOSHomescreenSkill(MycroftSkill):
    # The constructor of the skill, which calls MycroftSkill's constructor
    def __init__(self):
        super(OVOSHomescreenSkill, self).__init__(name="OVOSHomescreen")
        self.notifications_storage_model = []
        self.def_wallpaper_folder = path.dirname(__file__) + '/ui/wallpapers/'
        self.loc_wallpaper_folder = None
        self.selected_wallpaper = None  # Get from config after __init__ is done
        self.wallpaper_collection = []
        self.rtlMode = None  # Get from config after __init__ is done

        # Populate skill IDs to use for data sources
        self.weather_skill = None  # Get from config after __init__ is done
        self.datetime_skill = None  # Get from config after __init__ is done
        self.skill_info_skill = None  # Get from config after __init__ is done
        self.weather_api = None
        self.datetime_api = None
        self.skill_info_api = None

        # A variable to turn on/off the example text
        self.examples_enabled = True

    def initialize(self):
        self.weather_api = None
        self.datetime_api = None
        self.skill_info_api = None
        self.loc_wallpaper_folder = self.file_system.path + '/wallpapers/'
        self.selected_wallpaper = self.settings.get(
            "wallpaper") or "default.jpg"
        self.rtlMode = 1 if self.config_core.get("rtl", False) else 0
        self.weather_skill = self.settings.get(
            "weather_skill") or "skill-ovos-weather.openvoiceos"
        self.datetime_skill = self.settings.get(
            "datetime_skill") or "skill-date-time.openvoiceos"
        self.examples_enabled = 1 if self.settings.get(
            "examples_enabled", True) else 0
        if self.examples_enabled:
            self.skill_info_skill = self.settings.get(
                "examples_skill") or "ovos-skills-info.openvoiceos"

        now = datetime.datetime.now()
        callback_time = datetime.datetime(
            now.year, now.month, now.day, now.hour, now.minute
        ) + datetime.timedelta(seconds=60)
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

        self.collect_wallpapers()
        self._load_skill_apis()

        self.schedule_repeating_event(self.update_weather, callback_time, 900)
        self.schedule_repeating_event(self.update_examples, callback_time, 900)

        self.bus.emit(Message("mycroft.device.show.idle"))

    #####################################################################
    # Homescreen Registration & Handling

    @resting_screen_handler("OVOSHomescreen")
    def handle_idle(self, _):
        self._load_skill_apis()
        LOG.debug('Activating Time/Date resting page')
        self.gui['wallpaper_path'] = self.check_wallpaper_path(
            self.selected_wallpaper)
        self.gui['selected_wallpaper'] = self.selected_wallpaper
        self.gui['notification'] = {}
        self.gui['timer_widget'] = {}
        self.gui['alarm_widget'] = {}
        self.gui["notification_model"] = {
            "storedmodel": self.notifications_storage_model,
            "count": len(self.notifications_storage_model),
        }
        self.gui["applications_model"] = self.build_voice_applications_model()

        try:
            self.update_dt()
            self.update_weather()
            self.update_examples()
        except Exception as e:
            LOG.error(e)

        self.gui['rtl_mode'] = self.rtlMode
        self.gui['dateFormat'] = self.config_core.get("date_format") or "DMY"
        self.gui.show_page("idle.qml")

    def update_examples(self):
        """
        Loads or updates skill examples via the skill_info_api.
        """
        if not self.skill_info_api:
            if not self.examples_enabled:
                LOG.warning("Examples are disabled in settings")
            else:
                LOG.warning("Requested update before skill_info API loaded")
                self._load_skill_apis()
        if self.skill_info_api:
            self.gui['skill_examples'] = {
                "examples": self.skill_info_api.skill_info_examples()}
        else:
            LOG.warning("No skill_info_api, skipping update")
        self.gui['skill_info_enabled'] = self.examples_enabled

    def update_dt(self):
        """
        Loads or updates date/time via the datetime_api.
        """
        if not self.datetime_api:
            LOG.warning("Requested update before datetime API loaded")
            self._load_skill_apis()
        if self.datetime_api:
            self.gui["time_string"] = self.datetime_api.get_display_current_time()
            self.gui["date_string"] = self.datetime_api.get_display_date()
            self.gui["weekday_string"] = self.datetime_api.get_weekday()
            self.gui['day_string'], self.gui["month_string"] = self._split_month_string(
                self.datetime_api.get_month_date())
            self.gui["year_string"] = self.datetime_api.get_year()
        else:
            LOG.warning("No datetime_api, skipping update")

    def update_weather(self):
        """
        Loads or updates weather via the weather_api.
        """
        if not self.weather_api:
            LOG.warning("Requested update before weather API loaded")
            self._load_skill_apis()
        if self.weather_api:
            current_weather_report = self.weather_api.get_current_weather_homescreen()
            self.gui["weather_api_enabled"] = True
            self.gui["weather_code"] = current_weather_report.get(
                "weather_code")
            self.gui["weather_temp"] = current_weather_report.get(
                "weather_temp")
        else:
            self.gui["weather_api_enabled"] = False
            LOG.warning("No weather_api, skipping update")

    #####################################################################
    # Wallpaper Manager

    def collect_wallpapers(self):
        def_wallpaper_collection, loc_wallpaper_collection = None, None
        for dirname, dirnames, filenames in os.walk(self.def_wallpaper_folder):
            def_wallpaper_collection = filenames

        for dirname, dirnames, filenames in os.walk(self.loc_wallpaper_folder):
            loc_wallpaper_collection = filenames

        self.wallpaper_collection = def_wallpaper_collection + loc_wallpaper_collection

    @intent_file_handler("change.wallpaper.intent")
    def change_wallpaper(self, _):
        # Get Current Wallpaper idx
        current_idx = self.get_wallpaper_idx(self.selected_wallpaper)
        collection_length = len(self.wallpaper_collection) - 1
        if not current_idx == collection_length:
            fidx = current_idx + 1
            self.selected_wallpaper = self.wallpaper_collection[fidx]
            self.settings["wallpaper"] = self.wallpaper_collection[fidx]

        else:
            self.selected_wallpaper = self.wallpaper_collection[0]
            self.settings["wallpaper"] = self.wallpaper_collection[0]

        self.gui['wallpaper_path'] = self.check_wallpaper_path(
            self.selected_wallpaper)
        self.gui['selected_wallpaper'] = self.selected_wallpaper

    def get_wallpaper_idx(self, filename):
        try:
            index_element = self.wallpaper_collection.index(filename)
            return index_element
        except ValueError:
            return None

    def handle_set_wallpaper(self, message):
        image_url = message.data.get("url", "")
        now = datetime.datetime.now()
        setname = "wallpaper-" + now.strftime("%H%M%S") + ".jpg"
        if image_url:
            print(image_url)
            response = requests.get(image_url)
            with self.file_system.open(path.join("wallpapers", setname), "wb") as my_file:
                my_file.write(response.content)
                my_file.close()
            self.collect_wallpapers()
            cidx = self.get_wallpaper_idx(setname)
            self.selected_wallpaper = self.wallpaper_collection[cidx]
            self.settings["wallpaper"] = self.wallpaper_collection[cidx]

            self.gui['wallpaper_path'] = self.check_wallpaper_path(setname)
            self.gui['selected_wallpaper'] = self.selected_wallpaper

    def check_wallpaper_path(self, wallpaper):
        file_def_check = self.def_wallpaper_folder + wallpaper
        file_loc_check = self.loc_wallpaper_folder + wallpaper
        if path.exists(file_def_check):
            return self.def_wallpaper_folder
        elif path.exists(file_loc_check):
            return self.loc_wallpaper_folder

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
        notification_model = message.data.get("notification_model", "")
        self.gui["notification_model"] = notification_model

    #####################################################################
    # Misc

    def stop(self):
        pass

    def shutdown(self):
        self.cancel_all_repeating_events()

    def handle_mycroft_ready(self, _):
        self._load_skill_apis()

    def _load_skill_apis(self):
        """
        Loads weather, date/time, and examples skill APIs
        """
        try:
            if not self.weather_api:
                self.weather_api = SkillApi.get(self.weather_skill)
        except Exception as e:
            LOG.error(f"Failed To Import Weather Skill: {e}")

        try:
            if not self.skill_info_api:
                self.skill_info_api = SkillApi.get(
                    self.skill_info_skill) or None
        except Exception as e:
            LOG.error(f"Failed To Import OVOS Info Skill: {e}")

        # Import Date Time Skill As Date Time Provider
        try:
            if not self.datetime_api:
                self.datetime_api = SkillApi.get(self.datetime_skill)
        except Exception as e:
            LOG.error(f"Failed to import DateTime Skill: {e}")

        # TODO: Depreciate this
        if not self.datetime_api:
            try:
                root_dir = self.root_dir.rsplit("/", 1)[0]
                time_date_path = str(root_dir) + \
                    f"/{self.datetime_skill}/__init__.py"
                time_date_id = "datetimeskill"
                datetimeskill = load_skill_module(time_date_path, time_date_id)
                from datetimeskill import TimeSkill

                self.datetime_api = TimeSkill()
            except Exception as e:
                LOG.error(f"Failed To Import DateTime Skill: {e}")

    def _split_month_string(self, month_date: str) -> list:
        """
        Splits a month+date string into month and date (i.e. "August 06" -> ["August", "06"])
        :param month_date: formatted month and day of month ("August 06" or "06 August")
        :return: [day, month]
        """
        month_string = month_date.split(" ")
        if self.config_core.get('date_format') == 'MDY':
            day_string = month_string[1]
            month_string = month_string[0]
        else:
            day_string = month_string[0]
            month_string = month_string[1]

        return [day_string, month_string]

    #####################################################################
    # Build Voice Applications Model
    
    def find_icon_full_path(self, icon_name):
        localuser = environ['USER']
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
        localuser = environ['USER']
        file_list = ["/usr/share/applications/", "/usr/local/share/applications/",
                     f"/home/{localuser}/.local/share/applications/"]
        for file_path in file_list:
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
        self.gui['timer_widget'] = timerWidget
        
    def handle_alarm_widget_manager(self, message):
        alarmWidget = message.data.get("widget", {})
        self.gui['alarm_widget'] = alarmWidget

def create_skill():
    return OVOSHomescreenSkill()
