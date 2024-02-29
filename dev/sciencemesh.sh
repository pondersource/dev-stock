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

function waitForPort () {
  echo waitForPort "${1}" "${2}"
  # the "| cat" after the "| grep" is to prevent the command from exiting with 1 if no match is found by grep.
  x=$(docker exec -it "${1}" ss -tulpn | grep -c "${2}" | cat)
  until [ "${x}" -ne 0 ]
  do
    echo Waiting for "${1}" to open port "${2}", this usually takes about 10 seconds ... "${x}"
    sleep 1
    x=$(docker exec -it "${1}" ss -tulpn | grep -c "${2}" |  cat)
  done
  echo "${1}" port "${2}" is open
}

function waitForCollabora() {
  x=$(docker logs collabora.docker | grep -c "Ready")
  until [ "${x}" -ne 0 ]
  do
    echo Waiting for Collabora to be ready, this usually takes about 10 seconds ... "${x}"
    sleep 1
    x=$(docker logs collabora.docker | grep -c "Ready")
  done
  echo "Collabora is ready"
}

function createEfss() {
  local platform="${1}"
  local number="${2}"
  local user="${3}"
  local password="${4}"
  local image="${5}"

  if [[ -z "${image}" ]]; then
    local image="pondersource/dev-stock-${platform}"
  else
    local image="pondersource/dev-stock-${platform}-${image}"
  fi

  echo "creating efss ${platform} ${number}"

  docker run --detach --network=testnet                                           \
    --name="maria${platform}${number}.docker"                                     \
    -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek             \
    mariadb                                                                       \
    --transaction-isolation=READ-COMMITTED                                        \
    --binlog-format=ROW                                                           \
    --innodb-file-per-table=1                                                     \
    --skip-innodb-read-only-compressed

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
    "${image}"

    # wait for hostname port to be open.
    waitForPort "maria${platform}${number}.docker"  3306
    waitForPort "${platform}${number}.docker"       443

    # add self-signed certificates to os and trust them. (use >/dev/null 2>&1 to shut these up)
    docker exec "${platform}${number}.docker" bash -c "cp /tls/*.crt /usr/local/share/ca-certificates/"                                         >/dev/null 2>&1
    docker exec "${platform}${number}.docker" bash -c "cp /tls-host/*.crt /usr/local/share/ca-certificates/"                                    >/dev/null 2>&1
    docker exec "${platform}${number}.docker" update-ca-certificates                                                                            >/dev/null 2>&1
    docker exec "${platform}${number}.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt"  >/dev/null 2>&1

    # run init script inside efss.
    docker exec -u www-data "${platform}${number}.docker" sh "/${platform}-init.sh"

    echo ""
}

function createReva() {
  local platform="${1}"
  local number="${2}"
  local port="${3}"

  echo "creating reva for ${platform} ${number}"

  # make sure scripts are executable.
  chmod +x "${ENV_ROOT}/docker/scripts/reva-run.sh"           >/dev/null 2>&1
  chmod +x "${ENV_ROOT}/docker/scripts/reva-kill.sh"          >/dev/null 2>&1
  chmod +x "${ENV_ROOT}/docker/scripts/reva-entrypoint.sh"    >/dev/null 2>&1

  waitForCollabora

  docker run --detach --network=testnet                                       \
  --name="reva${platform}${number}.docker"                                    \
  -e HOST="reva${platform}${number}"                                          \
  -p "${port}:80"                                                             \
  -v "${ENV_ROOT}/reva:/reva"                                                 \
  -v "${ENV_ROOT}/docker/revad:/etc/revad"                                    \
  -v "${ENV_ROOT}/docker/tls:/etc/revad/tls"                                  \
  -v "${ENV_ROOT}/docker/scripts/reva-run.sh:/usr/bin/reva-run.sh"            \
  -v "${ENV_ROOT}/docker/scripts/reva-kill.sh:/usr/bin/reva-kill.sh"          \
  -v "${ENV_ROOT}/docker/scripts/reva-entrypoint.sh:/entrypoint.sh"           \
  pondersource/dev-stock-revad                                                \
  >/dev/null 2>&1
}

