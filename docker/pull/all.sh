#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# 3rd party images.
docker pull redis:latest
docker pull mariadb:11.4.2
docker pull memcached:1.6.18
docker pull theasp/novnc:latest
docker pull rclone/rclone:latest
docker pull collabora/code:latest
docker pull jlesage/firefox:latest
docker pull cypress/included:13.13.1
docker pull cs3org/wopiserver:latest
docker pull seafileltd/seafile-mc:11.0.5
docker pull quay.io/keycloak/keycloak:latest

# dev-stock images.
docker pull pondersource/dev-stock-ocmstub:latest
docker pull pondersource/dev-stock-revad:latest
docker pull pondersource/dev-stock-php-base:latest
docker pull pondersource/dev-stock-nextcloud:latest
docker pull pondersource/dev-stock-nextcloud:v28.0.7
docker pull pondersource/dev-stock-nextcloud:v27.1.10
docker pull pondersource/dev-stock-nextcloud:v30.0.0
# docker pull pondersource/dev-stock-nextcloud-sunet:latest
# docker pull pondersource/dev-stock-simple-saml-php:latest
docker pull pondersource/dev-stock-nextcloud-solid:latest
docker pull pondersource/dev-stock-nextcloud-sciencemesh:latest
docker pull pondersource/dev-stock-owncloud:latest
docker pull pondersource/dev-stock-owncloud-sciencemesh:latest
docker pull pondersource/dev-stock-owncloud-surf-trashbin:latest
docker pull pondersource/dev-stock-owncloud-token-based-access:latest
docker pull pondersource/dev-stock-owncloud-opencloudmesh:latest
docker pull pondersource/dev-stock-owncloud-federatedgroups:latest
docker pull pondersource/dev-stock-owncloud-ocm-test-suite:latest
