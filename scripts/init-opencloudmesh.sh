#!/usr/bin/env bash

set -e

# repositories and branches.
REPO_OWNCLOUD=https://github.com/pondersource/core
BRANCH_OWNCLOUD=ocm-cleaning

REPO_OCM=https://github.com/pondersource/oc-opencloudmesh
BRANCH_OCM=main

# pull images.
docker pull mariadb:latest
docker pull jlesage/firefox:latest
docker pull jlesage/firefox:v1.18.0

docker pull pondersource/dev-stock-oc1-opencloudmesh:latest
docker pull pondersource/dev-stock-oc2-opencloudmesh:latest

# ownCloud source code.
[ ! -d "owncloud" ] &&                                                          \
    git clone                                                                   \
    --depth 1                                                                   \
    --branch ${BRANCH_OWNCLOUD}                                                 \
    ${REPO_OWNCLOUD}                                                            \
    owncloud

[ ! -d "ocm" ] &&                                                               \
    git clone                                                                   \
    --branch ${BRANCH_OCM}                                                      \
    ${REPO_OCM}                                                                 \
    ocm

cd owncloud &&                                                                  \
    make    &&                                                                  \
    cd ..

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir --parents temp
