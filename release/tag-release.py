#!/usr/bin/env python3

# Python Standard Library
import os
import sys
import subprocess

args = sys.argv

platform_tag = args[1] if not args[1] == "none" else ""
pre_release_tag = f"-{args[2]}" if not args[2] == "none" else ""
directory_name = args[3]

# get path to this file's directory, then go one directory up.
file_path = os.path.abspath(os.path.dirname(__file__))
base_path = os.path.abspath(os.path.dirname(file_path))
project_path = os.path.join(base_path, f"{directory_name}")
version_file_path = os.path.join(project_path, "appinfo", "info.xml")

# open version file.
with open(version_file_path) as file:
    version_file = file.readlines()

# set version and version_info to None, so if we didn't find
# a version in info.xml, we can throw an error.
version = None
version_info = None

# find version
for line in version_file:
    if "<version>" in line:
        # find versioninside info.xml and reformat it to
        # standard x.y.z version format
        tuple_left = line.index(">")
        tuple_right = line.index("/")
        version = line[tuple_left + 1:tuple_right -
                       1].replace(",", ".").replace(" ", "")
        # creat a list from x.y.z string which has [x, y, z]
        # notice that x, y , z must be converted to integer
        version_info = [int(number) for number in version.split(".")]

# throw error if version not found
if not version or not version_info:
    raise ValueError("ERROR: version not found at info.xml.")

print("This program will tag a new release of the app\n"
      + "and it will push the new tag to github.\n")

# read and convert to integer.
print("Version is in X.Y.Z form.\n"
      "X is version major, Y is version minor, Z is version minor.\n\n")

print(f"Current version is {version} .\n\n")

new_major = int(input("Enter version major number:\n"))
new_minor = int(input("Enter version minor  number:\n"))
new_patch = int(input("Enter version patch number:\n"))

new_version = ".".join(map(str, [new_major, new_minor, new_patch]))

# check version to be bigger than last version.
if new_version == version:
    raise ValueError("Version can't be same as current version!")

if new_major < version_info[0]:
    raise ValueError(
        "Major version can't be less than the current major version!")
elif new_major > version_info[0]:
    pass
elif new_minor < version_info[1]:
    raise ValueError(
        "Minor version can't be less than the current minor version!")
elif new_minor > version_info[1]:
    pass
elif new_patch < version_info[2]:
    raise ValueError(
        "Patch version can't be less than the current patch version!")


# creat an empty list for new info.xml file
print("Creating new version. \n\n")

new_xml_file = list()

# write new version_info and in info.xml.
new_version_info = f"    <version>{new_major}.{new_minor}.{new_patch}</version>\n"

# read current info.xml, and update version
# then append to new_xml_file list.
with open(version_file_path, "r") as file:
    lines = file.readlines()
    for line in lines:
        if "<version>" in line:
            new_xml_file.append(new_version_info)
        else:
            new_xml_file.append(line)

# write updated content from new_xml_file
# back into info.xml file
with open(version_file_path, "w+") as file:
    file.writelines(new_xml_file)

# do git commit and tag and push to upstreams
print("Commit and Tag and Push to upstream. \n\n")

tag = f"v{new_version}-{platform_tag}{pre_release_tag}"

subprocess.call(
    f"cd {project_path} && git commit {version_file_path} -m \"version: {tag}\"", shell=True)
subprocess.call(f"cd {project_path} && git tag \"{tag}\"", shell=True)
subprocess.call(
    f"cd {project_path} && git push origin HEAD \"{tag}\"", shell=True)
