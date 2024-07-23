#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# oCIS version:
#   - 5.0.6
EFSS_PLATFORM_VERSION=${1:-"5.0.6"}

# 3rd party images.
docker pull bitnami/openldap:2.6
docker pull cypress/included:13.3.0

# images.
docker pull "owncloud/ocis:${EFSS_PLATFORM_VERSION}"
