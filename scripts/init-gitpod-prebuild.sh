#!/usr/bin/env bash

docker pull mariadb:latest
docker pull rclone/rclone:latest
docker pull collabora/code:latest
docker pull jlesage/firefox:latest
docker pull jlesage/firefox:v1.18.0
docker pull cs3org/wopiserver:latest

docker pull pondersource/dev-stock-revad:latest
docker pull pondersource/dev-stock-ocmstub:latest
docker pull pondersource/dev-stock-php-base:latest
docker pull pondersource/dev-stock-nextcloud:latest
docker pull pondersource/dev-stock-nextcloud-sciencemesh:latest
docker pull pondersource/dev-stock-owncloud:latest
docker pull pondersource/dev-stock-owncloud-sciencemesh:latest
