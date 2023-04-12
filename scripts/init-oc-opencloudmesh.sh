#!/bin/bash

docker pull pondersource/dev-stock-oc1-opencloudmesh
docker pull pondersource/dev-stock-oc2-opencloudmesh
docker pull jlesage/firefox:v1.17.1
docker pull mariadb
[ ! -d "core" ] && git clone --depth=1 --branch=ocm-cleaning https://github.com/pondersource/core
[ ! -d "oc-opencloudmesh" ] && git clone https://github.com/pondersource/oc-opencloudmesh