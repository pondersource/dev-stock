#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

docker pull pondersource/dev-stock-php-base:latest
docker pull pondersource/dev-stock-owncloud:latest
docker pull pondersource/dev-stock-owncloud-opencloudmesh:latest
docker pull pondersource/dev-stock-owncloud-federatedgroups:latest
