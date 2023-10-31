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

VERSION_CUSTOM_GROUPS=0.7.2
LINK_CUSTOM_GROUPS=https://github.com/owncloud/customgroups/releases/download/v${VERSION_CUSTOM_GROUPS}/customgroups-${VERSION_CUSTOM_GROUPS}.tar.gz

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

# CustomGroups source code.
wget -qO- ${LINK_CUSTOM_GROUPS} | tar xz -C owncloud/apps

# OpenCloudMesh source code.
[ ! -d "ocm" ] &&                                                                               \
    git clone                                                                                   \
    --branch ${BRANCH_OCM}                                                                      \
    ${REPO_OCM}                                                                                 \
    ocm

[ ! -d "owncloud/apps/ocm-git-repo" ] &&                                                        \
    mv ocm owncloud/apps/ocm-git-repo                                                           \
    &&                                                                                          \
    cd owncloud/apps                                                                            \
    &&                                                                                          \
    ln --symbolic --force  ocm-git-repo/opencloudmesh opencloudmesh                             \
    &&                                                                                          \
    cd ../..

# RD-SRAM source code.
[ ! -d "rd-sram" ] &&                                                                           \
    git clone                                                                                   \
    --branch ${BRANCH_RD_SRAM}                                                                  \
    ${REPO_RD_SRAM}                                                                             \
    rd-sram

[ ! -d "owncloud/apps/rd-sram-git-repo" ] &&                                                    \
    mv rd-sram owncloud/apps/rd-sram-git-repo                                                   \
    &&                                                                                          \
    cd owncloud/apps                                                                            \
    &&                                                                                          \
    ln --symbolic --force  rd-sram-git-repo/federatedgroups federatedgroups                     \
    &&                                                                                          \
    cd ../..

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
