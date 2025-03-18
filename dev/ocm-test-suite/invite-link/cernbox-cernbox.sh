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
#   - 5.0.9
EFSS_PLATFORM_1_VERSION=${1:-"5.0.9"}

# oCIS version:
#   - 5.0.9
EFSS_PLATFORM_2_VERSION=${2:-"5.0.9"}

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

function createIdpKeycloak() {
  redirect_to_null_cmd echo "creating idp"

  redirect_to_null_cmd docker run --detach --network=testnet --name=idp.docker                \
    -e KEYCLOAK_ADMIN="admin"                                                                 \
    -e KEYCLOAK_ADMIN_PASSWORD="admin"                                                        \
    -e KC_HOSTNAME="idp.docker"                                                               \
    -e KC_HTTPS_CERTIFICATE_FILE="/certificates/idp.crt"                                      \
    -e KC_HTTPS_CERTIFICATE_KEY_FILE="/certificates/idp.key"                                  \
    -e KC_HTTPS_PORT="443"                                                                    \
    -v "${ENV_ROOT}/temp/certificates:/certificates"                                          \
    -v "${ENV_ROOT}/temp/cernbox/keycloak.json:/opt/keycloak/data/import/keycloak.json"       \
    quay.io/keycloak/keycloak:26.1.0                                                          \
    -v start --import-realm --verbose --optimized
}

function createEfssCernBox() {
  local platform="${1}"
  local number="${2}"

  redirect_to_null_cmd echo "creating efss cernbox ${number}"

  redirect_to_null_cmd cp -r "${ENV_ROOT}/temp/cernbox/nginx" "${ENV_ROOT}/temp/cernbox/nginx-${number}"
  redirect_to_null_cmd cp "${ENV_ROOT}/temp/cernbox/web-ui-config.json" "${ENV_ROOT}/temp/cernbox/web-ui-config-${number}.json"
  
  changeInFile "${ENV_ROOT}/temp/cernbox/nginx-${number}/nginx.conf" "your.key.pem" "/certificates/${platform}${number}.key"
  changeInFile "${ENV_ROOT}/temp/cernbox/nginx-${number}/nginx.conf" "your.cert.pem" "/certificates/${platform}${number}.crt"
  changeInFile "${ENV_ROOT}/temp/cernbox/nginx-${number}/nginx.conf" "your.revad.org" "reva${platform}${number}.docker"
  changeInFile "${ENV_ROOT}/temp/cernbox/nginx-${number}/nginx.conf" "your.cernbox.org" "${platform}${number}.docker"

  changeInFile "${ENV_ROOT}/temp/cernbox/web-ui-config-${number}.json" "your.nginx.org" "${platform}${number}.docker"

  redirect_to_null_cmd docker run --detach --network=testnet                               \
  --name="${platform}${number}.docker"                                                     \
  -v "${ENV_ROOT}/temp/certificates:/certificates"                                         \
  -v "${ENV_ROOT}/temp/certificate-authority:/usr/local/share/ca-certificates"             \
  -v "${ENV_ROOT}/temp/cernbox/cernbox-web-sciencemesh/web:/var/www/web"                   \
  -v "${ENV_ROOT}/temp/cernbox/cernbox-web-sciencemesh/cernbox:/var/www/cernbox"           \
  -v "${ENV_ROOT}/temp/cernbox/nginx-${number}:/etc/nginx"                                 \
  -v "${ENV_ROOT}/temp/cernbox/web-ui-config-${number}.json:/var/www/web/config.json"      \
  nginx

  # redirect_to_null_cmd docker exec "${platform}${number}.docker" update-ca-certificates
}

function createReva() {
  local platform="${1}"
  local number="${2}"

  redirect_to_null_cmd echo "creating reva for ${platform} ${number}"

  # make sure scripts are executable.
  chmod +x "${ENV_ROOT}/temp/reva/run.sh"                                     >/dev/null 2>&1
  chmod +x "${ENV_ROOT}/temp/reva/kill.sh"                                    >/dev/null 2>&1
  chmod +x "${ENV_ROOT}/temp/reva/entrypoint.sh"                              >/dev/null 2>&1

  redirect_to_null_cmd docker run --detach --network=testnet                  \
  --name="reva${platform}${number}.docker"                                    \
  -e HOST="reva${platform}${number}"                                          \
  -v "${ENV_ROOT}/temp/certificates:/certificates"                            \
  -v "${ENV_ROOT}/temp/certificate-authority:/certificate-authority"          \
  -v "${ENV_ROOT}/temp/cernbox:/configs/revad"                                \
  -v "${ENV_ROOT}/temp/reva/run.sh:/usr/bin/run.sh"                           \
  -v "${ENV_ROOT}/temp/reva/kill.sh:/usr/bin/kill.sh"                         \
  -v "${ENV_ROOT}/temp/reva/entrypoint.sh:/usr/bin/entrypoint.sh"             \
  pondersource/dev-stock-revad
}

