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

cd "${DIR}/.." || exit

ENV_ROOT=$(pwd)
export ENV_ROOT=${ENV_ROOT}

# test case:
#   - login-nextcloud
#   - login-owncloud
#   - login-seafile
TEST_CASE=${1:-"login-nextcloud"}

# script mode:   dev, ci. default is dev.
SCRIPT_MODE=${2:-"dev"}

# test platform: chrome, edge, firefox, electron. default is electron.
# only applies on SCRIPT_MODE=ci
TEST_PLATFORM=${3:-"electron"}

case $TEST_CASE in

  login-nextcloud)
    "${ENV_ROOT}/dev/ocm-test-suite/login/nextcloud.sh" "${SCRIPT_MODE}" "${TEST_PLATFORM}"
    ;;

  login-owncloud)
    "${ENV_ROOT}/dev/ocm-test-suite/login/owncloud.sh" "${SCRIPT_MODE}" "${TEST_PLATFORM}"
    ;;

  login-seafile)
    "${ENV_ROOT}/dev/ocm-test-suite/login/seafile.sh" "${SCRIPT_MODE}" "${TEST_PLATFORM}"
    ;;

  *)
    echo -n "unknown"
    ;;
esac
