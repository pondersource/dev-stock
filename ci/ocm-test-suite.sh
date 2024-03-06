#!/usr/bin/env bash

# This script has some is different than tests/ocm-test-suite.sh in:
# 1. doesn't have VNC GUI
# 2. doesn't have Firefox 
# 3. doesn't have port mappings from container to host
# 4. doesn't detach Cypress and Cypress runs in headless mode.
# 5. docker runs SHOULD NOT contain -t flag. (This is a real pain in somewhere)

# @michielbdejong halt on error in docker init scripts
set -e

# get testing platform from arguments. default is chrome.
TEST_PLATFORM=${1:-"chrome"}

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

function waitForPort () {
  # the "| cat" after the "| grep" is to prevent the command from exiting with 1 if no match is found by grep.
  x=$(docker exec "${1}" ss -tulpn | grep -c "${2}" | cat)
  until [ "${x}" -ne 0 ]
  do
    sleep 1
    x=$(docker exec "${1}" ss -tulpn | grep -c "${2}" |  cat)
  done
}

function waitForCollabora() {
  x=$(docker logs collabora.docker | grep -c "Ready")
  until [ "${x}" -ne 0 ]
  do
    sleep 1
    x=$(docker logs collabora.docker | grep -c "Ready")
  done
}

function createEfss() {
  local platform=${1}
  local number=${2}
  local user=${3}
  local password=${4}

  echo "creating efss ${platform} ${number}"

  docker run --detach --network=testnet                                           \
    --name="maria${platform}${number}.docker"                                     \
    -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek             \
    mariadb                                                                       \
    --transaction-isolation=READ-COMMITTED                                        \
    --binlog-format=ROW                                                           \
    --innodb-file-per-table=1                                                     \
    --skip-innodb-read-only-compressed                                            \
    >/dev/null 2>&1

  docker run --detach --network=testnet                                           \
    --name="${platform}${number}.docker"                                          \
    --add-host "host.docker.internal:host-gateway"                                \
    -e HOST="${platform}${number}"                                                \
    -e DBHOST="maria${platform}${number}.docker"                                  \
    -e USER="${user}"                                                             \
    -e PASS="${password}"                                                         \
    -v "${ENV_ROOT}/docker/tls:/tls-host"                                         \
    -v "${ENV_ROOT}/temp/${platform}.sh:/${platform}-init.sh"                     \
    -v "${ENV_ROOT}/docker/scripts/entrypoint.sh:/entrypoint.sh"                  \
    -v "${ENV_ROOT}/${platform}/apps/sciencemesh:/var/www/html/apps/sciencemesh"  \
    "pondersource/dev-stock-${platform}-sciencemesh"                              \
    >/dev/null 2>&1

    # wait for hostname port to be open
    waitForPort "maria${platform}${number}.docker"  3306
    waitForPort "${platform}${number}.docker"       443

    # add self-signed certificates to os and trust them. (use >/dev/null 2>&1 to shut these up)
    docker exec "${platform}${number}.docker" bash -c "cp /tls/*.crt /usr/local/share/ca-certificates/"                                         >/dev/null 2>&1
    docker exec "${platform}${number}.docker" bash -c "cp /tls-host/*.crt /usr/local/share/ca-certificates/"                                    >/dev/null 2>&1
    docker exec "${platform}${number}.docker" update-ca-certificates                                                                            >/dev/null 2>&1
    docker exec "${platform}${number}.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt"  >/dev/null 2>&1

    # run init script inside efss.
    docker exec -u www-data "${platform}${number}.docker" sh "/${platform}-init.sh" >/dev/null 2>&1
}

