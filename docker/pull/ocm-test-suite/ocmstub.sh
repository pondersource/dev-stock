#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# nextcloud version:
#   - v27.1.11
#   - v28.0.14
EFSS_PLATFORM_VERSION=${1:-"V1.0.0"}

# dev-stock images.
docker pull pondersource/cypress:latest
docker pull "pondersource/ocmstub:${EFSS_PLATFORM_VERSION}"
