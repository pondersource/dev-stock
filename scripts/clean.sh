#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
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

ENV_ROOT=$(pwd)
export ENV_ROOT=${ENV_ROOT}

# revert back to normal.
sed -i 's/.*modifyObstructiveCode: false,.*/  modifyObstructiveCode: true,/'          "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"

# clear terminal:   yes, no. default is yes.
CLEAR_TERMINAL=${1:-"yes"}

running=$(docker ps -q)
# we actually need globbing and word spliting in this case.
# shellcheck disable=SC2086
[ -z "$running" ] || docker kill $running                   >/dev/null 2>&1

existing=$(docker ps -qa)
# we actually need globbing and word spliting in this case.
# shellcheck disable=SC2086
[ -z "$existing" ] || docker rm $existing                   >/dev/null 2>&1

echo "y" | docker volume prune
echo "y" | docker system prune

docker network remove testnet >/dev/null 2>&1 || true       >/dev/null 2>&1
docker network create testnet                               >/dev/null 2>&1

# I want a clean terminal xD
if [ "${CLEAR_TERMINAL}" = "yes" ]; then
    clear
fi
