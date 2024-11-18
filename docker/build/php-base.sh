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

echo "Building pondersource/php-base:8.3"
docker build --build-arg CACHEBUST="default"                                  \
  --file ./dockerfiles/php-base-8.3.Dockerfile                                \
  --tag "pondersource/php-base:8.3"                                           \
  .

echo "Building pondersource/php-base:7.4"
docker build --build-arg CACHEBUST="default"                                  \
  --file ./dockerfiles/php-base-7.4.Dockerfile                                \
  --tag "pondersource/php-base:7.4"                                           \
  .

echo Building pondersource/dev-stock-nextcloud
docker build --build-arg CACHEBUST="default" --build-arg BRANCH_NEXTCLOUD="v28.0.12" --file ./dockerfiles/nextcloud-base.Dockerfile --tag pondersource/dev-stock-nextcloud:v28.0.12 --tag pondersource/dev-stock-nextcloud:latest .
