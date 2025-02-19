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
REPO_NEXTCLOUD_APP=https://github.com/sciencemesh/nc-sciencemesh
BRANCH_NEXTCLOUD_APP=nextcloud

REPO_NEXTCLOUD=https://github.com/nextcloud/server
BRANCH_NEXTCLOUD=v27.1.11

REPO_OWNCLOUD=https://github.com/owncloud/core
BRANCH_OWNCLOUD=v10.15.0

REPO_OWNCLOUD_APP=https://github.com/sciencemesh/nc-sciencemesh
BRANCH_OWNCLOUD_APP=owncloud

REPO_REVA=https://github.com/cs3org/reva
BRANCH_REVA=v1.28.0

# Nextcloud source code.
[ ! -d "nextcloud" ] &&                                                                             \
    git clone                                                                                       \
    --depth 1                                                                                       \
    --branch ${BRANCH_NEXTCLOUD}                                                                    \
    ${REPO_NEXTCLOUD}                                                                               \
    nextcloud

# Nextcloud Sciencemesh source code.
[ ! -d "nextcloud-sciencemesh" ] &&                                                                 \
    git clone                                                                                       \
    --branch ${BRANCH_NEXTCLOUD_APP}                                                                \
    ${REPO_NEXTCLOUD_APP}                                                                           \
    nextcloud-sciencemesh                                                                           \
    &&                                                                                              \
    docker run -it --rm                                                                             \
    -v "$(pwd)/nextcloud-sciencemesh:/var/www/html/apps/sciencemesh"                                \
    --workdir /var/www/html/apps/sciencemesh                                                        \
    pondersource/nextcloud-sciencemesh                                                    \
    make composer

# move app to its place inside efss and create symbolic links.
[ ! -d "nextcloud/apps/sciencemesh" ] &&                                                            \
    mv nextcloud-sciencemesh nextcloud/apps/sciencemesh

# ownCloud source code.
[ ! -d "owncloud" ] &&                                                                              \
    git clone                                                                                       \
    --depth 1                                                                                       \
    --branch ${BRANCH_OWNCLOUD}                                                                     \
    ${REPO_OWNCLOUD}                                                                                \
    owncloud

# ownCloud Sciencemesh source code.
[ ! -d "owncloud-sciencemesh" ] &&                                                                  \
    git clone                                                                                       \
    --branch ${BRANCH_OWNCLOUD_APP}                                                                 \
    ${REPO_OWNCLOUD_APP}                                                                            \
    owncloud-sciencemesh                                                                            \
    &&                                                                                              \
    docker run -it --rm                                                                             \
    -v "$(pwd)/owncloud-sciencemesh:/var/www/html/apps/sciencemesh"                                 \
    --workdir /var/www/html/apps/sciencemesh                                                        \
    pondersource/owncloud-sciencemesh                                                     \
    composer install

[ ! -d "owncloud/apps/sciencemesh" ] &&                                                             \
    mv owncloud-sciencemesh owncloud/apps/sciencemesh

# Reva source code.
[ ! -d "reva" ] &&                                                                                  \
    git clone                                                                                       \
    --depth 1                                                                                       \
    --branch ${BRANCH_REVA}                                                                         \
    ${REPO_REVA}                                                                                    \
    reva                                                                                            \
    &&                                                                                              \
    docker run -it --rm                                                                             \
    -v "$(pwd)/reva:/reva-build"                                                                    \
    --workdir /reva-build                                                                           \
    golang:1.22.1-alpine                                                                            \
    sh -c "apk --no-cache add git make bash && git config --global --add safe.directory /reva-build && go mod download && make revad"

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
