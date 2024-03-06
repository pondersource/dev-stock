#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# 3rd party images.
docker pull mariadb:latest 
docker pull collabora/code:latest
docker pull cypress/included:13.3.0
docker pull cs3org/wopiserver:latest 

# dev-stock images.
docker pull pondersource/dev-stock-revad:latest
docker pull pondersource/dev-stock-ocmstub:latest
docker pull pondersource/dev-stock-nextcloud-sciencemesh:latest
docker pull pondersource/dev-stock-owncloud-sciencemesh:latest
docker pull pondersource/dev-stock-owncloud-ocm-test-suite:latest
