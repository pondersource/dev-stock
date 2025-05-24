#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# owncloud version:
#   - 10.15.0
EFSS_PLATFORM_VERSION=${1:-"v10.15.0-sm"}

# 3rd party images.
docker pull mariadb:11.4.2

# dev-stock images.
docker pull pondersource/cypress:latest
docker pull pondersource/revad:v1.28.0
docker pull "pondersource/owncloud:${EFSS_PLATFORM_VERSION}"
