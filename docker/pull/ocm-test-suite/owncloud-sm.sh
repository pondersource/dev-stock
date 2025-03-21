#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# owncloud version:
#   - 10.15.0
EFSS_PLATFORM_VERSION=${1:-"v10.15.0"}

# 3rd party images.
docker pull mariadb:11.4.2
docker pull cypress/included:13.13.1

# dev-stock images.
docker pull "pondersource/owncloud:${EFSS_PLATFORM_VERSION}"
