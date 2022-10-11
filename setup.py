#!/usr/bin/env python3
from setuptools import setup
from os import path, walk

# from github to ensure standard skill_id
SKILL_NAME = "skill-ovos-homescreen"
SKILL_AUTHOR = "OpenVoiceOS"
SKILL_PKG = SKILL_NAME.replace('-', '_')
# skill_id=package_name:SkillClass
PLUGIN_ENTRY_POINT = f'{SKILL_NAME}.{SKILL_AUTHOR.lower()}={SKILL_PKG}:OVOSHomescreenSkill'


def get_requirements(requirements_filename: str):
    requirements_file = path.join(path.abspath(path.dirname(__file__)),
                                  requirements_filename)
    with open(requirements_file, 'r', encoding='utf-8') as r:
        requirements = r.readlines()
    requirements = [r.strip() for r in requirements if r.strip()
                    and not r.strip().startswith("#")]
    return requirements


def find_resource_files():
    resource_base_dirs = ("locale", "ui", "vocab", "dialog", "regex", "skill")
    base_dir = path.dirname(__file__)
    package_data = ["*.json"]
    for res in resource_base_dirs:
        if path.isdir(path.join(base_dir, res)):
            for (directory, _, files) in walk(path.join(base_dir, res)):
                if files:
                    package_data.append(
                        path.join(directory.replace(base_dir, "").lstrip('/'),
                                  '*'))
    # print(package_data)
    return package_data


with open("README.md", "r") as f:
    long_description = f.read()

with open("./version.py", "r", encoding="utf-8") as v:
    for line in v.readlines():
        if line.startswith("__version__"):
            if '"' in line:
                version = line.split('"')[1]
            else:
                version = line.split("'")[1]

setup(
    # this is the package name that goes on pip
    name='ovos-skill-homescreen',
    version=version,
    description='OVOS skill plugin',
    long_description=long_description,
    url=f'https://github.com/{SKILL_AUTHOR}/{SKILL_NAME}',
    author='Aix',
    author_email='aix.m@outlook.com',
    license='Apache-2.0',
    package_dir={SKILL_PKG: ""},
    package_data={SKILL_PKG: find_resource_files()},
    packages=[SKILL_PKG],
    include_package_data=True,
    install_requires=get_requirements("requirements.txt"),
    keywords='ovos skill plugin',
    entry_points={'ovos.plugin.skill': PLUGIN_ENTRY_POINT}
)
