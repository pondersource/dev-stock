#!/usr/bin/env bash
set -e

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .

cd docker

echo Building pondersource/dev-stock-php-base
docker build --build-arg CACHEBUST="default" --file ./php-base.Dockerfile --tag pondersource/dev-stock-php-base .

echo Building pondersource/dev-stock-owncloud
docker build --build-arg CACHEBUST="default" --file ./owncloud.Dockerfile --tag pondersource/dev-stock-owncloud .

echo Building pondersource/dev-stock-owncloud-token-based-access
docker build --build-arg CACHEBUST="default" --file ./owncloud-token-based-access.Dockerfile --tag pondersource/dev-stock-owncloud-token-based-access .

# remove all <none> images.
# docker images -a | grep none | awk '{ print $3; }' | xargs docker rmi --force
