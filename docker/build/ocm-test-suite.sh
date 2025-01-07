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
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/revad.Dockerfile --tag pondersource/dev-stock-revad:latest .

echo Building pondersource/dev-stock-php-base
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/php-base.Dockerfile --tag pondersource/dev-stock-php-base:latest .

echo Building pondersource/dev-stock-nextcloud
docker build --build-arg CACHEBUST="default" --build-arg NEXTCLOUD_BRANCH="v30.0.2" --file ./dockerfiles/nextcloud.Dockerfile --tag pondersource/dev-stock-nextcloud:v30.0.2 --tag pondersource/dev-stock-nextcloud:latest .

echo Building pondersource/dev-stock-nextcloud
docker build --build-arg CACHEBUST="default" --build-arg NEXTCLOUD_BRANCH="v29.0.10" --file ./dockerfiles/nextcloud.Dockerfile --tag pondersource/dev-stock-nextcloud:v29.0.10 .

echo Building pondersource/dev-stock-nextcloud
docker build --build-arg CACHEBUST="default" --build-arg NEXTCLOUD_BRANCH="v28.0.14" --file ./dockerfiles/nextcloud.Dockerfile --tag pondersource/dev-stock-nextcloud:v28.0.14 .

echo Building pondersource/dev-stock-nextcloud
docker build --build-arg CACHEBUST="default" --build-arg NEXTCLOUD_BRANCH="v27.1.11" --file ./dockerfiles/nextcloud.Dockerfile --tag pondersource/dev-stock-nextcloud:v27.1.11 .

echo Building pondersource/dev-stock-nextcloud-sciencemesh
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/nextcloud-sciencemesh.Dockerfile --tag pondersource/dev-stock-nextcloud-sciencemesh:latest .

echo Building pondersource/dev-stock-owncloud
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/owncloud.Dockerfile --tag pondersource/dev-stock-owncloud:latest .

echo Building pondersource/dev-stock-owncloud-sciencemesh
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/owncloud-sciencemesh.Dockerfile --tag pondersource/dev-stock-owncloud-sciencemesh:latest .

echo Building pondersource/dev-stock-owncloud-ocm-test-suite
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/owncloud-ocm-test-suite.Dockerfile --tag pondersource/dev-stock-owncloud-ocm-test-suite:latest .

echo Building pondersource/dev-stock-ocmstub
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/ocmstub.Dockerfile --tag pondersource/dev-stock-ocmstub:v1.0.0 .
