#!/usr/bin/env bash
set -e

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .

# delete all containers including its volumes.
docker rm -vf $(docker ps -aq) || true

# delete all images.
docker rmi -f $(docker images -aq) || true

cd docker

echo Building pondersource/dev-stock-php-base
docker build --build-arg CACHEBUST="default" --file ./php-base.Dockerfile --tag pondersource/dev-stock-php-base .

echo Building pondersource/dev-stock-nextcloud-mfa
docker build --build-arg CACHEBUST="default" --file ./nextcloud-mfa.Dockerfile --tag pondersource/dev-stock-nextcloud-mfa .

# remove all <none> images.
# docker images -a | grep none | awk '{ print $3; }' | xargs docker rmi --force
