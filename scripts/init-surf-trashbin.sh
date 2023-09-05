#!/usr/bin/env bash

set -e

# repositories and branches.
REPO_SURF_TRASHBIN=https://github.com/pondersource/surf-trashbin-app
BRANCH_SURF_TRASHBIN=master

[ ! -d "dav-token-access" ] &&                                                  \
    git clone                                                                   \
    --branch ${BRANCH_SURF_TRASHBIN}                                            \
    ${REPO_SURF_TRASHBIN}                                                       \
    surf-trashbin-app

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
