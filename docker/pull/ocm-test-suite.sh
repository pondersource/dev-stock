#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# 3rd party images.
docker pull mariadb:latest
docker pull memcached:1.6.18
docker pull collabora/code:latest
docker pull cypress/included:13.3.0
docker pull cs3org/wopiserver:latest
docker pull seafileltd/seafile-mc:11.0.5

# dev-stock images.
docker pull pondersource/dev-stock-revad:latest
docker pull pondersource/dev-stock-ocmstub:latest
docker pull pondersource/dev-stock-nextcloud:v28.0.3
docker pull pondersource/dev-stock-nextcloud:v27.1.7
docker pull pondersource/dev-stock-nextcloud-sciencemesh:latest
docker pull pondersource/dev-stock-owncloud-sciencemesh:latest
docker pull pondersource/dev-stock-owncloud-ocm-test-suite:latest
