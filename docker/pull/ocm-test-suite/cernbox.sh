#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# CERNBox version:
#   - v1.28.0
EFSS_PLATFORM_VERSION=${1:-"v1.28.0"}

# dev-stock images.
docker pull pondersource/cypress:latest
docker pull pondersource/keycloak:latest
docker pull pondersource/cernbox:latest
docker pull "pondersource/revad-cernbox:${EFSS_PLATFORM_VERSION}"
