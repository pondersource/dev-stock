#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

EFSS_PLATFORM_VERSION=${1:-"v27.1.7"}

# 3rd party images.
docker pull mariadb:latest
docker pull cypress/included:13.3.0

# dev-stock images.
docker pull "pondersource/dev-stock-nextcloud:${EFSS_PLATFORM_VERSION}"
