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

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet

# install node lts/gallium (v16)
# TODO: check if nvm is installed or not
source /home/${USER}/.nvm/nvm.sh
nvm install lts/gallium
nvm use lts/gallium

cd remotestorage
npm run dev >/dev/null 2>&1 &
cd ..

cd remotestorage-widget
node_modules/.bin/webpack --mode=development -w >/dev/null 2>&1 &
cd ..

cd remotestorage-dev
http-server .
