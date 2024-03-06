#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

docker pull pondersource/dev-stock-revad:latest
docker pull pondersource/dev-stock-nextcloud-sciencemesh:latest
docker pull pondersource/dev-stock-owncloud-sciencemesh:latest
docker pull pondersource/dev-stock-owncloud-ocm-test-suite:latest
