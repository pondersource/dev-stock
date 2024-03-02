#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

echo "Log in as pondersource"
docker login

docker push pondersource/dev-stock-php-base

docker push pondersource/dev-stock-owncloud

docker push pondersource/dev-stock-owncloud-opencloudmesh

docker push pondersource/dev-stock-owncloud-federatedgroups
