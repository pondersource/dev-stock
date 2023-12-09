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

export EFSS1=nextcloud
export EFSS2=owncloud

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

# create temp directory if it doesn't exist.
[ ! -d "${ENV_ROOT}/temp" ] && mkdir --parents "${ENV_ROOT}/temp"

# copy init files.
cp -f ./docker/scripts/init-owncloud-sciencemesh.sh  ./temp/owncloud.sh
cp -f ./docker/scripts/init-nextcloud-sciencemesh.sh ./temp/nextcloud.sh

docker run --detach --network=testnet                                         \
  --name=meshdir.docker                                                       \
  -v "${ENV_ROOT}/docker/scripts/stub.js:/ocm-stub/stub.js"                   \
  pondersource/dev-stock-ocmstub                                              \
  >/dev/null 2>&1

# EFSS1
docker run --detach --network=testnet                                         \
  --name=maria1.docker                                                        \
  -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek           \
  mariadb                                                                     \
  --transaction-isolation=READ-COMMITTED                                      \
  --binlog-format=ROW                                                         \
  --innodb-file-per-table=1                                                   \
  --skip-innodb-read-only-compressed                                          \
  >/dev/null 2>&1

docker run --detach --network=testnet                                         \
  --name="${EFSS1}1.docker"                                                   \
  --add-host "host.docker.internal:host-gateway"                              \
  -e HOST="${EFSS1}1"                                                         \
  -e DBHOST="maria1.docker"                                                   \
  -e USER="einstein"                                                          \
  -e PASS="relativity"                                                        \
  -v "${ENV_ROOT}/docker/tls:/tls-host"                                       \
  -v "${ENV_ROOT}/temp/${EFSS1}.sh:/${EFSS1}-init.sh"                         \
  -v "${ENV_ROOT}/docker/scripts/entrypoint.sh:/entrypoint.sh"                \
  -v "${ENV_ROOT}/${EFSS1}/apps/sciencemesh:/var/www/html/apps/sciencemesh"   \
  "pondersource/dev-stock-${EFSS1}-sciencemesh"                               \
  >/dev/null 2>&1

# EFSS2
docker run --detach --network=testnet                                         \
  --name=maria2.docker                                                        \
  -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek           \
  mariadb                                                                     \
  --transaction-isolation=READ-COMMITTED                                      \
  --binlog-format=ROW                                                         \
  --innodb-file-per-table=1                                                   \
  --skip-innodb-read-only-compressed                                          \
  >/dev/null 2>&1

docker run --detach --network=testnet                                         \
  --name="${EFSS2}2.docker"                                                   \
  --add-host "host.docker.internal:host-gateway"                              \
  -e HOST="${EFSS2}2"                                                         \
  -e DBHOST="maria2.docker"                                                   \
  -e USER="marie"                                                             \
  -e PASS="radioactivity"                                                     \
  -v "${ENV_ROOT}/docker/tls:/tls-host"                                       \
  -v "${ENV_ROOT}/temp/${EFSS2}.sh:/${EFSS2}-init.sh"                         \
  -v "${ENV_ROOT}/docker/scripts/entrypoint.sh:/entrypoint.sh"                \
  -v "${ENV_ROOT}/${EFSS2}/apps/sciencemesh:/var/www/html/apps/sciencemesh"   \
  "pondersource/dev-stock-${EFSS2}-sciencemesh"                               \
  >/dev/null 2>&1

# EFSS1
waitForPort maria1.docker 3306
waitForPort "${EFSS1}1.docker" 443

docker exec "${EFSS1}1.docker" bash -c "cp /tls/*.crt /usr/local/share/ca-certificates/" >/dev/null 2>&1
docker exec "${EFSS1}1.docker" bash -c "cp /tls-host/*.crt /usr/local/share/ca-certificates/" >/dev/null 2>&1
docker exec "${EFSS1}1.docker" update-ca-certificates >/dev/null 2>&1
docker exec "${EFSS1}1.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt" >/dev/null 2>&1

docker exec -u www-data "${EFSS1}1.docker" sh "/${EFSS1}-init.sh" >/dev/null 2>&1

