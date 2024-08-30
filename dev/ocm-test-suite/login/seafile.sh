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

# seafile version:
#   - 8.0.8
#   - 9.0.10
#   - 10.0.1
#   - 11.0.5
EFSS_PLATFORM_VERSION=${1:-"11.0.5"}

# script mode:   dev, ci. default is dev.
SCRIPT_MODE=${2:-"dev"}

# browser platform: chrome, edge, firefox, electron. default is electron.
# only applies on SCRIPT_MODE=ci
BROWSER_PLATFORM=${3:-"electron"}

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

function createEfssSeafile() {
  local platform="${1}"
  local number="${2}"
  local user_email="${3}"
  local password="${4}"
  local remote_ocm_server="${5}"
  local tag="${6-latest}"

  redirect_to_null_cmd echo "creating efss ${platform} ${number}"

  redirect_to_null_cmd docker run --detach --network=testnet                                                                \
    --name="memcache${platform}${number}.docker"                                                                            \
    memcached:1.6.18                                                                                                        \
    memcached -m 256
  
  redirect_to_null_cmd docker run --detach --network=testnet                                                                \
    --name="maria${platform}${number}.docker"                                                                               \
    -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek                                                       \
    mariadb:11.4.2                                                                                                          \
    --transaction-isolation=READ-COMMITTED                                                                                  \
    --binlog-format=ROW                                                                                                     \
    --innodb-file-per-table=1                                                                                               \
    --skip-innodb-read-only-compressed

  redirect_to_null_cmd docker run --detach --network=testnet                                                                \
    --name="${platform}${number}.docker"                                                                                    \
    -e TIME_ZONE="Etc/UTC"                                                                                                  \
    -e DB_HOST="maria${platform}${number}.docker"                                                                           \
    -e DB_ROOT_PASSWD="eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek"                                                            \
    -e SEAFILE_ADMIN_EMAIL="${user_email}"                                                                                  \
    -e SEAFILE_ADMIN_PASSWORD="${password}"                                                                                 \
    -e SEAFILE_SERVER_LETSENCRYPT=false                                                                                     \
    -e FORCE_HTTPS_IN_CONF=false                                                                                            \
    -e SEAFILE_SERVER_HOSTNAME="${platform}${number}.docker"                                                                \
    -e SEAFILE_MEMCACHE_HOST="memcache${platform}${number}.docker"                                                          \
    -e SEAFILE_MEMCACHE_PORT=11211                                                                                          \
    -v "${ENV_ROOT}/temp/sea-init.sh:/init.sh"                                                                              \
    -v "${ENV_ROOT}/temp/seafile-data/${platform}${number}:/shared"                                                         \
    -v "${ENV_ROOT}/docker/tls/certificates/${platform}${number}.crt:/shared/ssl/${platform}${number}.docker.crt"           \
    -v "${ENV_ROOT}/docker/tls/certificates/${platform}${number}.key:/shared/ssl/${platform}${number}.docker.key"           \
    -v "${ENV_ROOT}/docker/tls/certificates:/certificates"                                                                  \
    -v "${ENV_ROOT}/docker/tls/certificate-authority:/certificate-authority"                                                \
    "seafileltd/seafile-mc:${tag}"

  # wait for hostname port to be open.
  waitForPort "maria${platform}${number}.docker"  3306

  # add self-signed certificates to os and trust them. (use >/dev/null 2>&1 to shut these up)
  docker exec "${platform}${number}.docker" bash -c "cp -f /certificates/*.crt                    /usr/local/share/ca-certificates/ || true"                    >/dev/null 2>&1
  docker exec "${platform}${number}.docker" bash -c "cp -f /certificate-authority/*.crt           /usr/local/share/ca-certificates/ || true"                    >/dev/null 2>&1
  docker exec "${platform}${number}.docker" update-ca-certificates                                                                                              >/dev/null 2>&1

  # seafile needs time to bootstrap itself.
  sleep 5

  # run init script inside seafile.
  redirect_to_null_cmd docker exec -e remote_ocm_server="${remote_ocm_server}" "${platform}${number}.docker" bash -c "/init.sh ${remote_ocm_server}"

  # restart seafile to apply our changes.
  sleep 2
  redirect_to_null_cmd docker restart "${platform}${number}.docker"
  sleep 2

  redirect_to_null_cmd echo ""
}

# delete and create temp directory.
rm -rf "${ENV_ROOT}/temp" && mkdir -p "${ENV_ROOT}/temp"

# copy init files.
cp -f "${ENV_ROOT}/docker/scripts/init/seafile.sh"                    "${ENV_ROOT}/temp/sea-init.sh"

# auto clean before starting.
"${ENV_ROOT}/scripts/clean.sh" "no"

# make sure network exists.
docker network inspect testnet >/dev/null 2>&1 || docker network create testnet >/dev/null 2>&1

###############
### Seafile ###
###############

createEfssSeafile   seafile   1   jonathan@seafile.com   xu   seafile2   "${EFSS_PLATFORM_VERSION}"

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
  echo "http://seafile1.docker -> username: jonathan@seafile.com   password: xu"
else
  # only record when testing on electron.
  if [ "${BROWSER_PLATFORM}" != "electron" ]; then
    sed -i 's/.*video: true,.*/video: false,/'                          "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"
    sed -i 's/.*videoCompression: true,.*/videoCompression: false,/'    "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"
  fi
  ##################
  ### Cypress CI ###
  ##################

  # run Cypress test suite headlessly and with the defined browser.
  docker run --network=testnet                                                  \
    --name="cypress.docker"                                                     \
    -v "${ENV_ROOT}/cypress/ocm-test-suite:/ocm"                                \
    -w /ocm                                                                     \
    cypress/included:13.13.1 cypress run                                        \
    --browser "${BROWSER_PLATFORM}"                                             \
    --spec "cypress/e2e/login/seafile.cy.js"
  
  # revert config file back to normal.
  if [ "${BROWSER_PLATFORM}" != "electron" ]; then
    sed -i 's/.*video: false,.*/  video: true,/'                        "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"
    sed -i 's/.*videoCompression: false,.*/  videoCompression: true,/'  "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"
  fi

  # auto clean after running tests in ci mode. do not clear terminal.
  "${ENV_ROOT}/scripts/clean.sh" "no"
fi
