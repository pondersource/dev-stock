#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
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

cd "$DIR/.." || exit

ENV_ROOT=$(pwd)
export ENV_ROOT=${ENV_ROOT}

# repositories and branches.
REPO_SOLID=https://github.com/pdsinterop/solid-nextcloud
BRANCH_SOLID=support-nc-27

# Solid-Nextcloud source code.
[ ! -d "solid-nextcloud" ] &&                                               \
    git clone                                                               \
    --depth 1                                                               \
    --branch ${BRANCH_SOLID}                                                \
    ${REPO_SOLID}                                                           \
    solid-nextcloud

docker run -it --rm -v "${ENV_ROOT}/solid-nextcloud:/var/www/html/apps/solid-nextcloud" --workdir /var/www/html/apps/solid-nextcloud/solid "pondersource/dev-stock-nextcloud-solid"  bash -c "composer install"

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
