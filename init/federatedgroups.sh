#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# find this scripts location.
SOURCE=${BASH_SOURCE[0]}
while [ -L "${SOURCE}" ]; do # resolve "${SOURCE}" until the file is no longer a symlink.
  DIR=$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "${SOURCE}")
   # if "${SOURCE}" was a relative symlink, we need to resolve it relative to the path where the symlink file was located.
  [[ "${SOURCE}" != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
DIR=$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )

cd "${DIR}/.." || exit

# repositories and branches.
REPO_OWNCLOUD=https://github.com/owncloud/core
BRANCH_OWNCLOUD=v10.14.0

VERSION_CUSTOM_GROUPS=0.9.0
LINK_CUSTOM_GROUPS=https://github.com/owncloud/customgroups/releases/download/v${VERSION_CUSTOM_GROUPS}/customgroups-${VERSION_CUSTOM_GROUPS}.tar.gz

REPO_OCM=https://github.com/pondersource/oc-opencloudmesh
BRANCH_OCM=main

REPO_FEDERATEDGROUPS=https://github.com/surfnet/rd-sram-integration
BRANCH_FEDERATEDGROUPS=main

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
[ ! -d "opencloudmesh-git-repo" ] &&                                                            \
    git clone                                                                                   \
    --branch ${BRANCH_OCM}                                                                      \
    ${REPO_OCM}                                                                                 \
    opencloudmesh-git-repo

[ ! -d "owncloud/apps/opencloudmesh-git-repo" ] &&                                              \
    mv opencloudmesh-git-repo owncloud/apps/opencloudmesh-git-repo                              \
    &&                                                                                          \
    cd owncloud/apps                                                                            \
    &&                                                                                          \
    ln --symbolic --force opencloudmesh-git-repo/opencloudmesh opencloudmesh                    \
    &&                                                                                          \
    cd ../..

# FederatedGroups source code.
[ ! -d "federatedgroups-git-repo" ] &&                                                          \
    git clone                                                                                   \
    --branch ${BRANCH_FEDERATEDGROUPS}                                                          \
    ${REPO_FEDERATEDGROUPS}                                                                     \
    federatedgroups-git-repo

[ ! -d "owncloud/apps/federatedgroups-git-repo" ] &&                                            \
    mv federatedgroups-git-repo owncloud/apps/federatedgroups-git-repo                          \
    &&                                                                                          \
    cd owncloud/apps                                                                            \
    &&                                                                                          \
    ln --symbolic --force federatedgroups-git-repo/federatedgroups federatedgroups              \
    &&                                                                                          \
    cd ../..

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
