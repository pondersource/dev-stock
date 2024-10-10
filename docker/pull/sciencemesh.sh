#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

docker pull pondersource/dev-stock-revad:latest
docker pull pondersource/dev-stock-nextcloud:v28.0.7
docker pull pondersource/dev-stock-nextcloud:v27.1.10
docker pull pondersource/dev-stock-nextcloud:v30.0.0
docker pull pondersource/dev-stock-nextcloud-sciencemesh:latest
docker pull pondersource/dev-stock-owncloud-sciencemesh:latest
