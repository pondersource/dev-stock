#!/bin/bash

docker pull pondersource/dev-stock-oc1-opencloudmesh
docker pull pondersource/dev-stock-oc2-opencloudmesh
docker pull jlesage/firefox:v1.17.1
docker pull mariadb
[ ! -d "core" ] && git clone --depth=1 --branch=accept-ocm-to-groups https://github.com/pondersource/core
[ ! -d "oc-opencloudmesh" ] && git clone --branch=main https://github.com/pondersource/oc-opencloudmesh