# delete and create temp directory.
rm -rf "${ENV_ROOT}/temp" && mkdir --parents "${ENV_ROOT}/temp"

# copy init files.
cp -fr "${ENV_ROOT}/docker/scripts/reva"                                "${ENV_ROOT}/temp/"
cp -fr "${ENV_ROOT}/docker/configs/cernbox"                             "${ENV_ROOT}/temp/cernbox"
cp -fr "${ENV_ROOT}/docker/tls/certificates"                            "${ENV_ROOT}/temp/certificates"
cp -fr "${ENV_ROOT}/docker/tls/certificate-authority"                   "${ENV_ROOT}/temp/certificate-authority"

# fix permissions.
chmod -R 777  "${ENV_ROOT}/temp/certificates"
chmod -R 777  "${ENV_ROOT}/temp/certificate-authority"

# cernbox web bundle configuration.
rm -rf "${ENV_ROOT}/temp/cernbox/cernbox-web-sciencemesh"
mkdir "${ENV_ROOT}/temp/cernbox/cernbox-web-sciencemesh"
unzip -qq "${ENV_ROOT}/temp/cernbox/cernbox-web-bundle.zip" -d "${ENV_ROOT}/temp/cernbox/cernbox-web-sciencemesh"
cd "${ENV_ROOT}/temp/cernbox/cernbox-web-sciencemesh/web/js"
sed -i "s|sciencemesh\.cesnet\.cz\/iop|meshdir\.docker|" web-app-science*mjs
rm web-app-science*mjs.gz
gzip web-app-science*mjs
cd "${ENV_ROOT}"
chmod -R 755 "${ENV_ROOT}/temp/cernbox/cernbox-web-sciencemesh"/*
sudo chown -R 101:101 "${ENV_ROOT}/temp/cernbox/cernbox-web-sciencemesh"/*

# auto clean before starting.
"${ENV_ROOT}/scripts/clean.sh" "no"

# make sure network exists.
docker network inspect testnet >/dev/null 2>&1 || docker network create testnet >/dev/null 2>&1


############
### IdP ####
############

createIdpKeycloak

############
### Reva ###
############

# syntax:
# createReva platform number port.
#
# 
# platform:   owncloud, nextcloud.
# number:     should be unique for each platform, for example: you cannot have two Nextclouds with same number.

createReva cernbox  1
createReva cernbox  2

###############
### CERNBox ###
###############

# syntax:
# createEfssCernBox number.
#
#
# number:         should be unique for each oCIS, for example: you cannot have two oCIS with same number.

# CERNBoxes.
createEfssCernBox cernbox 1
createEfssCernBox cernbox 2

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
  echo "Cypress inside VNC Server -> http://localhost:5700"
  echo "Embedded Firefox          -> http://localhost:5800"
  echo ""
  echo "Inside Embedded Firefox browse to EFSS hostname and enter the related credentials:"
  echo "https://cernbox1.docker -> username: einstein               password: relativity"
  echo "https://cernbox2.docker -> username: marie                  password: radioactivity"
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
  docker run --network=testnet                                                                              \
    --name="cypress.docker"                                                                                 \
    -v "${ENV_ROOT}/cypress/ocm-test-suite:/ocm"                                                            \
    -w /ocm                                                                                                 \
    cypress/included:13.13.1 cypress run                                                                    \
    --browser "${BROWSER_PLATFORM}"                                                                         \
    --spec "cypress/e2e/invite-link/cernbox-${P1_VER}-to-cernbox-${P2_VER}.cy.js"
  
  # revert config file back to normal.
  if [ "${BROWSER_PLATFORM}" != "electron" ]; then
    sed -i 's/.*video: false,.*/  video: true,/'                        "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"
    sed -i 's/.*videoCompression: false,.*/  videoCompression: true,/'  "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"
  fi

  # auto clean after running tests in ci mode. do not clear terminal.
  "${ENV_ROOT}/scripts/clean.sh" "no"
fi
