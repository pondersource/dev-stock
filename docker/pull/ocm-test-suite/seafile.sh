#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# seafile version:
#   - 8.0.8
#   - 9.0.10
#   - 10.0.1
#   - 11.0.5
EFSS_PLATFORM_VERSION=${1:-"11.0.5"}

# 3rd party images.
docker pull mariadb:latest
docker pull memcached:1.6.18
docker pull cypress/included:13.3.0
docker pull "seafileltd/seafile-mc:${EFSS_PLATFORM_VERSION}"
