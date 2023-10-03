#!/usr/bin/env bash
set -e

# repositories and branches.
REPO_TOKEN_BASED_ACCESS=https://github.com/pondersource/surf-token-based-access
BRANCH_TOKEN_BASED_ACCESS=main

REPO_OPENID=https://github.com/owncloud/openidconnect
BRANCH_OPENID=master

[ ! -d "surf-token-based-access" ] &&                                           \
    git clone                                                                   \
    --branch ${BRANCH_TOKEN_BASED_ACCESS}                                       \
    ${REPO_TOKEN_BASED_ACCESS}                                                  \
    surf-token-based-access

[ ! -d "open-id-connect" ] &&                                                   \
    git clone                                                                   \
    --branch ${BRANCH_OPENID}                                                   \
    ${REPO_OPENID}                                                              \
    open-id-connect                                                             \
    &&                                                                          \
    docker run -it                                                              \
    -v "$(pwd)/open-id-connect:/var/www/html/apps/openidconnect"                \
    --workdir /var/www/html/apps/openidconnect                                  \
    pondersource/dev-stock-owncloud-token-based-access                                   \
    make install-deps

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
