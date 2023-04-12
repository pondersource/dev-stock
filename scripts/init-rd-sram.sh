#!/bin/bash

docker pull pondersource/dev-stock-oc1-rd-sram
docker pull pondersource/dev-stock-oc2-rd-sram
docker pull jlesage/firefox:v1.17.1
docker pull mariadb
[ ! -d "rd-sram-integration" ] && git clone https://github.com/surfnet/rd-sram-integration
[ ! -d "core" ] && git clone --depth=1 --branch=accept-ocm-to-groups https://github.com/pondersource/core
[ ! -d "oc-opencloudmesh" ] && git clone https://github.com/pondersource/oc-opencloudmesh
