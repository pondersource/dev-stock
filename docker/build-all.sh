#!/usr/bin/env bash

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .

set -e

cd docker

echo Building pondersource/dev-stock-ocmstub
docker build --build-arg CACHEBUST="default" --file ./ocmstub.Dockerfile --tag pondersource/dev-stock-ocmstub .

echo Building pondersource/dev-stock-revad
docker build --build-arg CACHEBUST="default" --file ./revad.Dockerfile --tag pondersource/dev-stock-revad .

echo Building pondersource/dev-stock-php-base
docker build --build-arg CACHEBUST="default" --file ./php-base.Dockerfile --tag pondersource/dev-stock-php-base .

echo Building pondersource/dev-stock-nextcloud
docker build --build-arg CACHEBUST="default" --file ./nextcloud.Dockerfile --tag pondersource/dev-stock-nextcloud .

echo Building pondersource/dev-stock-nextcloud-mfa
docker build --build-arg CACHEBUST="default" --file ./nextcloud-mfa.Dockerfile --tag pondersource/dev-stock-nextcloud-mfa .

echo Building pondersource/dev-stock-nextcloud-solid
docker build --build-arg CACHEBUST="default" --file ./nextcloud-solid.Dockerfile --tag pondersource/dev-stock-nextcloud-solid .

echo Building pondersource/dev-stock-nextcloud-sunet
docker build --build-arg CACHEBUST="default" --file ./nextcloud-sunet.Dockerfile --tag pondersource/dev-stock-nextcloud-sunet .

echo Building pondersource/dev-stock-simple-saml-php
cd simple-saml-php
docker build -t pondersource/dev-stock-simple-saml-php .
cd ..

echo Building pondersource/dev-stock-nextcloud-sciencemesh
docker build --build-arg CACHEBUST="default" --file ./nextcloud-sciencemesh.Dockerfile --tag pondersource/dev-stock-nextcloud-sciencemesh .

echo Building pondersource/dev-stock-owncloud
docker build --build-arg CACHEBUST="default" --file ./owncloud.Dockerfile --tag pondersource/dev-stock-owncloud .

echo Building pondersource/dev-stock-owncloud-sciencemesh
docker build --build-arg CACHEBUST="default" --file ./owncloud-sciencemesh.Dockerfile --tag pondersource/dev-stock-owncloud-sciencemesh .

echo Building pondersource/dev-stock-owncloud-surf-trashbin
docker build --build-arg CACHEBUST="default" --file ./owncloud-surf-trashbin.Dockerfile --tag pondersource/dev-stock-owncloud-surf-trashbin .

echo Building pondersource/dev-stock-owncloud-token-based-access
docker build --build-arg CACHEBUST="default" --file ./owncloud-token-based-access.Dockerfile --tag pondersource/dev-stock-owncloud-token-based-access .

echo Building pondersource/dev-stock-owncloud-opencloudmesh
docker build --build-arg CACHEBUST="default" --file ./owncloud-opencloudmesh.Dockerfile --tag pondersource/dev-stock-owncloud-opencloudmesh .

echo Building pondersource/dev-stock-owncloud-rd-sram
docker build --build-arg CACHEBUST="default" --file ./owncloud-rd-sram.Dockerfile --tag pondersource/dev-stock-owncloud-rd-sram .

# remove all <none> images.
# docker images -a | grep none | awk '{ print $3; }' | xargs docker rmi --force
