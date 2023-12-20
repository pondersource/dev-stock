#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

# syntax:
# db-maria.sh platform number
#
# 
# platform:   owncloud, nextcloud.
# number:     should be unique for each platform, you cannot have two nextclouds with same number.

platform=${1}
number=${2}

docker exec -it                                     \
    "maria${platform}${number}.docker"              \
    mariadb                                         \
    -u root                                         \
    -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek      \
    efss
