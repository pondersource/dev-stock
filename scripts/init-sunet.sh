#!/usr/bin/env bash

set -e

REPO_ROOT=$(pwd)
export REPO_ROOT=$REPO_ROOT

# repositories and branches.
REPO_MFAZONES=https://github.com/pondersource/mfazones
BRANCH_MFAZONES=main

# See 
REPO_NC=https://github.com/pondersource/server
BRANCH_NC=mrv/mfa-check-rebased

# MFA Zones source code.
[ ! -d "mfazones" ] &&                                               \
    git clone                                                        \
    --depth 1                                                        \
    --branch ${BRANCH_MFAZONES}                                      \
    ${REPO_MFAZONES}                                                 \
    mfazones

cd mfazones
git pull
cd ..

# Nextloud source code.
[ ! -d "server" ] &&                                                 \
    git clone                                                        \
    --depth 1                                                        \
    --branch ${BRANCH_NC}                                            \
    ${REPO_NC}                                                       \
    server

cd server
git pull
cd ..

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
