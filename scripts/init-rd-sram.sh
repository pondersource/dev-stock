#!/usr/bin/env bash

set -e

# repositories and branches.
REPO_OCM=https://github.com/pondersource/oc-opencloudmesh
BRANCH_OCM=main

REPO_RD_SRAM=https://github.com/surfnet/rd-sram-integration
BRANCH_RD_SRAM=main


REPO_CORE=https://github.com/pondersource/core
BRANCH_CORE=accept-ocm-to-groups

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

# uncommnt if you need to clone oc/core repo
# [ ! -d "core" ] && git clone --branch ${BRANCH_CORE} ${REPO_CORE} core
  
docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir --parents temp
