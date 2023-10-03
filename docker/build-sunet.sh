#!/usr/bin/env bash
set -e

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .

cd docker

echo Building pondersource/dev-stock-php-base
docker build --build-arg CACHEBUST="default" --file ./php-base.Dockerfile --tag pondersource/dev-stock-php-base .

echo Building pondersource/dev-stock-nextcloud-sunet
docker build --build-arg CACHEBUST="default" --file ./nextcloud-sunet.Dockerfile --tag pondersource/dev-stock-nextcloud-sunet .

echo Building pondersource/dev-stock-simple-saml-php
cd simple-saml-php
docker build -t pondersource/dev-stock-simple-saml-php .
cd ..

# remove all <none> images.
# docker images -a | grep none | awk '{ print $3; }' | xargs docker rmi --force
