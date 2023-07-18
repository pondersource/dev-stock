#!/usr/bin/env bash

set -e

# repositories and branches.
REPO_DAV_TOKEN=https://github.com/pondersource/dav-token-access
BRANCH_DAV_TOKEN=master

[ ! -d "dav-token-access" ] &&                                                  \
    git clone                                                                   \
    --branch ${BRANCH_DAV_TOKEN}                                                \
    ${REPO_DAV_TOKEN}                                                           \
    dav-token-access

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir --parents temp
