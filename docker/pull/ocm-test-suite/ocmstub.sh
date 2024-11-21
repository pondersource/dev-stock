#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# nextcloud version:
#   - v27.1.11
#   - v28.0.12
EFSS_PLATFORM_VERSION=${1:-"1.0"}

# dev-stock images.
docker pull "pondersource/dev-stock-ocmstub:${EFSS_PLATFORM_VERSION}"
