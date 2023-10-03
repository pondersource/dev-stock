#!/usr/bin/env bash
set -e

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .

cd docker

echo Building pondersource/dev-stock-revad
docker build --build-arg CACHEBUST="default" --file ./revad.Dockerfile --tag pondersource/dev-stock-revad .

echo Building pondersource/dev-stock-php-base
docker build --build-arg CACHEBUST="default" --file ./php-base.Dockerfile --tag pondersource/dev-stock-php-base .

echo Building pondersource/dev-stock-nextcloud
docker build --build-arg CACHEBUST="default" --file ./nextcloud.Dockerfile --tag pondersource/dev-stock-nextcloud .

echo Building pondersource/dev-stock-nextcloud-sciencemesh
docker build --build-arg CACHEBUST="default" --file ./nextcloud-sciencemesh.Dockerfile --tag pondersource/dev-stock-nextcloud-sciencemesh .

echo Building pondersource/dev-stock-owncloud
docker build --build-arg CACHEBUST="default" --file ./owncloud.Dockerfile --tag pondersource/dev-stock-owncloud .

echo Building pondersource/dev-stock-owncloud-sciencemesh
docker build --build-arg CACHEBUST="default" --file ./owncloud-sciencemesh.Dockerfile --tag pondersource/dev-stock-owncloud-sciencemesh .

# remove all <none> images.
# docker images -a | grep none | awk '{ print $3; }' | xargs docker rmi --force
