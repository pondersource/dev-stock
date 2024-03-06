#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# find this scripts location.
SOURCE=${BASH_SOURCE[0]}
while [ -L "${SOURCE}" ]; do # resolve "${SOURCE}" until the file is no longer a symlink.
  DIR=$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "${SOURCE}")
   # if "${SOURCE}" was a relative symlink, we need to resolve it relative to the path where the symlink file was located.
  [[ "${SOURCE}" != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
DIR=$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )

cd "${DIR}/.." || exit

# use docker buildkit. you can disable buildkit by providing 0 as first argument.
USE_BUILDKIT=${1:-"1"}

export DOCKER_BUILDKIT="${USE_BUILDKIT}"

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .

echo Building pondersource/dev-stock-revad
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/revad.Dockerfile --tag pondersource/dev-stock-revad .

echo Building pondersource/dev-stock-php-base
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/php-base.Dockerfile --tag pondersource/dev-stock-php-base .

echo Building pondersource/dev-stock-nextcloud
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/nextcloud.Dockerfile --tag pondersource/dev-stock-nextcloud .

echo Building pondersource/dev-stock-nextcloud-sciencemesh
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/nextcloud-sciencemesh.Dockerfile --tag pondersource/dev-stock-nextcloud-sciencemesh .

echo Building pondersource/dev-stock-owncloud
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/owncloud.Dockerfile --tag pondersource/dev-stock-owncloud .

echo Building pondersource/dev-stock-owncloud-sciencemesh
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/owncloud-sciencemesh.Dockerfile --tag pondersource/dev-stock-owncloud-sciencemesh .

echo Building pondersource/dev-stock-owncloud-ocm-test-suite
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/owncloud-ocm-test-suite.Dockerfile --tag pondersource/dev-stock-owncloud-ocm-test-suite .
