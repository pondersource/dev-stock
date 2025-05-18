#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

EFSS_PLATFORM_VERSION=${1:-"v27.1.11"}

# 3rd party images.
docker pull mariadb:11.4.2

# dev-stock images.
docker pull "pondersource/nextcloud:${EFSS_PLATFORM_VERSION}"
docker pull pondersource/cypress:latest
