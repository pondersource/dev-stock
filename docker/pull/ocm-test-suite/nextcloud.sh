#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# nextcloud version:
#   - v27.1.11
#   - v28.0.14
EFSS_PLATFORM_VERSION=${1:-"v27.1.11"}

# 3rd party images.
docker pull mariadb:11.4.2
docker pull cypress/included:13.13.1

# dev-stock images.
docker pull "pondersource/nextcloud:${EFSS_PLATFORM_VERSION}"
