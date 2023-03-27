#!/bin/bash

docker pull pondersource/dev-stock-revad-network-beta
docker pull pondersource/dev-stock-nc1-sciencemesh
docker pull pondersource/dev-stock-nc2-sciencemesh
docker pull pondersource/dev-stock-oc1-sciencemesh
docker pull pondersource/dev-stock-oc2-sciencemesh
docker pull pondersource/dev-stock-ocmstub
docker pull jlesage/firefox:v1.17.1
docker pull mariadb
# docker pull rclone/rclone
[ ! -d "oc-sciencemesh" ] && git clone --branch=oc-10 https://github.com/pondersource/nc-sciencemesh oc-sciencemesh && docker run -it -v "$(pwd)/oc-sciencemesh:/var/www/html/apps/sciencemesh"  --workdir /var/www/html/apps/sciencemesh pondersource/dev-stock-oc1-sciencemesh make composer
[ ! -d "nc-sciencemesh" ] && git clone  --branch=sciencemesh https://github.com/pondersource/nc-sciencemesh && docker run -it -v "$(pwd)/nc-sciencemesh:/var/www/html/apps/sciencemesh"  --workdir /var/www/html/apps/sciencemesh pondersource/dev-stock-nc1-sciencemesh make composer
docker network inspect testnet >/dev/null 2>&1 || docker network create testnet
