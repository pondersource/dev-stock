#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

# repositories and branches.
REPO_OCM=https://github.com/pondersource/oc-opencloudmesh
BRANCH_OCM=main

[ ! -d "ocm" ] &&                                                               \
    git clone                                                                   \
    --branch ${BRANCH_OCM}                                                      \
    ${REPO_OCM}                                                                 \
    ocm

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
