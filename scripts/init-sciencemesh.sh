#!/usr/bin/env bash

set -e

# repositories and branches.
REPO_NEXTCLOUD=https://github.com/nextcloud/server.git
BRANCH_NEXTCLOUD=v26.0.1

REPO_OWNCLOUD=https://github.com/pondersource/core.git
BRANCH_OWNCLOUD=ocm-via-sciencemesh

REPO_NEXTCLOUD_APP=https://github.com/pondersource/nc-sciencemesh
BRANCH_NEXTCLOUD_APP=nextcloud-dev

REPO_OWNCLOUD_APP=https://github.com/pondersource/nc-sciencemesh
BRANCH_OWNCLOUD_APP=owncloud-dev

REPO_REVA=https://github.com/cs3org/reva
BRANCH_REVA=v1.24.0

# pull images.
docker pull mariadb:latest
docker pull rclone/rclone:latest
docker pull collabora/code:latest
docker pull jlesage/firefox:latest
docker pull jlesage/firefox:v1.18.0
docker pull cs3org/wopiserver:latest

# add additional tagging for docker images.
docker tag pondersource/dev-stock-owncloud-sciencemesh pondersource/dev-stock-oc1-sciencemesh
docker tag pondersource/dev-stock-owncloud-sciencemesh pondersource/dev-stock-oc2-sciencemesh
docker tag pondersource/dev-stock-nextcloud-sciencemesh pondersource/dev-stock-nc1-sciencemesh
docker tag pondersource/dev-stock-nextcloud-sciencemesh pondersource/dev-stock-nc2-sciencemesh

# Nextcloud source code.
[ ! -d "nextcloud" ] &&                                                         \
    git clone                                                                   \
    --depth 1                                                                   \
    --branch ${BRANCH_NEXTCLOUD}                                                \
    ${REPO_NEXTCLOUD}                                                           \
    nextcloud

# ownCloud source code.
[ ! -d "owncloud" ] &&                                                          \
    git clone                                                                   \
    --depth 1                                                                   \
    --branch ${BRANCH_OWNCLOUD}                                                 \
    ${REPO_OWNCLOUD}                                                            \
    owncloud

# Nextcloud Sciencemesh source code.
[ ! -d "nc-sciencemesh" ] &&                                                    \
    git clone                                                                   \
    --branch ${BRANCH_NEXTCLOUD_APP}                                            \
    ${REPO_NEXTCLOUD_APP}                                                       \
    nc-sciencemesh                                                              \
    &&                                                                          \
    docker run -it                                                              \
    -v "$(pwd)/nc-sciencemesh:/var/www/html/apps/sciencemesh"                   \
    --workdir /var/www/html/apps/sciencemesh                                    \
    pondersource/dev-stock-nc1-sciencemesh                                      \
    make composer

# ownCloud Sciencemesh source code.
[ ! -d "oc-sciencemesh" ] &&                                                    \
    git clone                                                                   \
    --branch ${BRANCH_OWNCLOUD_APP}                                             \
    ${REPO_OWNCLOUD_APP}                                                        \
    oc-sciencemesh                                                              \
    &&                                                                          \
    docker run -it                                                              \
    -v "$(pwd)/oc-sciencemesh:/var/www/html/apps/sciencemesh"                   \
    --workdir /var/www/html/apps/sciencemesh                                    \
    pondersource/dev-stock-oc1-sciencemesh                                      \
    make composer

# Reva source code.
[ ! -d "reva" ] &&                                                              \
    git clone                                                                   \
    --branch ${BRANCH_REVA}                                                     \
    ${REPO_REVA}                                                                \
    reva                                                                        \
    &&                                                                          \
    cd reva                                                                     \
    &&                                                                          \
    go mod tidy                                                                 \
    &&                                                                          \
    go mod vendor                                                               \
    &&                                                                          \
    make revad                                                                  \
    &&                                                                          \
    cd ..

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet


[ ! -d "temp" ] && mkdir --parents temp