function sciencemeshInsertIntoDB() {
  local platform="${1}"
  local number="${2}"

  echo "configuring ScienceMesh app for efss ${platform} ${number}"

  # run db injections.
  mysql_cmd="docker exec "maria${platform}${number}.docker" mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss"
  $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'iopUrl', 'https://reva${platform}${number}.docker/');"          >/dev/null 2>&1
  $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'revaSharedSecret', 'shared-secret-1');"                         >/dev/null 2>&1
  $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'meshDirectoryUrl', 'https://meshdir.docker/meshdir');"          >/dev/null 2>&1
  $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'inviteManagerApikey', 'invite-manager-endpoint');"              >/dev/null 2>&1
}

# delete and create temp directory.
rm -rf "${ENV_ROOT}/temp" && mkdir --parents "${ENV_ROOT}/temp"

# copy init files.
cp -f "${ENV_ROOT}/docker/scripts/init-owncloud-sciencemesh.sh"   "${ENV_ROOT}/temp/owncloud.sh"
cp -f "${ENV_ROOT}/docker/scripts/init-nextcloud-sciencemesh.sh"  "${ENV_ROOT}/temp/nextcloud.sh"

# make sure network exists.
docker network inspect testnet >/dev/null 2>&1 || docker network create testnet >/dev/null 2>&1

docker run --detach --name=collabora.docker --network=testnet -p 9980:9980 -t -e "extra_params=--o:ssl.enable=false" collabora/code:latest  >/dev/null 2>&1
docker run --detach --name=wopi.docker      --network=testnet -p 8880:8880 -t cs3org/wopiserver:latest  >/dev/null 2>&1
#docker run --detach --name=rclone.docker    --network=testnet  rclone/rclone rcd -vv --rc-user=rcloneuser --rc-pass=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek --rc-addr=0.0.0.0:5572 --server-side-across-configs=true --log-file=/dev/stdout

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
# image:      which image variation to use for container.

# ownClouds.
createEfss owncloud   1   marie     radioactivity     sciencemesh
createEfss owncloud   2   mahdi     baghbani          sciencemesh

# Nextclouds.
createEfss nextcloud  1   einstein  relativity        sciencemesh
createEfss nextcloud  2   michiel   dejong            sciencemesh

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

###################
### ScienceMesh ###
###################

# syntax:
# sciencemeshInsertIntoDB platform number.
#
# 
# platform:   owncloud, nextcloud.
# number:     should be unique for each platform, for example: you cannot have two Nextclouds with same number.

sciencemeshInsertIntoDB owncloud  1
sciencemeshInsertIntoDB owncloud  2

sciencemeshInsertIntoDB nextcloud 1
sciencemeshInsertIntoDB nextcloud 2

# Mesh directory for ScienceMesh invite flow.
docker run --detach --network=testnet                                         \
  --name=meshdir.docker                                                       \
  -v "${ENV_ROOT}/docker/scripts/stub.js:/ocm-stub/stub.js"                   \
  pondersource/dev-stock-ocmstub                                              \
  >/dev/null 2>&1

###############
### Firefox ###
###############

docker run --detach --network=testnet                                          \
  --name=firefox                                                               \
  -p 5800:5800                                                                 \
  --shm-size 2g                                                                \
  jlesage/firefox:latest                                                       \
  >/dev/null 2>&1

# print instructions.
clear
echo "Now browse to :"
echo "Embedded Firefox          -> http://localhost:5800"
echo ""
echo "Inside Embedded Firefox browse to EFSS hostname and enter the related credentials:"
echo "https://owncloud1.docker  -> username: marie      password: radioactivity"
echo "https://owncloud2.docker  -> username: mahdi      password: baghbani"
echo "https://nextcloud1.docker -> username: einstein   password: relativity"
echo "https://nextcloud2.docker -> username: michiel    password: dejong"
