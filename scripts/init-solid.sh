#!/usr/bin/env bash
set -e

REPO_ROOT=$(pwd)
export REPO_ROOT=$REPO_ROOT

# repositories and branches.
REPO_SOLID=https://github.com/pdsinterop/solid-nextcloud.git
BRANCH_SOLID=support-nc-27

# Solid-Nextcloud source code.
[ ! -d "solid-nextcloud" ] &&                                               \
    git clone                                                               \
    --depth 1                                                               \
    --branch ${BRANCH_SOLID}                                                \
    ${REPO_SOLID}                                                           \
    solid-nextcloud

docker run -it --rm -v "${REPO_ROOT}/solid-nextcloud:/var/www/html/apps/solid-nextcloud" --workdir /var/www/html/apps/solid-nextcloud/solid "pondersource/dev-stock-nextcloud-solid"  bash -c "composer install"

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
