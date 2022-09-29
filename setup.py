#!/usr/bin/env python3
from setuptools import setup

# skill_id=package_name:SkillClass
PLUGIN_ENTRY_POINT = 'ovos-skill-homescreen.openvoiceos=ovos_skill_homescreen:OVOSHomescreenSkill'


setup(
    # this is the package name that goes on pip
    name='ovos-skill-homescreen',
    version='0.0.1',
    description='OVOS homescreen skill plugin',
    url='https://github.com/OpenVoiceOS/skill-ovos-homescreen',
    author='Aix',
    author_email='aix.m@outlook.com',
    license='Apache-2.0',
    package_dir={"ovos_skill_homescreen": ""},
    package_data={'ovos_skill_homescreen': ["vocab/*", "ui/*", "skill/*, *.json"]},
    packages=['ovos_skill_homescreen'],
    include_package_data=True,
    install_requires=["astral==1.4", "arrow==0.12.0"],
    keywords='ovos skill plugin',
    entry_points={'ovos.plugin.skill': PLUGIN_ENTRY_POINT}
)
