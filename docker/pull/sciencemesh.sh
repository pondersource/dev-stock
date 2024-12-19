#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

docker pull pondersource/dev-stock-revad:latest
docker pull pondersource/dev-stock-nextcloud:v30.0.2
docker pull pondersource/dev-stock-nextcloud:v39.0.8
docker pull pondersource/dev-stock-nextcloud:v28.0.14
docker pull pondersource/dev-stock-nextcloud:v27.1.11
docker pull pondersource/dev-stock-nextcloud-sciencemesh:latest
docker pull pondersource/dev-stock-owncloud-sciencemesh:latest
