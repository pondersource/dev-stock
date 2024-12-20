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
#   - login
#   - share-with
#   - share-link
TEST_CASE=${1:-"login"}

# efss platform:
#   - nextcloud
#   - owncloud
#   - seafile
EFSS_PLATFORM_1=${2:-"nextcloud"}

EFSS_PLATFORM_1_VERSION=${3:-"unknown"}

# script mode:   dev, ci. default is dev.
SCRIPT_MODE=${4:-"dev"}

# browser platform: chrome, edge, firefox, electron. default is electron.
# only applies on SCRIPT_MODE=ci
BROWSER_PLATFORM=${5:-"electron"}

# efss platform:
#   - nextcloud
#   - owncloud
#   - seafile
EFSS_PLATFORM_2=${6:-"nextcloud"}

EFSS_PLATFORM_2_VERSION=${7:-"unknown"}

case "${TEST_CASE}" in

  "login")
    case "${EFSS_PLATFORM_1}" in

      "nextcloud")
        "${ENV_ROOT}/dev/ocm-test-suite/login/nextcloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "owncloud")
        "${ENV_ROOT}/dev/ocm-test-suite/login/owncloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "ocis")
        "${ENV_ROOT}/dev/ocm-test-suite/login/ocis.sh" "${EFSS_PLATFORM_1_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "seafile")
        "${ENV_ROOT}/dev/ocm-test-suite/login/seafile.sh" "${EFSS_PLATFORM_1_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "ocmstub")
        "${ENV_ROOT}/dev/ocm-test-suite/login/ocmstub.sh" "${EFSS_PLATFORM_1_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      *)
        echo -n "unknown login"
        ;;
    esac
    ;;

  "share-with")
    case "${EFSS_PLATFORM_1}-${EFSS_PLATFORM_2}" in

      "nextcloud-nextcloud")
        "${ENV_ROOT}/dev/ocm-test-suite/share-with/nextcloud-nextcloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "nextcloud-owncloud")
        "${ENV_ROOT}/dev/ocm-test-suite/share-with/nextcloud-owncloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "nextcloud-seafile")
        echo -n "not supported"
        ;;

      "nextcloud-ocmstub")
        "${ENV_ROOT}/dev/ocm-test-suite/share-with/nextcloud-ocmstub.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "owncloud-nextcloud")
        "${ENV_ROOT}/dev/ocm-test-suite/share-with/owncloud-nextcloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "owncloud-owncloud")
        "${ENV_ROOT}/dev/ocm-test-suite/share-with/owncloud-owncloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "owncloud-seafile")
        echo -n "not supported"
        ;;

      "owncloud-ocmstub")
        "${ENV_ROOT}/dev/ocm-test-suite/share-with/owncloud-ocmstub.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "seafile-nextcloud")
        echo -n "not supported"
        ;;

      "seafile-owncloud")
        echo -n "not supported"
        ;;

      "seafile-seafile")
        "${ENV_ROOT}/dev/ocm-test-suite/share-with/seafile-seafile.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;
      
      "ocmstub-nextcloud")
        "${ENV_ROOT}/dev/ocm-test-suite/share-with/ocmstub-nextcloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "ocmstub-owncloud")
        "${ENV_ROOT}/dev/ocm-test-suite/share-with/ocmstub-owncloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "ocmstub-ocmstub")
        "${ENV_ROOT}/dev/ocm-test-suite/share-with/ocmstub-ocmstub.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      *)
        echo -n "unknown share-with"
        ;;
    esac
    ;;

  "share-link")
    case "${EFSS_PLATFORM_1}-${EFSS_PLATFORM_2}" in

      "nextcloud-nextcloud")
        "${ENV_ROOT}/dev/ocm-test-suite/share-link/nextcloud-nextcloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "nextcloud-owncloud")
        "${ENV_ROOT}/dev/ocm-test-suite/share-link/nextcloud-owncloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "owncloud-nextcloud")
        "${ENV_ROOT}/dev/ocm-test-suite/share-link/owncloud-nextcloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "owncloud-owncloud")
        "${ENV_ROOT}/dev/ocm-test-suite/share-link/owncloud-owncloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      *)
        echo -n "unknown share-link"
        ;;
    esac
    ;;

  "invite-link")
    case "${EFSS_PLATFORM_1}-${EFSS_PLATFORM_2}" in

      "nextcloud-nextcloud")
        "${ENV_ROOT}/dev/ocm-test-suite/invite-link/nextcloud-nextcloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "nextcloud-owncloud")
        "${ENV_ROOT}/dev/ocm-test-suite/invite-link/nextcloud-owncloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "nextcloud-ocis")
        "${ENV_ROOT}/dev/ocm-test-suite/invite-link/nextcloud-ocis.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "owncloud-nextcloud")
        "${ENV_ROOT}/dev/ocm-test-suite/invite-link/owncloud-nextcloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "owncloud-owncloud")
        "${ENV_ROOT}/dev/ocm-test-suite/invite-link/owncloud-owncloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "owncloud-ocis")
        "${ENV_ROOT}/dev/ocm-test-suite/invite-link/owncloud-ocis.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "ocis-ocis")
        "${ENV_ROOT}/dev/ocm-test-suite/invite-link/ocis-ocis.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "ocis-owncloud")
        "${ENV_ROOT}/dev/ocm-test-suite/invite-link/ocis-owncloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "ocis-nextcloud")
        "${ENV_ROOT}/dev/ocm-test-suite/invite-link/ocis-nextcloud.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      "cernbox-cernbox")
        "${ENV_ROOT}/dev/ocm-test-suite/invite-link/cernbox-cernbox.sh" "${EFSS_PLATFORM_1_VERSION}" "${EFSS_PLATFORM_2_VERSION}" "${SCRIPT_MODE}" "${BROWSER_PLATFORM}"
        ;;

      *)
        echo -n "unknown invite-link"
        ;;
    esac
    ;;

  *)
    echo -n "unknown"
    ;;
esac
