#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# oCIS version:
#   - 5.0.9
EFSS_PLATFORM_VERSION=${1:-"V5.0.9"}

# 3rd party images.
docker pull "owncloud/ocis:${EFSS_PLATFORM_VERSION#v}"


# dev-stock images.
docker pull pondersource/cypress:latest