function createReva() {
  local platform=${1}
  local number=${2}
  local port=${3}

  echo "creating reva for ${platform} ${number}"

  # make sure scripts are executable.
  chmod +x "${ENV_ROOT}/docker/scripts/reva-run.sh"           >/dev/null 2>&1
  chmod +x "${ENV_ROOT}/docker/scripts/reva-kill.sh"          >/dev/null 2>&1
  chmod +x "${ENV_ROOT}/docker/scripts/reva-entrypoint.sh"    >/dev/null 2>&1

  # TODO: remember to uncomment this line when collabora is integrated into ci
  # waitForCollabora

  docker run --detach --network=testnet                                       \
  --name="reva${platform}${number}.docker"                                    \
  -e HOST="reva${platform}${number}"                                          \
  -p "${port}:80"                                                             \
  -v "${ENV_ROOT}/reva:/reva"                                                 \
  -v "${ENV_ROOT}/docker/tls:/etc/tls"                                        \
  -v "${ENV_ROOT}/docker/revad:/configs/revad"                                \
  -v "${ENV_ROOT}/docker/scripts/reva-run.sh:/usr/bin/reva-run.sh"            \
  -v "${ENV_ROOT}/docker/scripts/reva-kill.sh:/usr/bin/reva-kill.sh"          \
  -v "${ENV_ROOT}/docker/scripts/reva-entrypoint.sh:/entrypoint.sh"           \
  pondersource/dev-stock-revad                                                \
  >/dev/null 2>&1
}

function sciencemeshInsertIntoDB() {
  local platform=${1}
  local number=${2}

  # run db injections.
  mysql_cmd="docker exec "maria${platform}${number}.docker" mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss"
  $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'iopUrl', 'https://reva${platform}${number}.docker/');"          >/dev/null 2>&1
  $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'revaSharedSecret', 'shared-secret-1');"                         >/dev/null 2>&1 
  $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'meshDirectoryUrl', 'https://meshdir.docker/meshdir');"          >/dev/null 2>&1
  $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'inviteManagerApikey', 'invite-manager-endpoint');"              >/dev/null 2>&1
}


# create temp directory if it doesn't exist.
[ ! -d "${ENV_ROOT}/temp" ] && mkdir --parents "${ENV_ROOT}/temp"

# copy init files.
cp -f ./docker/scripts/init-owncloud-sciencemesh.sh  ./temp/owncloud.sh
cp -f ./docker/scripts/init-nextcloud-sciencemesh.sh ./temp/nextcloud.sh

# make sure network exists.
docker network inspect testnet >/dev/null 2>&1 || docker network create testnet >/dev/null 2>&1

############
### EFSS ###
############

# syntax:
# createEfss platform number username password
#
# 
# platform:   owncloud, nextcloud.
# number:     should be unique for each platform, you cannot have two nextclouds with same number.
# username:   username for sign in into efss.
# password:   password for sign in into efss.

# ownClouds
createEfss owncloud 1 marie radioactivity
createEfss owncloud 2 mahdi baghbani

# Nextclouds
createEfss nextcloud 1 einstein relativity
createEfss nextcloud 2 michiel  dejong

############
### Reva ###
############

# syntax:
# createReva platform number port
#
# 
# platform:   owncloud, nextcloud.
# number:     should be unique for each platform, you cannot have two nextclouds with same number.
# port:       maps a port on local host to port 80 of reva, for `curl` puposes! should be unique.
#             for all createReva commands, if the port is not unique or is already in use by another.
#             program, script would halt!

createReva owncloud  1 4501
createReva owncloud  2 4502

createReva nextcloud 1 4503
createReva nextcloud 2 4504

###################
### ScienceMesh ###
###################

# syntax:
# sciencemeshInsertIntoDB platform number
#
# 
# platform:   owncloud, nextcloud.
# number:     should be unique for each platform, you cannot have two nextclouds with same number.

sciencemeshInsertIntoDB owncloud 1
sciencemeshInsertIntoDB owncloud 2

sciencemeshInsertIntoDB nextcloud 1
sciencemeshInsertIntoDB nextcloud 2

# Mesh directory for ScienceMesh invite flow.
docker run --detach --network=testnet                                         \
  --name=meshdir.docker                                                       \
  -v "${ENV_ROOT}/docker/scripts/stub.js:/ocm-stub/stub.js"                   \
  pondersource/dev-stock-ocmstub                                              \
  >/dev/null 2>&1

###############
### Cypress ###
###############

# run Cypress test suite headlessly and with the defined browser.
docker run --network=testnet                                                  \
  --name="cypress.docker"                                                     \
  -v "${ENV_ROOT}/cypress/ocm-tests:/ocm"                                     \
  -w /ocm                                                                     \
  cypress/included:13.3.0 cypress run --browser "${TEST_PLATFORM}"
