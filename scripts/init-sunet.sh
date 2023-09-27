#!/usr/bin/env bash

set -e

REPO_ROOT=$(pwd)
export REPO_ROOT=$REPO_ROOT

# repositories and branches.
REPO_MFAZONES=https://github.com/pondersource/mfazones
BRANCH_MFAZONES=main

# MFA Zones source code.
[ ! -d "mfazones" ] &&                                               \
    git clone                                                        \
    --depth 1                                                        \
    --branch ${BRANCH_MFAZONES}                                      \
    ${REPO_MFAZONES}                                                 \
    mfazones

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
