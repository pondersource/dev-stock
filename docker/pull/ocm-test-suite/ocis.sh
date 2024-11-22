#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# oCIS version:
#   - 5.0.9
EFSS_PLATFORM_VERSION=${1:-"5.0.9"}

# 3rd party images.
docker pull cypress/included:13.13.1

# images.
docker pull "owncloud/ocis:${EFSS_PLATFORM_VERSION}"
