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

[ ! -d "temp" ] && mkdir -p temp

# repositories and branches.
REPO_REMOTE_STORAGE=https://github.com/pondersource/remotestorage.js
BRANCH_REMOTE_STORAGE=master

REPO_REMOTE_STORAGE_WIDGET=https://github.com/pondersource/remotestorage-widget
BRANCH_REMOTE_STORAGE_WIDGET=master

# remotestorage source code.
[ ! -d "remotestorage" ] &&                                                                            \
    git clone                                                                                      \
    --branch ${BRANCH_REMOTE_STORAGE}                                                              \
    ${REPO_REMOTE_STORAGE}                                                                         \
    remotestorage

# remotestorage-widget source code.
[ ! -d "remotestorage-widget" ] &&                                                                            \
    git clone                                                                                      \
    --branch ${BRANCH_REMOTE_STORAGE_WIDGET}                                                       \
    ${REPO_REMOTE_STORAGE_WIDGET}                                                                  \
    remotestorage-widget

# install node lts/gallium (v16)
# TODO: check if nvm is installed or not
source /home/${USER}/.nvm/nvm.sh
nvm install lts/gallium
nvm use lts/gallium

npm install --global http-server

cd remotestorage
npm install --legacy-peer-deps
npm run build:dev
cd ..

cd remotestorage-widget
npm install --legacy-peer-deps
npm run build
cd ..

mkdir remotestorage-dev
cd remotestorage-dev 
npm init my-app --yes

cp ../remotestorage/release/remotestorage.js .
cp ../remotestorage-widget/build/widget.js .

cat > index.html <<EOF
<html>
    <head>

    </head>
    <body>
        <script src="./remotestorage.js"></script>
        <script src="./widget.js"></script>
        <script>
            const options = {
                solidProviders: {
                    providers: [
                        Widget.SOLID_COMMUNITY,
                        Widget.INRUPT
                    ],
                    allowAnyProvider: true
                }
            }
            const remoteStorage = new RemoteStorage();
            const widget = new Widget(remoteStorage, options);
            widget.attach();
        </script>
    </body>
</html>
EOF
