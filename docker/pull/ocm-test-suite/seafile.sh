#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# seafile version:
#   - 11.0.5
EFSS_PLATFORM_VERSION=${1:-"v11.0.13"}

# 3rd party images.
docker pull mariadb:11.4.2
docker pull memcached:1.6.18
docker pull "seafileltd/seafile-mc:${EFSS_PLATFORM_VERSION#v}"

# dev-stock images.
docker pull pondersource/cypress:latest
