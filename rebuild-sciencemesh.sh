#!/bin/bash
set -e

echo Building pondersource/dev-stock-ocmstub
cd servers/ocmstub
cp -r ../../tls .
docker build -t pondersource/dev-stock-ocmstub .

echo Building pondersource/dev-stock-revad 
cd ../revad
cp -r ../../tls .
docker build -t pondersource/dev-stock-revad .

echo Base image apache-php-8.0
cd ../apache-php-8.0
cp -r ../../tls .
docker build -t apache-php-8.0 .

echo Base image nextcloud
cd ../nextcloud
docker build -t nextcloud .

echo Building pondersource/dev-stock-nc1
cd ../nc1
docker build -t pondersource/dev-stock-nc1 .

echo Building pondersource/dev-stock-nc1
cd ../nc2
docker build -t pondersource/dev-stock-nc2 .

echo Base image nextcloud-sciencemesh
cd ../nextcloud-sciencemesh
# docker build -t nextcloud --build-arg CACHEBUST=`date +%s` .
docker build -t nextcloud-sciencemesh .

# echo Building pondersource/dev-stock-nc1-sciencemesh
# cd ../nc1-sciencemesh
# docker build -t pondersource/dev-stock-nc1-sciencemesh .

# echo Building pondersource/dev-stock-nc2-sciencemesh
# cd ../nc2-sciencemesh
# docker build -t pondersource/dev-stock-nc2-sciencemesh .

echo Base image apache-php-7.4
cd ../apache-php-7.4
cp -r ../../tls .
docker build -t apache-php-7.4 .

echo Base image owncloud
cd ../owncloud
docker build -t owncloud .

echo Building pondersource/dev-stock-oc1
cd ../oc1
docker build -t pondersource/dev-stock-oc1 .

echo Building pondersource/dev-stock-oc2
cd ../oc2
docker build -t pondersource/dev-stock-oc2 .

echo Base image owncloud-sciencemesh
cd ../owncloud-sciencemesh
docker build -t owncloud-sciencemesh .

echo Building pondersource/dev-stock-oc1-sciencemesh
cd ../oc1-sciencemesh
docker build -t pondersource/dev-stock-oc1-sciencemesh .

echo Building pondersource/dev-stock-oc2-sciencemesh
cd ../oc2-sciencemesh
docker build -t pondersource/dev-stock-oc2-sciencemesh .
