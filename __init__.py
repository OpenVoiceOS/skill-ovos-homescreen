import sys
import os
import time
import datetime
import importlib.util
import json
import time
from os import path
from mycroft.messagebus.message import Message
from mycroft.skills.core import MycroftSkill, resting_screen_handler
from mycroft.skills.skill_loader import load_skill_module
from mycroft.util.log import getLogger, LOG
from mycroft.skills.skill_manager import SkillManager

__author__ = 'aix'

LOGGER = getLogger(__name__)


class OVOSHomescreen(MycroftSkill):
    # The constructor of the skill, which calls MycroftSkill's constructor
    def __init__(self):
        super(OVOSHomescreen, self).__init__(name="OVOSHomescreen")
        self.skill_manager = None
        self.notifications_model = []
        self.notifications_storage_model = []

    def initialize(self):
        now = datetime.datetime.now()
        callback_time = (datetime.datetime(now.year, now.month, now.day,
                                           now.hour, now.minute) +
                         datetime.timedelta(seconds=60))
        self.schedule_repeating_event(self.update_dt, callback_time, 10)
        self.skill_manager = SkillManager(self.bus)
        
        # Handle Listner Animations
        self.gui.register_handler("homescreen.notification.set", self.handle_display_notification)
        self.gui.register_handler("homescreen.notification.pop.clear", self.handle_clear_notification_data)
        self.gui.register_handler("homescreen.notification.pop.clear.delete", self.handle_clear_delete_notification_data)
        self.gui.register_handler("homescreen.notification.storage.clear", self.handle_clear_notification_storage)
        
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
        self.gui['date_string'] = self.dt_skill.get_display_date()
        self.gui['weekday_string'] = self.dt_skill.get_weekday()
        self.gui['month_string'] = self.dt_skill.get_month_date()
        self.gui['year_string'] = self.dt_skill.get_year()
        self.gui['notification'] = {}
        self.gui["notification_model"] = {"storedmodel": self.notifications_storage_model, "count": len(self.notifications_storage_model)}
        self.gui.show_page('idle.qml')

    def handle_idle_update_time(self):
        self.gui['time_string'] = self.dt_skill.get_display_current_time()
        self.gui['date_string'] = self.dt_skill.get_display_date()
        self.gui['weekday_string'] = self.dt_skill.get_weekday()
        self.gui['month_string'] = self.dt_skill.get_month_date()
        self.gui['year_string'] = self.dt_skill.get_year()

    def update_dt(self):
        self.gui['time_string'] = self.dt_skill.get_display_current_time()
        self.gui['date_string'] = self.dt_skill.get_display_date()
        self.gui['weekday_string'] = self.dt_skill.get_weekday()
        self.gui['month_string'] = self.dt_skill.get_month_date()
        self.gui['year_string'] = self.dt_skill.get_year()

    #####################################################################
    # Manage notifications
        
    def handle_display_notification(self, message):
        """ Get Notification & Action """
        LOG.info("Got a notification")
        notification_message = {"sender": message.data.get("sender", ""), "text": message.data.get("text", ""), "action": message.data.get("action", ""), "type": message.data.get("type", "")}
        LOG.info(len(self.notifications_model))
        if notification_message not in self.notifications_model:
            LOG.info("Did not find notification in list")
            self.notifications_model.append(notification_message)
            self.gui["notifcation_counter"] = len(self.notifications_model)
            LOG.info(len(self.notifications_model))
            LOG.info("should be sending notification now")
            self.gui["notification"] = notification_message
            LOG.info("notification sent")
            time.sleep(2)
            self.bus.emit(Message("homescreen.notification.show"))
        
    def handle_clear_notification_data(self, message):
        notification_data = message.data.get("notification", "")
        self.notifications_storage_model.append(notification_data)
        LOG.info("notification should be cleared")
        LOG.info(len(self.notifications_model))
        for i in range(len(self.notifications_model)): 
            if self.notifications_model[i]['sender'] == notification_data["sender"] and self.notifications_model[i]['text'] == notification_data["text"]:
                LOG.info("notification is cleared")
                if not len(self.notifications_model) > 0:
                    del self.notifications_model[i]
                    self.notifications_model = []
                else:
                    del self.notifications_model[i]
                break

        self.gui["notification_model"] = {"storedmodel": self.notifications_storage_model, "count": len(self.notifications_storage_model)}
        
    def handle_clear_notification_storage(self, message):
        self.notifications_storage_model = []
        self.gui["notification_model"] = {"storedmodel": self.notifications_storage_model, "count": len(self.notifications_storage_model)}
    
    def handle_clear_delete_notification_data(self, message):
        notification_data = message.data.get("notification", "")
        LOG.info(len(self.notifications_model))
        for i in range(len(self.notifications_model)): 
            if self.notifications_model[i]['sender'] == notification_data["sender"] and self.notifications_model[i]['text'] == notification_data["text"]:
                if not len(self.notifications_model) > 0:
                    del self.notifications_model[i]
                    self.notifications_model = []
                else:
                    del self.notifications_model[i]
                break
        
    def stop(self):
        pass


def create_skill():
    return OVOSHomescreen()
