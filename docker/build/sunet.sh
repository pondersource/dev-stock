#!/usr/bin/env bash

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .

set -e

# @michielbdejong avoid docker buildkit
export DOCKER_BUILDKIT=0

# find this scripts location.
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
   # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

cd "$DIR/.."

echo Building pondersource/dev-stock-nextcloud-sunet
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/nextcloud-sunet.Dockerfile --tag pondersource/dev-stock-nextcloud-sunet .

cd simple-saml-php

echo Building pondersource/dev-stock-simple-saml-php
docker build --tag pondersource/dev-stock-simple-saml-php .

cd ..
