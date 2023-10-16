#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

# find this scripts location.
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
   # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

cd "$DIR/.." || exit

# repositories and branches.
REPO_OWNCLOUD=https://github.com/owncloud/core
BRANCH_OWNCLOUD=v10.13.0

REPO_OWNCLOUD_APP=https://github.com/sciencemesh/nc-sciencemesh
BRANCH_OWNCLOUD_APP=owncloud

REPO_REVA=https://github.com/cs3org/reva
BRANCH_REVA=master

REPO_OCM=https://github.com/pondersource/oc-opencloudmesh
BRANCH_OCM=main

REPO_RD_SRAM=https://github.com/surfnet/rd-sram-integration
BRANCH_RD_SRAM=main

# ownCloud source code.
[ ! -d "owncloud" ] &&                                                                          \
    git clone                                                                                   \
    --depth 1                                                                                   \
    --branch ${BRANCH_OWNCLOUD}                                                                 \
    ${REPO_OWNCLOUD}                                                                            \
    owncloud

# ownCloud Sciencemesh source code.
[ ! -d "owncloud-sciencemesh" ] &&                                                              \
    git clone                                                                                   \
    --branch ${BRANCH_OWNCLOUD_APP}                                                             \
    ${REPO_OWNCLOUD_APP}                                                                        \
    owncloud-sciencemesh                                                                        \
    &&                                                                                          \
    docker run -it --rm                                                                         \
    -v "$(pwd)/owncloud-sciencemesh:/var/www/html/apps/sciencemesh"                             \
    --workdir /var/www/html/apps/sciencemesh                                                    \
    pondersource/dev-stock-owncloud-sciencemesh                                                 \
    composer install

[ ! -d "owncloud/apps/sciencemesh" ] &&                                                         \
    mv owncloud-sciencemesh owncloud/apps/sciencemesh

# Reva source code.
[ ! -d "reva" ] &&                                                                              \
    git clone                                                                                   \
    --depth 1                                                                                   \
    --branch ${BRANCH_REVA}                                                                     \
    ${REPO_REVA}                                                                                \
    reva                                                                                        \
    &&                                                                                          \
    docker run -it --rm                                                                         \
    -v "$(pwd)/reva:/reva-build"                                                                \
    --workdir /reva-build                                                                       \
    golang:1.21.1-bullseye                                                                      \
    bash -c "git config --global --add safe.directory /reva-build && go mod vendor && make revad"

# OpenCloudMesh source code.
[ ! -d "ocm" ] &&                                                                               \
    git clone                                                                                   \
    --branch ${BRANCH_OCM}                                                                      \
    ${REPO_OCM}                                                                                 \
    ocm

[ ! -d "owncloud/apps/opencloudmesh" ] &&                                                       \
    mv ocm/opencloudmesh owncloud/apps/opencloudmesh                                            \
    &&                                                                                          \
    rm -rf ocm

# RD-SRAM source code.
[ ! -d "rd-sram" ] &&                                                                           \
    git clone                                                                                   \
    --branch ${BRANCH_RD_SRAM}                                                                  \
    ${REPO_RD_SRAM}                                                                             \
    rd-sram

[ ! -d "owncloud/apps/federatedgroups" ] &&                                                     \
    mv rd-sram/federatedgroups owncloud/apps/federatedgroups                                    \
    &&                                                                                          \
    rm -rf rd-sram

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
