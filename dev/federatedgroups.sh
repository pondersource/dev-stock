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

  docker run --detach --network=testnet                                                                   \
    --name="maria${platform}${number}.docker"                                                             \
    -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek                                     \
    mariadb                                                                                               \
    --transaction-isolation=READ-COMMITTED                                                                \
    --binlog-format=ROW                                                                                   \
    --innodb-file-per-table=1                                                                             \
    --skip-innodb-read-only-compressed

  docker run --detach --network=testnet                                                                   \
    --name="${platform}${number}.docker"                                                                  \
    --add-host "host.docker.internal:host-gateway"                                                        \
    -e HOST="${platform}${number}"                                                                        \
    -e DBHOST="maria${platform}${number}.docker"                                                          \
    -e USER="${user}"                                                                                     \
    -e PASS="${password}"                                                                                 \
    -v "${ENV_ROOT}/docker/tls:/tls-host"                                                                 \
    -v "${ENV_ROOT}/temp/curls:/curls"                                                                    \
    -v "${ENV_ROOT}/temp/${platform}.sh:/${platform}-init.sh"                                             \
    -v "${ENV_ROOT}/docker/scripts/entrypoint.sh:/entrypoint.sh"                                          \
    -v "${ENV_ROOT}/${platform}/apps/customgroups:/var/www/html/apps/customgroups"                        \
    -v "${ENV_ROOT}/${platform}/apps/opencloudmesh:/var/www/html/apps/opencloudmesh"                      \
    -v "${ENV_ROOT}/${platform}/apps/federatedgroups:/var/www/html/apps/federatedgroups"                  \
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

function federatedGroupsInsertIntoDB() {
  local platform="${1}"
  local number="${2}"

  echo "configuring scim control for <federated groups> for efss ${platform} ${number}"

  # run db injections.
  mysql_cmd="docker exec "maria${platform}${number}.docker" mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss"
  $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) VALUES ('federatedgroups', 'scim_token', 'something-super-secret');"

  echo "creating federated group 'TestGroup (uniharderwijk_surfdrive_test) (SRAM CO)' on ${platform}${number}"
  docker exec -it "${platform}${number}.docker" sh /curls/createGroup.sh "${platform}${number}.docker"

  docker exec -it "${platform}${number}.docker" sh /curls/excludeMarie.sh "${platform}${number}.docker"
}


# delete and create temp directory.
rm -rf "${ENV_ROOT}/temp" && mkdir --parents "${ENV_ROOT}/temp"

# copy init files.
cp -Rf "${ENV_ROOT}/docker/rd-sram/curls"                   "${ENV_ROOT}/temp/curls"
cp -f "${ENV_ROOT}/docker/scripts/init-owncloud-rd-sram.sh" "${ENV_ROOT}/temp/owncloud.sh"

# make sure network exists.
docker network inspect testnet >/dev/null 2>&1 || docker network create testnet >/dev/null 2>&1

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
createEfss owncloud   1   einstein  relativity        rd-sram
createEfss owncloud   2   marie     radioactivity     rd-sram

########################
### Federated Groups ###
########################

# syntax:
# federatedGroupsInsertIntoDB platform number.
#
# 
# platform:   owncloud, nextcloud.
# number:     should be unique for each platform, for example: you cannot have two Nextclouds with same number.

federatedGroupsInsertIntoDB owncloud  1
federatedGroupsInsertIntoDB owncloud  2

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
echo "https://owncloud1.docker  -> username: einstein   password: relativity"
echo "https://owncloud2.docker  -> username: marie      password: radioactivity"
echo ""
echo "share something from einstein@owncloud1.docker to Test Group, then run:"
echo "$ docker exec -it owncloud2.docker sh /curls/includeMarie.sh owncloud2.docker"
echo "$ docker exec -it owncloud1.docker sh /curls/includeMarie.sh owncloud1.docker"
echo "then log in to owncloud2.docker as marie, you should not have received the share"
echo "refresh the owncloud2.docker page, the share from einstein to Test Group should now also arrive to Marie"
