#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -ex

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

# script mode:   dev, ci. default is dev.
SCRIPT_MODE=${1:-"dev"}

# test platform: chrome, edge, firefox, electron. default is chrome.
# only applies on SCRIPT_MODE=ci
TEST_PLATFORM=${2:-"chrome"}

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

function createSeafile() {
  local platform="${1}"
  local number="${2}"
  local user_email="${3}"
  local password="${4}"
  local remote_ocm_server="${5}"

  redirect_to_null_cmd echo "creating efss ${platform} ${number}"

  redirect_to_null_cmd docker run --detach --network=testnet                                                                \
    --name="memcache${platform}${number}.docker"                                                                            \
    memcached:1.6.18                                                                                                        \
    memcached -m 256
  
  redirect_to_null_cmd docker run --detach --network=testnet                                                                \
    --name="maria${platform}${number}.docker"                                                                               \
    -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek                                                       \
    mariadb                                                                                                                 \
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
    -v "${ENV_ROOT}/seafile-data/${platform}${number}:/shared"                                                              \
    -v "${ENV_ROOT}/temp/sea-init.sh:/init.sh"                                                                              \
    -v "${ENV_ROOT}/docker/tls/certificates/${platform}${number}.crt:/shared/ssl/${platform}${number}.docker.crt"           \
    -v "${ENV_ROOT}/docker/tls/certificates/${platform}${number}.key:/shared/ssl/${platform}${number}.docker.key"           \
    -v "${ENV_ROOT}/docker/tls/certificates:/certificates"                                                                  \
    -v "${ENV_ROOT}/docker/tls/certificate-authority:/certificate-authority"                                                \
    seafileltd/seafile-mc:11.0.5

  # wait for hostname port to be open.
  waitForPort "maria${platform}${number}.docker"  3306

  # add self-signed certificates to os and trust them. (use >/dev/null 2>&1 to shut these up)
  docker exec "${platform}${number}.docker" bash -c "cp -f /certificates/*.crt                    /usr/local/share/ca-certificates/ || true"                    >/dev/null 2>&1
  docker exec "${platform}${number}.docker" bash -c "cp -f /certificate-authority/*.crt           /usr/local/share/ca-certificates/ || true"                    >/dev/null 2>&1
  docker exec "${platform}${number}.docker" update-ca-certificates                                                                                              >/dev/null 2>&1

  # seafile needs time to bootstrap itself.
  sleep 5

  # run init script inside seafile.
  docker exec -e remote_ocm_server="${remote_ocm_server}" "${platform}${number}.docker" bash -c "/init.sh ${remote_ocm_server}"

  # restart seafile to apply our changes.
  sleep 2
  docker restart "${platform}${number}.docker"
  sleep 2

  redirect_to_null_cmd echo ""
}

function createEfss() {
  local platform="${1}"
  local number="${2}"
  local user="${3}"
  local password="${4}"
  local init_script="${5}"
  local tag="${6-latest}"
  local image="${7}"

  if [[ -z "${image}" ]]; then
    local image="pondersource/dev-stock-${platform}"
  else
    local image="pondersource/dev-stock-${platform}-${image}"
  fi

  redirect_to_null_cmd echo "creating efss ${platform} ${number}"

  redirect_to_null_cmd docker run --detach --network=testnet                                                                \
    --name="maria${platform}${number}.docker"                                                                               \
    -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek                                                       \
    mariadb                                                                                                                 \
    --transaction-isolation=READ-COMMITTED                                                                                  \
    --binlog-format=ROW                                                                                                     \
    --innodb-file-per-table=1                                                                                               \
    --skip-innodb-read-only-compressed

  redirect_to_null_cmd docker run --detach --network=testnet                                                                \
    --name="${platform}${number}.docker"                                                                                    \
    --add-host "host.docker.internal:host-gateway"                                                                          \
    -e HOST="${platform}${number}"                                                                                          \
    -e DBHOST="maria${platform}${number}.docker"                                                                            \
    -e USER="${user}"                                                                                                       \
    -e PASS="${password}"                                                                                                   \
    -v "${ENV_ROOT}/temp/federatedgroups:/curls"                                                                            \
    -v "${ENV_ROOT}/docker/tls/certificates:/certificates"                                                                  \
    -v "${ENV_ROOT}/docker/tls/certificate-authority:/certificate-authority"                                                \
    -v "${ENV_ROOT}/temp/${init_script}:/${platform}-init.sh"                                                               \
    -v "${ENV_ROOT}/docker/scripts/entrypoint.sh:/entrypoint.sh"                                                            \
    -v "${ENV_ROOT}/${platform}/apps/sciencemesh:/var/www/html/apps/sciencemesh"                                            \
    "${image}:${tag}"

  # wait for hostname port to be open.
  waitForPort "maria${platform}${number}.docker"  3306
  waitForPort "${platform}${number}.docker"       443

  # add self-signed certificates to os and trust them. (use >/dev/null 2>&1 to shut these up)
  docker exec "${platform}${number}.docker" bash -c "cp -f /certificates/*.crt                    /usr/local/share/ca-certificates/ || true"            >/dev/null 2>&1
  docker exec "${platform}${number}.docker" bash -c "cp -f /certificate-authority/*.crt           /usr/local/share/ca-certificates/ || true"            >/dev/null 2>&1
  docker exec "${platform}${number}.docker" bash -c "cp -f /tls/*.crt                             /usr/local/share/ca-certificates/ || true"            >/dev/null 2>&1
  docker exec "${platform}${number}.docker" update-ca-certificates                                                                                      >/dev/null 2>&1
  docker exec "${platform}${number}.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt"            >/dev/null 2>&1

  # run init script inside efss.
  redirect_to_null_cmd docker exec -u www-data "${platform}${number}.docker" bash "/${platform}-init.sh"

  redirect_to_null_cmd echo ""
}

