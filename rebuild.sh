#!/bin/bash
set -e

# docker build -t tester .

# image for stub1 and stub2:
cd ocm-stub
cp -r ../tls .
docker build -t stub .
cd ../servers/ci
pwd
# # image for running the tests from Github Actions:
# cd ../ci
# cp -r ../../tls .
# docker build -t ci .

# image for revad1, revad2, revanc1, revanc2:
cd ../revad
cp -r ../../tls .
# docker build -t revad --build-arg CACHEBUST=`date +%s` .
docker build -t revad .

# base image for owncloud image:
cd ../apache-php-7.4
cp -r ../../tls .
docker build -t apache-php-7.4 .

# base image for nextcloud image:
cd ../apache-php-8.0
cp -r ../../tls .
docker build -t apache-php-8.0 .

# base image for nc1 image and nc2 image:
cd ../nextcloud
# docker build -t nextcloud --build-arg CACHEBUST=`date +%s` .
docker build -t nextcloud .

# image for nc1:
cd ../nc1
docker build -t nc1 .

# image for nc2:
cd ../nc2
docker build -t nc2 .

# base image for oc1 image and oc2 image:
cd ../owncloud
docker build -t owncloud .

# image for oc1:
cd ../oc1
docker build -t oc1 .

# image for oc2:
cd ../oc2
docker build -t oc2 .
