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

ENV_ROOT=$(pwd)
export ENV_ROOT=${ENV_ROOT}

# repositories and branches.
REPO_NEXTCLOUD=https://github.com/nextcloud/server
BRANCH_NEXTCLOUD=v27.1.10

REPO_SOLID=https://github.com/pdsinterop/solid-nextcloud
BRANCH_SOLID=main

# Nextcloud source code.
[ ! -d "nextcloud" ] &&                                                                             \
    git clone                                                                                       \
    --depth 1                                                                                       \
    --branch ${BRANCH_NEXTCLOUD}                                                                    \
    ${REPO_NEXTCLOUD}                                                                               \
    nextcloud

# Nextcloud Sciencemesh source code.
[ ! -d "solid-nextcloud" ] &&                                                                       \
    git clone                                                                                       \
    --branch ${BRANCH_SOLID}                                                                        \
    ${REPO_SOLID}                                                                                   \
    solid-nextcloud                                                                                 \

[ ! -d "nextcloud/apps/solid" ] &&                                                                  \
    mv solid-nextcloud nextcloud/apps/solid-nextcloud                                               \
    &&                                                                                              \
    cd nextcloud/apps                                                                               \
    &&                                                                                              \
    ln --symbolic --force solid-nextcloud/solid solid                                               \
    &&                                                                                              \
    docker run -it --rm                                                                             \
    -v "${ENV_ROOT}/nextcloud/apps/solid:/var/www/html/apps/solid"                                  \
    --workdir /var/www/html/apps/solid                                                              \
    "pondersource/dev-stock-nextcloud-solid"                                                        \
    bash -c "composer install"                                                                      \
    &&                                                                                              \
    cd ../..

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