function createReva() {
  local platform="${1}"
  local number="${2}"
  local port="${3}"

  redirect_to_null_cmd echo "creating reva for ${platform} ${number}"

  # make sure scripts are executable.
  chmod +x "${ENV_ROOT}/temp/reva/run.sh"                       >/dev/null 2>&1
  chmod +x "${ENV_ROOT}/temp/reva/kill.sh"                      >/dev/null 2>&1
  chmod +x "${ENV_ROOT}/temp/reva/entrypoint.sh"                >/dev/null 2>&1

  if [ "${SCRIPT_MODE}" = "dev" ]; then
    waitForCollabora
  fi

  docker run --detach --network=testnet                                                                       \
  --name="reva${platform}${number}.docker"                                                                    \
  -e HOST="reva${platform}${number}"                                                                          \
  -p "${port}:80"                                                                                             \
  -v "${ENV_ROOT}/reva:/reva"                                                                                 \
  -v "${ENV_ROOT}/docker/tls/certificates:/certificates"                                                      \
  -v "${ENV_ROOT}/docker/tls/certificate-authority:/certificate-authority"                                    \
  -v "${ENV_ROOT}/temp/revad:/configs/revad"                                                                  \
  -v "${ENV_ROOT}/temp/reva/run.sh:/usr/bin/run.sh"                                                           \
  -v "${ENV_ROOT}/temp/reva/kill.sh:/usr/bin/kill.sh"                                                         \
  -v "${ENV_ROOT}/temp/reva/entrypoint.sh:/usr/bin/entrypoint.sh"                                             \
  pondersource/dev-stock-revad                                                                                \
  >/dev/null 2>&1
}

function sciencemeshInsertIntoDB() {
  local platform="${1}"
  local number="${2}"

  redirect_to_null_cmd echo "configuring ScienceMesh app for efss ${platform} ${number}"

  # run db injections.
  mysql_cmd="docker exec "maria${platform}${number}.docker" mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss"
  $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'iopUrl', 'https://reva${platform}${number}.docker/');"          >/dev/null 2>&1
  $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'revaSharedSecret', 'shared-secret-1');"                         >/dev/null 2>&1
  $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'meshDirectoryUrl', 'https://meshdir.docker/meshdir');"          >/dev/null 2>&1
  $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'inviteManagerApikey', 'invite-manager-endpoint');"              >/dev/null 2>&1
}

function federatedGroupsInsertIntoDB() {
  local platform="${1}"
  local number="${2}"

  redirect_to_null_cmd echo "configuring scim control for <federated groups> for efss ${platform} ${number}"

  # run db injections.
  mysql_cmd="docker exec "maria${platform}${number}.docker" mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss"
  $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) VALUES ('federatedgroups', 'scim_token', 'something-super-secret');"                  >/dev/null 2>&1

  redirect_to_null_cmd echo "creating federated group 'TestGroup (uniharderwijk_surfdrive_test) (SRAM CO)' on ${platform}${number}"
  docker exec -it "${platform}${number}.docker" sh /curls/createGroup.sh "${platform}${number}.docker"                                                          >/dev/null 2>&1

  docker exec -it "${platform}${number}.docker" sh /curls/includeMarie.sh "${platform}${number}.docker"                                                         >/dev/null 2>&1
}

