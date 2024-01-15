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
REPO_SURF_TRASHBIN=https://github.com/pondersource/surf-trashbin-app
BRANCH_SURF_TRASHBIN=master

[ ! -d "surf-trashbin-app" ] &&                                                 \
    git clone                                                                   \
    --branch ${BRANCH_SURF_TRASHBIN}                                            \
    ${REPO_SURF_TRASHBIN}                                                       \
    surf-trashbin-app

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

[ ! -d "temp" ] && mkdir -p temp
