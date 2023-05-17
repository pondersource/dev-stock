#!/usr/bin/env bash

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="$(date +%s)" .

set -e

# delete all containers including its volumes.
docker rm -vf $(docker ps -aq) || true

# delete all images.
docker rmi -f $(docker images -aq) || true

cd docker

echo Building pondersource/dev-stock-ocmstub
docker build --build-arg CACHEBUST="$(date +%s)" --file ./ocmstub.Dockerfile --tag pondersource/dev-stock-ocmstub .

echo Building pondersource/dev-stock-revad
docker build --build-arg CACHEBUST="$(date +%s)" --file ./revad.Dockerfile --tag pondersource/dev-stock-revad .

echo Building pondersource/dev-stock-php-base
docker build --build-arg CACHEBUST="$(date +%s)" --file ./php-base.Dockerfile --tag pondersource/dev-stock-php-base .

echo Building pondersource/dev-stock-nextcloud
docker build --build-arg CACHEBUST="$(date +%s)" --file ./nextcloud.Dockerfile --tag pondersource/dev-stock-nextcloud .

echo Building pondersource/dev-stock-nextcloud-sciencemesh
docker build --build-arg CACHEBUST="$(date +%s)" --file ./nextcloud-sciencemesh.Dockerfile --tag pondersource/dev-stock-nextcloud-sciencemesh .

echo Building pondersource/dev-stock-nextcloud-mfa
docker build --build-arg CACHEBUST="$(date +%s)" --file ./nextcloud-mfa.Dockerfile --tag pondersource/dev-stock-nextcloud-mfa .

echo Building pondersource/dev-stock-owncloud
docker build --build-arg CACHEBUST="$(date +%s)" --file ./owncloud.Dockerfile --tag pondersource/dev-stock-owncloud .

echo Building pondersource/dev-stock-owncloud-sciencemesh
docker build --build-arg CACHEBUST="$(date +%s)" --file ./owncloud-sciencemesh.Dockerfile --tag pondersource/dev-stock-owncloud-sciencemesh .

echo Building pondersource/dev-stock-owncloud-opencloudmesh
docker build --build-arg CACHEBUST="$(date +%s)" --file ./owncloud-opencloudmesh.Dockerfile --tag pondersource/dev-stock-owncloud-opencloudmesh .

echo Building pondersource/dev-stock-owncloud-rd-sram
docker build --build-arg CACHEBUST="$(date +%s)" --file ./owncloud-rd-sram.Dockerfile --tag pondersource/dev-stock-owncloud-rd-sram .

# remove all <none> images.
docker images -a | grep none | awk '{ print $3; }' | xargs docker rmi --force