# delete and create temp directory.
rm -rf "${ENV_ROOT}/temp" && mkdir --parents "${ENV_ROOT}/temp"

# copy init files.
cp -fr  "${ENV_ROOT}/docker/scripts/reva"                               "${ENV_ROOT}/temp/"
cp -fr  "${ENV_ROOT}/docker/configs/revad"                              "${ENV_ROOT}/temp/"
cp -fr  "${ENV_ROOT}/docker/scripts/federatedgroups"                    "${ENV_ROOT}/temp/"
cp -f   "${ENV_ROOT}/docker/scripts/ocmstub/index.js"                   "${ENV_ROOT}/temp/index.js"
cp -f   "${ENV_ROOT}/docker/scripts/init/seafile.sh"                    "${ENV_ROOT}/temp/sea-init.sh"
cp -f   "${ENV_ROOT}/docker/scripts/init-owncloud-sm-ocm.sh"            "${ENV_ROOT}/temp/owncloud.sh"
cp -f   "${ENV_ROOT}/docker/scripts/init-nextcloud-ocm-test-suite.sh"   "${ENV_ROOT}/temp/nextcloud.sh"
cp -f   "${ENV_ROOT}/docker/scripts/init-owncloud-federatedgroups.sh"   "${ENV_ROOT}/temp/owncloud-fg.sh"

sed -i 's/owncloud1/owncloud3/g'                                        "${ENV_ROOT}/temp/federatedgroups/createGroup.sh"
sed -i 's/owncloud1/owncloud3/g'                                        "${ENV_ROOT}/temp/federatedgroups/includeMarie.sh"
sed -i 's/owncloud1/owncloud3/g'                                        "${ENV_ROOT}/temp/federatedgroups/excludeMarie.sh"
sed -i 's/owncloud2/owncloud4/g'                                        "${ENV_ROOT}/temp/federatedgroups/createGroup.sh"
sed -i 's/owncloud2/owncloud4/g'                                        "${ENV_ROOT}/temp/federatedgroups/includeMarie.sh"
sed -i 's/owncloud2/owncloud4/g'                                        "${ENV_ROOT}/temp/federatedgroups/excludeMarie.sh"

# auto clean before starting.
"${ENV_ROOT}/scripts/clean.sh" "no"

# make sure network exists.
docker network inspect testnet >/dev/null 2>&1 || docker network create testnet >/dev/null 2>&1

# NOTE: collabora doesn't work on github ci, disable ScienceMesh apps for now.
if [ "${SCRIPT_MODE}" = "dev" ]; then
  docker run --detach --name=collabora.docker --network=testnet -p 9980:9980 -t -e "extra_params=--o:ssl.enable=false" collabora/code:latest  >/dev/null 2>&1
  docker run --detach --name=wopi.docker      --network=testnet -p 8880:8880 -t cs3org/wopiserver:latest  >/dev/null 2>&1
  #docker run --detach --name=rclone.docker    --network=testnet  rclone/rclone rcd -vv --rc-user=rcloneuser --rc-pass=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek --rc-addr=0.0.0.0:5572 --server-side-across-configs=true --log-file=/dev/stdout
fi

# NOTE: collabora doesn't work on github ci, disable ScienceMesh apps for now.
if [ "${SCRIPT_MODE}" = "ci" ]; then
  rm -f "${ENV_ROOT}/temp/revad/sciencemesh-apps-collabora.toml"
fi

############
### EFSS ###
############

# syntax:
# createEfss platform number username password image.
#
#
# platform:   owncloud, nextcloud.
# number:     should be unique for each platform, for example: you cannot have two Nextclouds with same number.
# username:   username for sign in into efss.
# password:   password for sign in into efss.
# tag:        tag for the image, use latest if not sure.
# image:      which image variation to use for container.

# ownClouds
createEfss    owncloud   1   marie                    radioactivity     owncloud.sh         latest        ocm-test-suite
createEfss    owncloud   2   mahdi                    baghbani          owncloud.sh         latest        ocm-test-suite

