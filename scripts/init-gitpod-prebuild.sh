#!/usr/bin/env bash

docker pull mariadb:latest
docker pull rclone/rclone:latest
docker pull jlesage/firefox:latest
docker pull jlesage/firefox:v1.18.0

docker pull pondersource/dev-stock-revad:latest
docker pull pondersource/dev-stock-ocmstub:latest
docker push pondersource/dev-stock-php-base:latest
docker push pondersource/dev-stock-nextcloud:latest
docker push pondersource/dev-stock-nextcloud-sciencemesh:latest
docker push pondersource/dev-stock-owncloud:latest
docker push pondersource/dev-stock-owncloud-sciencemesh:latest
