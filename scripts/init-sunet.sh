#!/usr/bin/env bash

set -e

REPO_ROOT=$(pwd)
export REPO_ROOT=$REPO_ROOT

# repositories and branches.
REPO_MFAZONES=https://github.com/pondersource/mfazones
BRANCH_MFAZONES=main

# MFA Zones source code.
[ ! -d "mfazones" ] &&                                               \
    git clone                                                        \
    --depth 1                                                        \
    --branch ${BRANCH_MFAZONES}                                      \
    ${REPO_MFAZONES}                                                 \
    mfazones

docker run -it --rm -v "${REPO_ROOT}/mfazones:/var/www/html/apps/mfazones" --workdir /var/www/html/apps/solid-nextcloud/solid "pondersource/dev-stock-nextcloud-sunet"  bash -c "composer install"

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
