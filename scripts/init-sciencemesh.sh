#!/usr/bin/env bash

set -e

# repositories and branches.
REPO_NEXTCLOUD_APP=https://github.com/pondersource/nc-sciencemesh
BRANCH_NEXTCLOUD_APP=sciencemesh
REPO_OWNCLOUD_APP=https://github.com/pondersource/nc-sciencemesh
BRANCH_OWNCLOUD_APP=oc-10-take-2
REPO_REVA=https://github.com/cs3org/reva
BRANCH_REVA=v2.13.3

# docker pull rclone/rclone
docker pull mariadb:latest
docker pull jlesage/firefox:latest
docker pull jlesage/firefox:v1.18.0

# add additional tagging for docker images.
docker tag pondersource/dev-stock-owncloud-sciencemesh pondersource/dev-stock-oc1-sciencemesh
docker tag pondersource/dev-stock-owncloud-sciencemesh pondersource/dev-stock-oc2-sciencemesh
docker tag pondersource/dev-stock-nextcloud-sciencemesh pondersource/dev-stock-nc1-sciencemesh
docker tag pondersource/dev-stock-nextcloud-sciencemesh pondersource/dev-stock-nc2-sciencemesh

# Nextcloud Sciencemesh source code.
[ ! -d "nc-sciencemesh" ] &&                                                    \
    git clone                                                                   \
    --depth 1                                                                   \
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
    --depth 1                                                                   \
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
    --depth 1                                                                   \
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
