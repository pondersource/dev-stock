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
    -v "${ENV_ROOT}/docker/tls/certificates:/tls-host"                            \
    -v "${ENV_ROOT}/docker/tls/certificate-authority:/certificate-authority"      \
    -v "${ENV_ROOT}/temp/${platform}.sh:/${platform}-init.sh"                     \
    -v "${ENV_ROOT}/docker/scripts/entrypoint.sh:/entrypoint.sh"                  \
    "${image}"

    # wait for hostname port to be open.
    waitForPort "maria${platform}${number}.docker"  3306
    waitForPort "${platform}${number}.docker"       443

    # add self-signed certificates to os and trust them. (use >/dev/null 2>&1 to shut these up)
    docker exec "${platform}${number}.docker" bash -c "cp -f /tls/*.crt                             /usr/local/share/ca-certificates/"            >/dev/null 2>&1
    docker exec "${platform}${number}.docker" bash -c "cp -f /certificate-authority/*.crt           /usr/local/share/ca-certificates/"            >/dev/null 2>&1
    docker exec "${platform}${number}.docker" bash -c "cp -f /tls/*.crt                             /usr/local/share/ca-certificates/"            >/dev/null 2>&1
    docker exec "${platform}${number}.docker" update-ca-certificates                                                                              >/dev/null 2>&1
    docker exec "${platform}${number}.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt"    >/dev/null 2>&1

    # run init script inside efss.
    docker exec -u www-data "${platform}${number}.docker" bash "/${platform}-init.sh"

    echo ""
}

# delete and create temp directory.
rm -rf "${ENV_ROOT}/temp" && mkdir --parents "${ENV_ROOT}/temp"

# copy init files.
cp -f "${ENV_ROOT}/docker/scripts/init-owncloud.sh"   "${ENV_ROOT}/temp/owncloud.sh"
cp -f "${ENV_ROOT}/docker/scripts/init-nextcloud.sh"  "${ENV_ROOT}/temp/nextcloud.sh"

# make sure network exists.
docker network inspect testnet >/dev/null 2>&1 || docker network create testnet >/dev/null 2>&1

############
### EFSS ###
############

# syntax:
# createEfss platform number username password.
#
#
# platform:   owncloud, nextcloud.
# number:     should be unique for each platform, for example: you cannot have two Nextclouds with same number.
# username:   username for sign in into efss.
# password:   password for sign in into efss.

# ownClouds.
createEfss owncloud     1   marie     radioactivity
createEfss owncloud     2   mahdi     baghbani

# Nextclouds.
createEfss nextcloud    1   einstein  relativity
createEfss nextcloud    2   michiel   dejong

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

# print instructions.
clear
echo "Now browse to :"
echo "Embedded Firefox            -> http://localhost:5800"
echo ""
echo "Inside Embedded Firefox browse to EFSS hostname and enter the related credentials:"
echo "https://owncloud1.docker    -> username: marie      password: radioactivity"
echo "https://owncloud2.docker    -> username: mahdi      password: baghbani"
echo "https://nextcloud1.docker   -> username: einstein   password: relativity"
echo "https://nextcloud2.docker   -> username: michiel    password: dejong"
