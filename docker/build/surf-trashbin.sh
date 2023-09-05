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

cd "$DIR/../dockerfiles"

echo Building pondersource/dev-stock-php-base
docker build --build-arg CACHEBUST="default" --file ./php-base.Dockerfile --tag pondersource/dev-stock-php-base .

echo Building pondersource/dev-stock-owncloud
docker build --build-arg CACHEBUST="default" --file ./owncloud.Dockerfile --tag pondersource/dev-stock-owncloud .

echo Building pondersource/dev-stock-owncloud-surf-trashbin
docker build --build-arg CACHEBUST="default" --file ./owncloud-surf-trashbin.Dockerfile --tag pondersource/dev-stock-owncloud-surf-trashbin .