createEfss    owncloud   3   einstein                 relativity        owncloud-fg.sh      latest        federatedgroups
createEfss    owncloud   4   marie                    radioactivity     owncloud-fg.sh      latest        federatedgroups

# Nextclouds
createEfss    nextcloud  1   einstein                 relativity        nextcloud.sh        latest        sciencemesh
createEfss    nextcloud  2   michiel                  dejong            nextcloud.sh        latest        sciencemesh

createEfss    nextcloud  3   yashar                   pmh               nextcloud.sh        v28.0.3 
createEfss    nextcloud  4   madeline                 oleary            nextcloud.sh        v28.0.3

# Seafiles
createSeafile seafile    1  jonathan@seafile.com      xu                 seafile2
createSeafile seafile    2  giuseppe@cern.ch          lopresti           seafile1

############
### Reva ###
############

# syntax:
# createReva platform number port.
#
# 
# platform:   owncloud, nextcloud.
# number:     should be unique for each platform, for example: you cannot have two Nextclouds with same number.
# port:       maps a port on local host to port 80 of reva, for `curl` purposes! should be unique.
#             for all createReva commands, if the port is not unique or is already in use by another.
#             program, script would halt!

createReva owncloud  1 4501
createReva owncloud  2 4502

createReva nextcloud 1 4503
createReva nextcloud 2 4504

createReva nextcloud 3 4505
createReva nextcloud 4 4506

###################
### ScienceMesh ###
###################

# syntax:
# sciencemeshInsertIntoDB platform number.
#
# 
# platform:   owncloud, nextcloud.
# number:     should be unique for each platform, for example: you cannot have two Nextclouds with same number.

sciencemeshInsertIntoDB owncloud    1
sciencemeshInsertIntoDB owncloud    2

sciencemeshInsertIntoDB nextcloud   1
sciencemeshInsertIntoDB nextcloud   2

########################
### Federated Groups ###
########################

# syntax:
# federatedGroupsInsertIntoDB platform number.
#
# 
# platform:   owncloud, nextcloud.
# number:     should be unique for each platform, for example: you cannot have two Nextclouds with same number.

federatedGroupsInsertIntoDB owncloud  3
federatedGroupsInsertIntoDB owncloud  4

######################
### Mesh directory ###
######################
docker run --detach --network=testnet                                                                       \
  --name=meshdir.docker                                                                                     \
  -e HOST="meshdir"                                                                                         \
  -v "${ENV_ROOT}/temp/index.js:/ocmstub/index.js"                                                          \
  pondersource/dev-stock-ocmstub                                                                            \
  >/dev/null 2>&1

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
    cypress/included:13.3.0                                                                                 \
    open --project .

  # print instructions.
  clear
  echo "Now browse to :"
  echo "Cypress inside VNC Server -> http://localhost:5700"
  echo "Embedded Firefox          -> http://localhost:5800"
  echo ""
  echo "Inside Embedded Firefox browse to EFSS hostname and enter the related credentials:"
  echo "https://owncloud1.docker  -> username: marie                  password: radioactivity"
  echo "https://owncloud2.docker  -> username: mahdi                  password: baghbani"
  echo "https://owncloud3.docker  -> username: einstein               password: relativity"
  echo "https://owncloud4.docker  -> username: marie                  password: radioactivity"
  echo "https://nextcloud1.docker -> username: einstein               password: relativity"
  echo "https://nextcloud2.docker -> username: michiel                password: dejong"
  echo "https://nextcloud3.docker -> username: yahsar                 password: pmh"
  echo "https://nextcloud4.docker -> username: madeline               password: oleary"
  echo "https://seafile1.docker   -> username: jonathan@seafile.com   password: xu"
  echo "https://seafile2.docker   -> username: giuseppe@cern.ch       password: lopresti"
else
  # only record when testing on electron.
  if [ "${TEST_PLATFORM}" != "electron" ]; then
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
    cypress/included:13.3.0 cypress run --browser "${TEST_PLATFORM}"           || 
    true
  
  # revert config file back to normal.
  if [ "${TEST_PLATFORM}" != "electron" ]; then
    sed -i 's/.*video: false,.*/  video: true,/'                        "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"
    sed -i 's/.*videoCompression: false,.*/  videoCompression: true,/'  "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"
  fi

  # auto clean after running tests in ci mode. do not clear terminal.
  "${ENV_ROOT}/scripts/clean.sh" "no"
fi
