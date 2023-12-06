#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

docker pull mariadb
docker pull collabora/code:latest
docker pull cypress/included:13.3.0
docker pull cs3org/wopiserver:latest 
docker pull pondersource/dev-stock-revad
docker pull pondersource/dev-stock-ocmstub
docker pull pondersource/dev-stock-owncloud-sciencemesh
docker pull pondersource/dev-stock-nextcloud-sciencemesh
