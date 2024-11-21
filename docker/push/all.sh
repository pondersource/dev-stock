#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

echo "Log in as pondersource"
docker login

docker push pondersource/dev-stock-ocmstub:latest
docker push pondersource/dev-stock-ocmstub:v1.0.0
docker push pondersource/dev-stock-revad:latest
docker push pondersource/dev-stock-php-base:latest
docker push pondersource/dev-stock-nextcloud:latest
docker push pondersource/dev-stock-nextcloud:v30.0.0
docker push pondersource/dev-stock-nextcloud:v29.0.8
docker push pondersource/dev-stock-nextcloud:v28.0.12
docker push pondersource/dev-stock-nextcloud:v27.1.11
# docker push pondersource/dev-stock-nextcloud-sunet
# docker push pondersource/dev-stock-simple-saml-php
docker push pondersource/dev-stock-nextcloud-solid:latest
docker push pondersource/dev-stock-nextcloud-sciencemesh:latest
docker push pondersource/dev-stock-owncloud:latest
docker push pondersource/dev-stock-owncloud-sciencemesh:latest
docker push pondersource/dev-stock-owncloud-surf-trashbin:latest
docker push pondersource/dev-stock-owncloud-token-based-access:latest
docker push pondersource/dev-stock-owncloud-opencloudmesh:latest
docker push pondersource/dev-stock-owncloud-federatedgroups:latest
docker push pondersource/dev-stock-owncloud-ocm-test-suite:latest
