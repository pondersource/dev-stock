#!/usr/bin/env bash

set -e

# repositories and branches.
REPO_OCM=https://github.com/pondersource/oc-opencloudmesh
BRANCH_OCM=main

REPO_RD_SRAM=https://github.com/surfnet/rd-sram-integration
BRANCH_RD_SRAM=main

[ ! -d "ocm" ] &&                                                               \
    git clone                                                                   \
    --branch ${BRANCH_OCM}                                                      \
    ${REPO_OCM}                                                                 \
    ocm

[ ! -d "rd-sram" ] &&                                                           \
    git clone                                                                   \
    --branch ${BRANCH_RD_SRAM}                                                  \
    ${REPO_RD_SRAM}                                                             \
    rd-sram

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
