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

# oCIS version:
#   - 5.0.6
EFSS_PLATFORM_1_VERSION=${1:-"5.0.6"}

# oCIS version:
#   - 5.0.6
EFSS_PLATFORM_2_VERSION=${2:-"5.0.6"}

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

function changeInFile() {
  local file_path="${1}"
  local original="${2}"
  local replacement="${3}"

  sed -i "s#${original}#${replacement}#g" "${file_path}"
}

function createEfssOcis() {
  local number="${1}"

  redirect_to_null_cmd echo "creating efss ocis ${number}"

  redirect_to_null_cmd docker run --detach --network=testnet                                                                \
    --name="ocis${number}.docker"                                                                                           \
    -e OCIS_LOG_LEVEL=info                                                                                                  \
    -e OCIS_LOG_COLOR=true                                                                                                  \
    -e OCIS_LOG_PRETTY=true                                                                                                 \
    -e PROXY_HTTP_ADDR=0.0.0.0:443                                                                                          \
    -e OCIS_URL="https://ocis${number}.docker"                                                                              \
    -e OCIS_INSECURE=true                                                                                                   \
    -e PROXY_TRANSPORT_TLS_KEY="/certificates/ocis${number}.key"                                                            \
    -e PROXY_TRANSPORT_TLS_CERT="/certificates/ocis${number}.crt"                                                           \
    -e PROXY_ENABLE_BASIC_AUTH=true                                                                                         \
    -e IDM_ADMIN_PASSWORD=admin                                                                                             \
    -e IDM_CREATE_DEMO_USERS=true                                                                                           \
    -e FRONTEND_OCS_INCLUDE_OCM_SHAREES=true                                                                                \
		-e FRONTEND_OCS_LIST_OCM_SHARES=true                                                                                    \
		-e FRONTEND_ENABLE_FEDERATED_SHARING_INCOMING=true                                                                      \
		-e FRONTEND_ENABLE_FEDERATED_SHARING_OUTGOING=true                                                                      \
		-e OCIS_ADD_RUN_SERVICES=ocm                                                                                            \
		-e OCM_OCM_PROVIDER_AUTHORIZER_PROVIDERS_FILE=/dev-stock/ocmproviders.json                                              \
		-e GRAPH_INCLUDE_OCM_SHAREES=true                                                                                       \
		-e OCM_OCM_INVITE_MANAGER_INSECURE=true                                                                                 \
		-e OCM_OCM_SHARE_PROVIDER_INSECURE=true                                                                                 \
		-e OCM_OCM_STORAGE_PROVIDER_INSECURE=true                                                                               \
    -e WEB_UI_CONFIG_FILE=/dev-stock/web-ui-config.json                                                                     \
    -v "${ENV_ROOT}/temp/ocis:/dev-stock"                                                                                   \
    -v "${ENV_ROOT}/temp/certificates:/certificates"                                                                        \
    -v "${ENV_ROOT}/temp/certificate-authority:/certificate-authority"                                                      \
    --entrypoint /bin/sh                                                                                                    \
    "owncloud/ocis:5.0.6"                                                                                                   \
    -c "ocis init || true; ocis server"
}

# delete and create temp directory.
rm -rf "${ENV_ROOT}/temp" && mkdir -p "${ENV_ROOT}/temp/certificates"

# copy init files.
cp -fr "${ENV_ROOT}/docker/configs/ocis"                  "${ENV_ROOT}/temp/ocis"
cp -f "${ENV_ROOT}/docker/tls/certificates/ocis"*         "${ENV_ROOT}/temp/certificates"
cp -fr "${ENV_ROOT}/docker/tls/certificate-authority"     "${ENV_ROOT}/temp/certificate-authority"

# fix permissions.
chmod -R 777  "${ENV_ROOT}/temp/certificates"
chmod -R 777  "${ENV_ROOT}/temp/certificate-authority"

# auto clean before starting.
"${ENV_ROOT}/scripts/clean.sh" "no"

# make sure network exists.
docker network inspect testnet >/dev/null 2>&1 || docker network create testnet >/dev/null 2>&1

# insert real domain names into ocmproviders.json
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--domain--|"        "ocis1.docker"
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--homepage--|"      "ocis1.docker"
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--ocm--|"           "ocis1.docker"
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--ocm--path--|"     "ocis1.docker/ocm/"
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--ocm--host--|"     "ocis1.docker"
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--webdav--|"        "ocis1.docker"
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--webdav--path--|"  "ocis1.docker/dav/"
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--webdav--host--|"  "ocis1.docker"

changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--domain--|"        "ocis2.docker"
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--homepage--|"      "ocis2.docker"
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--ocm--|"           "ocis2.docker"
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--ocm--path--|"     "ocis2.docker/ocm/"
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--ocm--host--|"     "ocis2.docker"
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--webdav--|"        "ocis2.docker"
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--webdav--path--|"  "ocis2.docker/dav/"
changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--webdav--host--|"  "ocis2.docker"