# run db injections.
mysql1_cmd="docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss"
$mysql1_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'iopUrl', 'https://reva${EFSS1}1.docker/');" >/dev/null 2>&1
$mysql1_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'revaSharedSecret', 'shared-secret-1');" >/dev/null 2>&1
$mysql1_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'meshDirectoryUrl', 'https://meshdir.docker/meshdir');" >/dev/null 2>&1
$mysql1_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'inviteManagerApikey', 'invite-manager-endpoint');" >/dev/null 2>&1

# EFSS2
waitForPort maria2.docker 3306
waitForPort "${EFSS2}2.docker" 443

docker exec "${EFSS2}2.docker" bash -c "cp /tls/*.crt /usr/local/share/ca-certificates/" >/dev/null 2>&1
docker exec "${EFSS2}2.docker" bash -c "cp /tls-host/*.crt /usr/local/share/ca-certificates/" >/dev/null 2>&1
docker exec "${EFSS2}2.docker" update-ca-certificates >/dev/null 2>&1
docker exec "${EFSS2}2.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt" >/dev/null 2>&1

docker exec -u www-data "${EFSS2}2.docker" sh "/${EFSS2}-init.sh" >/dev/null 2>&1

mysql2_cmd="docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss" 
$mysql2_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'iopUrl', 'https://reva${EFSS2}2.docker/');" >/dev/null 2>&1
$mysql2_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'revaSharedSecret', 'shared-secret-1');" >/dev/null 2>&1
$mysql2_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'meshDirectoryUrl', 'https://meshdir.docker/meshdir');" >/dev/null 2>&1
$mysql2_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'inviteManagerApikey', 'invite-manager-endpoint');" >/dev/null 2>&1

# Reva Setup.

# make sure scripts are executable.
chmod +x "${ENV_ROOT}/docker/scripts/reva-run.sh"
chmod +x "${ENV_ROOT}/docker/scripts/reva-kill.sh"
chmod +x "${ENV_ROOT}/docker/scripts/reva-entrypoint.sh"

docker run --detach --network=testnet                                         \
  --name="reva${EFSS1}1.docker"                                               \
  -e HOST="reva${EFSS1}1"                                                     \
  -v "${ENV_ROOT}/reva:/reva"                                                 \
  -v "${ENV_ROOT}/docker/revad:/etc/revad"                                    \
  -v "${ENV_ROOT}/docker/tls:/etc/revad/tls"                                  \
  -v "${ENV_ROOT}/ci/sciencemesh.toml:/etc/revad/sciencemesh.toml"            \
  -v "${ENV_ROOT}/docker/scripts/reva-run.sh:/usr/bin/reva-run.sh"            \
  -v "${ENV_ROOT}/docker/scripts/reva-kill.sh:/usr/bin/reva-kill.sh"          \
  -v "${ENV_ROOT}/docker/scripts/reva-entrypoint.sh:/entrypoint.sh"           \
  pondersource/dev-stock-revad                                                \
  >/dev/null 2>&1

docker run --detach --network=testnet                                         \
  --name="reva${EFSS2}2.docker"                                               \
  -e HOST="reva${EFSS2}2"                                                     \
  -v "${ENV_ROOT}/reva:/reva"                                                 \
  -v "${ENV_ROOT}/docker/revad:/etc/revad"                                    \
  -v "${ENV_ROOT}/docker/tls:/etc/revad/tls"                                  \
  -v "${ENV_ROOT}/ci/sciencemesh.toml:/etc/revad/sciencemesh.toml"            \
  -v "${ENV_ROOT}/docker/scripts/reva-run.sh:/usr/bin/reva-run.sh"            \
  -v "${ENV_ROOT}/docker/scripts/reva-kill.sh:/usr/bin/reva-kill.sh"          \
  -v "${ENV_ROOT}/docker/scripts/reva-entrypoint.sh:/entrypoint.sh"           \
  pondersource/dev-stock-revad                                                \
  >/dev/null 2>&1

# Cypress Setup.
docker run --network=testnet                                                  \
  --name="cypress.docker"                                                     \
  -v "${ENV_ROOT}/cypress/ocm-tests:/ocm"                                     \
  -w /ocm                                                                     \
  cypress/included:13.3.0 cypress run --browser "${TEST_PLATFORM}"
