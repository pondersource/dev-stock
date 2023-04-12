#!/bin/bash
set -e

echo Base image apache-php-7.4
cd servers/apache-php-7.4
cp -r ../../tls .
docker build -t apache-php-7.4 .

echo Base image owncloud
cd ../owncloud
docker build -t owncloud .

echo Base image owncloud-opencloudmesh
cd ../owncloud-opencloudmesh
docker build -t owncloud-opencloudmesh .

echo Building pondersource/dev-stock-oc1-opencloudmesh
cd ../oc1-opencloudmesh
docker build -t pondersource/dev-stock-oc1-opencloudmesh .

echo Building pondersource/dev-stock-oc2-opencloudmesh
cd ../oc2-opencloudmesh
docker build -t pondersource/dev-stock-oc2-opencloudmesh .

echo Base image owncloud-rd-sram
cd ../owncloud-rd-sram
docker build -t owncloud-rd-sram .

echo Building pondersource/dev-stock-oc1-rd-sram
cd ../oc1-rd-sram
docker build -t pondersource/dev-stock-oc1-rd-sram .

echo Building pondersource/dev-stock-oc2-rd-sram
cd ../oc2-rd-sram
docker build -t pondersource/dev-stock-oc2-rd-sram .
