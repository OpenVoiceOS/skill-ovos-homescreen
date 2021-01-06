import sys
import os
import time
import datetime
import importlib.util
import json
from os import path
from mycroft.skills.core import MycroftSkill, resting_screen_handler
from mycroft.skills.skill_loader import load_skill_module
from mycroft.util.log import getLogger
from mycroft.skills.skill_manager import SkillManager

__author__ = 'aix'

LOGGER = getLogger(__name__)


class OVOSHomescreen(MycroftSkill):

    # The constructor of the skill, which calls MycroftSkill's constructor
    def __init__(self):
        super(OVOSHomescreen, self).__init__(name="OVOSHomescreen")
        self.skill_manager = None

    def initialize(self):
        now = datetime.datetime.now()
        callback_time = (datetime.datetime(now.year, now.month, now.day,
                                           now.hour, now.minute) +
                         datetime.timedelta(seconds=60))
        self.schedule_repeating_event(self.update_dt, callback_time, 10)
        self.skill_manager = SkillManager(self.bus)

        # Make Import For TimeData
        root_dir = self.root_dir.rsplit('/', 1)[0]
        try:
            time_date_path = str(
                root_dir) + "/mycroft-date-time.mycroftai/__init__.py"
            time_date_id = "datetimeskill"
            datetimeskill = load_skill_module(time_date_path, time_date_id)
            from datetimeskill import TimeSkill
            self.dt_skill = TimeSkill()
        except:
            print("Failed To Import DateTime Skill")

    @resting_screen_handler('OVOSHomescreen')
    def handle_idle(self, message):
        self.gui.clear()
        self.log.debug('Activating Time/Date resting page')
        self.gui['time_string'] = self.dt_skill.get_display_current_time()
        self.gui['ampm_string'] = ''
        self.gui['date_string'] = self.dt_skill.get_display_date()
        self.gui['weekday_string'] = self.dt_skill.get_weekday()
        self.gui['month_string'] = self.dt_skill.get_month_date()
        self.gui['year_string'] = self.dt_skill.get_year()
        self.gui.show_page('homescreen.qml')

    def handle_idle_update_time(self):
        self.gui['time_string'] = self.dt_skill.get_display_current_time()

    def update_dt(self):
        self.gui['time_string'] = self.dt_skill.get_display_current_time()
        self.gui['date_string'] = self.dt_skill.get_display_date()
        self.gui['weekday_string'] = self.dt_skill.get_weekday()
        self.gui['month_string'] = self.dt_skill.get_month_date()
        self.gui['year_string'] = self.dt_skill.get_year()

    def stop(self):
        pass


def create_skill():
    return OVOSHomescreen()
