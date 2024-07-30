#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# nextcloud version:
#   - v27.1.10
#   - v28.0.7
EFSS_PLATFORM_VERSION=${1:-"v27.1.10"}

# 3rd party images.
docker pull mariadb:latest
docker pull cypress/included:13.13.1

# dev-stock images.
docker pull "pondersource/dev-stock-nextcloud:${EFSS_PLATFORM_VERSION}"
