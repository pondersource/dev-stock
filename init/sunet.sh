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

ENV_ROOT=$(pwd)
export ENV_ROOT=${ENV_ROOT}

# repositories and branches.
REPO_MFAZONES=https://github.com/pondersource/mfazones
BRANCH_MFAZONES=main

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
