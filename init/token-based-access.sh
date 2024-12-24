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
REPO_DAV_TOKEN=https://github.com/pondersource/dav-token-access
BRANCH_DAV_TOKEN=master

REPO_OPENID=https://github.com/owncloud/openidconnect
BRANCH_OPENID=master

[ ! -d "dav-token-access" ] &&                                                  \
    git clone                                                                   \
    --branch ${BRANCH_DAV_TOKEN}                                                \
    ${REPO_DAV_TOKEN}                                                           \
    dav-token-access

[ ! -d "open-id-connect" ] &&                                                   \
    git clone                                                                   \
    --branch ${BRANCH_OPENID}                                                   \
    ${REPO_OPENID}                                                              \
    open-id-connect                                                             \
    &&                                                                          \
    docker run -it                                                              \
    -v "$(pwd)/open-id-connect:/var/www/html/apps/openidconnect"                \
    --workdir /var/www/html/apps/openidconnect                                  \
    pondersource/owncloud-rc-mounts                                   \
    make install-deps

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
