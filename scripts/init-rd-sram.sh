#!/usr/bin/env bash

docker pull mariadb:latest
docker pull jlesage/firefox:latest

docker pull pondersource/dev-stock-oc1-rd-sram:latest
docker pull pondersource/dev-stock-oc2-rd-sram:latest

[ ! -d "rd-sram-integration" ] && git clone https://github.com/surfnet/rd-sram-integration
[ ! -d "core" ] && git clone --depth=1 --branch=ocm-cleaning https://github.com/pondersource/core
[ ! -d "oc-opencloudmesh" ] && git clone https://github.com/pondersource/oc-opencloudmesh
