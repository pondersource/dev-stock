#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

echo "Log in as pondersource"
docker login

docker push pondersource/dev-stock-php-base:latest
docker push pondersource/dev-stock-owncloud:latest
docker push pondersource/dev-stock-owncloud-opencloudmesh:latest
docker push pondersource/dev-stock-owncloud-federatedgroups:latest
