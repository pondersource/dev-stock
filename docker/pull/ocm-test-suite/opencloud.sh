#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# OpenCloud version:
#   - v2.3.0
EFSS_PLATFORM_VERSION=${1:-"v2.3.0"}

# 3rd party images.
docker pull "opencloudeu/opencloud-rolling:${EFSS_PLATFORM_VERSION#v}"


# dev-stock images.
docker pull pondersource/cypress:latest
