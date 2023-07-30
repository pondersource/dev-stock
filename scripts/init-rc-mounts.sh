#!/usr/bin/env bash

set -e

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
    pondersource/dev-stock-owncloud-rc-mounts                                   \
    make install-deps

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir --parents temp
