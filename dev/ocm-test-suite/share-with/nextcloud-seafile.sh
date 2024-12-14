#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
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

cd "${DIR}/../../.." || exit

ENV_ROOT=$(pwd)
export ENV_ROOT=${ENV_ROOT}

# nextcloud version:
#   - v27.1.11
#   - v28.0.14
EFSS_PLATFORM_1_VERSION=${1:-"11.0.5"}

# seafile version:
#   - 8.0.8
#   - 9.0.10
#   - 10.0.1
#   - 11.0.5
EFSS_PLATFORM_2_VERSION=${2:-"11.0.5"}

# script mode:   dev, ci. default is dev.
SCRIPT_MODE=${3:-"dev"}

# browser platform: chrome, edge, firefox, electron. default is electron.
# only applies on SCRIPT_MODE=ci
BROWSER_PLATFORM=${4:-"electron"}

function redirect_to_null_cmd() {
    if [ "${SCRIPT_MODE}" = "ci" ]; then
        "$@" >/dev/null 2>&1
    else
        "$@"
    fi
}

function waitForPort () {
  redirect_to_null_cmd echo waitForPort "${1} ${2}"
  # the "| cat" after the "| grep" is to prevent the command from exiting with 1 if no match is found by grep.
  x=$(docker exec "${1}" ss -tulpn | grep -c "${2}" | cat)
  until [ "${x}" -ne 0 ]
  do
    redirect_to_null_cmd echo Waiting for "${1} to open port ${2}, this usually takes about 10 seconds ... ${x}"
    sleep 1
    x=$(docker exec "${1}" ss -tulpn | grep -c "${2}" |  cat)
  done
  redirect_to_null_cmd echo "${1} port ${2} is open"
}

function waitForCollabora() {
  x=$(docker logs collabora.docker | grep -c "Ready")
  until [ "${x}" -ne 0 ]
  do
    redirect_to_null_cmd echo "Waiting for Collabora to be ready, this usually takes about 10 seconds ... ${x}"
    sleep 1
    x=$(docker logs collabora.docker | grep -c "Ready")
  done
  redirect_to_null_cmd echo "Collabora is ready"
}
