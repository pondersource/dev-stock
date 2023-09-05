#!/usr/bin/env bash

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .

set -e

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

echo Building pondersource/dev-stock-ocmstub
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/ocmstub.Dockerfile --tag pondersource/dev-stock-ocmstub .

echo Building pondersource/dev-stock-revad
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/revad.Dockerfile --tag pondersource/dev-stock-revad .

echo Building pondersource/dev-stock-php-base
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/php-base.Dockerfile --tag pondersource/dev-stock-php-base .

echo Building pondersource/dev-stock-nextcloud
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/nextcloud.Dockerfile --tag pondersource/dev-stock-nextcloud .

echo Building pondersource/dev-stock-nextcloud-mfa
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/nextcloud-mfa.Dockerfile --tag pondersource/dev-stock-nextcloud-mfa .

echo Building pondersource/dev-stock-nextcloud-solid
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/nextcloud-solid.Dockerfile --tag pondersource/dev-stock-nextcloud-solid .

echo Building pondersource/dev-stock-nextcloud-sciencemesh
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/nextcloud-sciencemesh.Dockerfile --tag pondersource/dev-stock-nextcloud-sciencemesh .

echo Building pondersource/dev-stock-owncloud
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/owncloud.Dockerfile --tag pondersource/dev-stock-owncloud .

echo Building pondersource/dev-stock-owncloud-sciencemesh
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/owncloud-sciencemesh.Dockerfile --tag pondersource/dev-stock-owncloud-sciencemesh .

echo Building pondersource/dev-stock-owncloud-surf-trashbin
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/owncloud-surf-trashbin.Dockerfile --tag pondersource/dev-stock-owncloud-surf-trashbin .

echo Building pondersource/dev-stock-owncloud-rc-mounts
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/owncloud-rc-mounts.Dockerfile --tag pondersource/dev-stock-owncloud-rc-mounts .

echo Building pondersource/dev-stock-owncloud-opencloudmesh
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/owncloud-opencloudmesh.Dockerfile --tag pondersource/dev-stock-owncloud-opencloudmesh .

echo Building pondersource/dev-stock-owncloud-rd-sram
docker build --build-arg CACHEBUST="default" --file ./dockerfiles/owncloud-rd-sram.Dockerfile --tag pondersource/dev-stock-owncloud-rd-sram .