############
### oCIS ###
############

# syntax:
# createEfssOcis number.
#
#
# number:         should be unique for each oCIS, for example: you cannot have two oCIS with same number.

# oCISes.
createEfssOcis    1
createEfssOcis    2

if [ "${SCRIPT_MODE}" = "dev" ]; then
  ###############
  ### Firefox ###
  ###############

  docker run --detach --network=testnet                                                                     \
    --name=firefox                                                                                          \
    -p 5800:5800                                                                                            \
    --shm-size 2g                                                                                           \
    -e USER_ID="${UID}"                                                                                     \
    -e GROUP_ID="${UID}"                                                                                    \
    -e DARK_MODE=1                                                                                          \
    -v "${ENV_ROOT}/docker/tls/browsers/firefox/cert9.db:/config/profile/cert9.db:rw"                       \
    -v "${ENV_ROOT}/docker/tls/browsers/firefox/cert_override.txt:/config/profile/cert_override.txt:rw"     \
    jlesage/firefox:latest                                                                                  \
    >/dev/null 2>&1

  ##################
  ### VNC Server ###
  ##################

  # remove previous x11 unix socket file, avoid any problems while mounting new one.
  sudo rm -rf "${ENV_ROOT}/temp/.X11-unix"

  # try to change DISPLAY_WIDTH, DISPLAY_HEIGHT to make it fit in your screen,
  # NOTE: please do not commit any change related to resolution.
  docker run --detach --network=testnet                                                                     \
    --name=vnc-server                                                                                       \
    -p 5700:8080                                                                                            \
    -e RUN_XTERM=no                                                                                         \
    -e DISPLAY_WIDTH=1920                                                                                   \
    -e DISPLAY_HEIGHT=1080                                                                                  \
    -v "${ENV_ROOT}/temp/.X11-unix:/tmp/.X11-unix"                                                          \
    theasp/novnc:latest

  ###############
  ### Cypress ###
  ###############

  # create cypress and attach its display to the VNC server container. 
  # this way you can view inside cypress container through vnc server.
  docker run --detach --network=testnet                                                                     \
    --name="cypress.docker"                                                                                 \
    -e DISPLAY=vnc-server:0.0                                                                               \
    -v "${ENV_ROOT}/cypress/ocm-test-suite:/ocm"                                                            \
    -v "${ENV_ROOT}/temp/.X11-unix:/tmp/.X11-unix"                                                          \
    -w /ocm                                                                                                 \
    --entrypoint cypress                                                                                    \
    cypress/included:13.13.1                                                                                \
    open --project .

  # print instructions.
  clear
  echo "Now browse to :"
  echo "Cypress inside VNC Server -> http://localhost:5700/vnc_auto.html, scale VNC to get to the Continue button, and run the appropriate test from ./cypress/ocm-test-suite/cypress/e2e/"
  echo "Embedded Firefox          -> http://localhost:5800"
  echo ""
  echo "Inside Embedded Firefox browse to EFSS hostname and enter the related credentials:"
  echo "https://ocis1.docker -> username: einstein               password: relativity"
  echo "https://ocis2.docker -> username: marie                  password: radioactivity"
else
  # only record when testing on electron.
  if [ "${BROWSER_PLATFORM}" != "electron" ]; then
    sed -i 's/.*video: true,.*/video: false,/'                          "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"
    sed -i 's/.*videoCompression: true,.*/videoCompression: false,/'    "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"
  fi
  ##################
  ### Cypress CI ###
  ##################

  # extract version up until first dot . , example: v27.1.17 becomes v27
  P1_VER="$( cut -d '.' -f 1 <<< "${EFSS_PLATFORM_1_VERSION}" )"
  P2_VER="$( cut -d '.' -f 1 <<< "${EFSS_PLATFORM_2_VERSION}" )"

  # run Cypress test suite headlessly and with the defined browser.
  docker run --network=testnet                                                  \
    --name="cypress.docker"                                                     \
    -v "${ENV_ROOT}/cypress/ocm-test-suite:/ocm"                                \
    -w /ocm                                                                     \
    cypress/included:13.13.1 cypress run                                        \
    --browser "${BROWSER_PLATFORM}"                                             \
    --spec "cypress/e2e/invite-link/ocis-${P1_VER}-to-ocis-${P2_VER}.cy.js"
  
  # revert config file back to normal.
  if [ "${BROWSER_PLATFORM}" != "electron" ]; then
    sed -i 's/.*video: false,.*/  video: true,/'                        "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"
    sed -i 's/.*videoCompression: false,.*/  videoCompression: true,/'  "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"
  fi

  # auto clean after running tests in ci mode. do not clear terminal.
  "${ENV_ROOT}/scripts/clean.sh" "no"
fi
