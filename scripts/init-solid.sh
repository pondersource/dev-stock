#!/usr/bin/env bash

set -e

# repositories and branches.
REPO_SOLID=https://github.com/pdsinterop/solid-nextcloud.git
BRANCH_SOLID=main

# Solid-Nextcloud source code.
[ ! -d "solid-nextcloud" ] &&                                               \
    git clone                                                               \
    --depth 1                                                               \
    --branch ${BRANCH_SOLID}                                                \
    ${REPO_SOLID}                                                           \
    solid-nextcloud

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir --parents temp
