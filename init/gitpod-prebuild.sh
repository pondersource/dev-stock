#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

docker pull redis:latest
docker pull mariadb:latest
docker pull theasp/novnc:latest
docker pull rclone/rclone:latest
docker pull collabora/code:latest
docker pull jlesage/firefox:latest
docker pull jlesage/firefox:v1.18.0
docker pull cypress/included:13.3.0
docker pull cs3org/wopiserver:latest
docker pull quay.io/keycloak/keycloak:latest

docker pull pondersource/dev-stock-revad:latest
docker pull pondersource/dev-stock-ocmstub:latest
docker pull pondersource/dev-stock-php-base:latest
docker pull pondersource/dev-stock-nextcloud:latest
docker pull pondersource/dev-stock-nextcloud-sciencemesh:latest
docker pull pondersource/dev-stock-nextcloud-sunet:latest
docker pull pondersource/dev-stock-simple-saml-php:latest
docker pull pondersource/dev-stock-nextcloud-solid:latest
docker pull pondersource/dev-stock-owncloud:latest
docker pull pondersource/dev-stock-owncloud-sciencemesh:latest
docker pull pondersource/dev-stock-owncloud-surf-trashbin:latest
docker pull pondersource/dev-stock-owncloud-token-based-access:latest
docker pull pondersource/dev-stock-owncloud-opencloudmesh:latest
docker pull pondersource/dev-stock-owncloud-rd-sram:latest
