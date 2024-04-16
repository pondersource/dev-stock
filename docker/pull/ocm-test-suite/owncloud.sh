#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# 3rd party images.
docker pull mariadb:latest
docker pull cypress/included:13.3.0

# dev-stock images.
docker pull pondersource/dev-stock-owncloud-ocm-test-suite:latest
