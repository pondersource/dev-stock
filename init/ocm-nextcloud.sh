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

# repositories and branches.
REPO_NEXTCLOUD=https://github.com/SUNET/nextcloud-server
BRANCH_NEXTCLOUD=master

# Nextcloud source code.
[ ! -d "ocm-nextcloud" ] &&                                                                         \
    git clone                                                                                       \
    --depth 1                                                                                       \
    --branch ${BRANCH_NEXTCLOUD}                                                                    \
    ${REPO_NEXTCLOUD}                                                                               \
    ocm-nextcloud
docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
