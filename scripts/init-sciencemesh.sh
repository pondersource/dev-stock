#!/usr/bin/env bash

# docker pull rclone/rclone
docker pull mariadb:latest
docker pull jlesage/firefox:latest

docker pull pondersource/dev-stock-revad:latest
docker pull pondersource/dev-stock-ocmstub:latest
docker pull pondersource/dev-stock-owncloud-sciencemesh:latest
docker pull pondersource/dev-stock-nextcloud-sciencemesh:latest

# add additional tagging for docker images.
docker tag pondersource/dev-stock-owncloud-sciencemesh pondersource/dev-stock-oc1-sciencemesh
docker tag pondersource/dev-stock-owncloud-sciencemesh pondersource/dev-stock-oc2-sciencemesh
docker tag pondersource/dev-stock-nextcloud-sciencemesh pondersource/dev-stock-nc1-sciencemesh
docker tag pondersource/dev-stock-nextcloud-sciencemesh pondersource/dev-stock-nc2-sciencemesh

# Nextcloud Sciencemesh source code.
[ ! -d "nc-sciencemesh" ] && git clone --branch=main         https://github.com/pondersource/nc-sciencemesh nc-sciencemesh && docker run -it -v "$(pwd)/nc-sciencemesh:/var/www/html/apps/sciencemesh" --workdir /var/www/html/apps/sciencemesh pondersource/dev-stock-nc1-sciencemesh make composer

# ownCloud Sciencemesh source code.
[ ! -d "oc-sciencemesh" ] && git clone --branch=oc-10-take-2 https://github.com/pondersource/nc-sciencemesh oc-sciencemesh && docker run -it -v "$(pwd)/oc-sciencemesh:/var/www/html/apps/sciencemesh" --workdir /var/www/html/apps/sciencemesh pondersource/dev-stock-oc1-sciencemesh make composer

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet
