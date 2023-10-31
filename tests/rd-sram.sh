#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

export EFSS1=owncloud
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
  echo waitForPort ${1} ${2}
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

# create temp directory if it doesn't exist.
[ ! -d "${ENV_ROOT}/temp" ] && mkdir -p "${ENV_ROOT}/temp"

# copy init files.
cp --force "${ENV_ROOT}/docker/scripts/init-owncloud-rd-sram.sh" "${ENV_ROOT}/temp/oc-rd-sram.sh"

docker run --detach --name=firefox          --network=testnet -p 5800:5800  --shm-size 2g jlesage/firefox:latest
docker run --detach --name=firefox-legacy   --network=testnet -p 5900:5800  --shm-size 2g jlesage/firefox:v1.18.0

echo "starting maria1.docker"
docker run --detach --network=testnet                                                               \
  --name=maria1.docker                                                                              \
  -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek                                 \
  mariadb                                                                                           \
  --transaction-isolation=READ-COMMITTED                                                            \
  --binlog-format=ROW                                                                               \
  --innodb-file-per-table=1                                                                         \
  --skip-innodb-read-only-compressed

echo "starting ${EFSS1}1.docker"
docker run --detach --network=testnet                                                               \
  --name="${EFSS1}1.docker"                                                                         \
  --publish 8080:80                                                                                 \
  --add-host "host.docker.internal:host-gateway"                                                    \
  -e HOST="${EFSS1}1"                                                                               \
  -e DBHOST="maria1.docker"                                                                         \
  -e USER="einstein"                                                                                \
  -e PASS="relativity"                                                                              \
  -v "${ENV_ROOT}/docker/tls:/tls-host"                                                             \
  -v "${ENV_ROOT}/temp/oc-rd-sram.sh:/init.sh"                                                      \
  -v "${ENV_ROOT}/docker/scripts/entrypoint.sh:/entrypoint.sh"                                      \
  -v "${ENV_ROOT}/docker/rd-sram/curls:/curls"                                                      \
  -v "${ENV_ROOT}/${EFSS1}/apps/sciencemesh:/var/www/html/apps/sciencemesh"                         \
  -v "${ENV_ROOT}/${EFSS1}/apps/customgroups:/var/www/html/apps/customgroups"                       \
  -v "${ENV_ROOT}/${EFSS1}/apps/opencloudmesh:/var/www/html/apps/opencloudmesh"                     \
  -v "${ENV_ROOT}/${EFSS1}/apps/federatedgroups:/var/www/html/apps/federatedgroups"                 \
  pondersource/dev-stock-owncloud-rd-sram

echo "starting maria2.docker"
docker run --detach --network=testnet                                                               \
  --name=maria2.docker                                                                              \
  -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek                                 \
  mariadb                                                                                           \
  --transaction-isolation=READ-COMMITTED                                                            \
  --binlog-format=ROW                                                                               \
  --innodb-file-per-table=1                                                                         \
  --skip-innodb-read-only-compressed

echo "starting ${EFSS2}2.docker"
docker run --detach --network=testnet                                                               \
  --name="${EFSS2}2.docker"                                                                         \
  --publish 9080:80                                                                                 \
  --add-host "host.docker.internal:host-gateway"                                                    \
  -e HOST="${EFSS2}2"                                                                               \
  -e DBHOST="maria2.docker"                                                                         \
  -e USER="marie"                                                                                   \
  -e PASS="radioactivity"                                                                           \
  -v "${ENV_ROOT}/docker/tls:/tls-host"                                                             \
  -v "${ENV_ROOT}/temp/oc-rd-sram.sh:/init.sh"                                                      \
  -v "${ENV_ROOT}/docker/scripts/entrypoint.sh:/entrypoint.sh"                                      \
  -v "${ENV_ROOT}/docker/rd-sram/curls:/curls"                                                      \
  -v "${ENV_ROOT}/${EFSS1}/apps/sciencemesh:/var/www/html/apps/sciencemesh"                         \
  -v "${ENV_ROOT}/${EFSS1}/apps/customgroups:/var/www/html/apps/customgroups"                       \
  -v "${ENV_ROOT}/${EFSS1}/apps/opencloudmesh:/var/www/html/apps/opencloudmesh"                     \
  -v "${ENV_ROOT}/${EFSS1}/apps/federatedgroups:/var/www/html/apps/federatedgroups"                 \
  pondersource/dev-stock-owncloud-rd-sram

waitForPort maria1.docker 3306
waitForPort ${EFSS1}1.docker 443

docker exec "${EFSS1}1.docker" bash -c "cp /tls/*.crt /usr/local/share/ca-certificates/"
docker exec "${EFSS1}1.docker" bash -c "cp /tls-host/*.crt /usr/local/share/ca-certificates/"
docker exec "${EFSS1}1.docker" update-ca-certificates
docker exec "${EFSS1}1.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt"

echo "executing init.sh on ${EFSS1}1.docker"
docker exec -u www-data ${EFSS1}1.docker bash /init.sh

waitForPort maria2.docker 3306
waitForPort ${EFSS2}2.docker 443

docker exec "${EFSS2}2.docker" bash -c "cp /tls/*.crt /usr/local/share/ca-certificates/"
docker exec "${EFSS2}2.docker" bash -c "cp /tls-host/*.crt /usr/local/share/ca-certificates/"
docker exec "${EFSS2}2.docker" update-ca-certificates
docker exec "${EFSS2}2.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt"

echo "executing init.sh on ${EFSS2}2.docker"
docker exec -u www-data ${EFSS2}2.docker bash /init.sh

echo "Setting up SCIM control for Federated Groups"
mysql1_cmd="docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss"
mysql2_cmd="docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss"

$mysql1_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) VALUES ('federatedgroups', 'scim_token', 'something-super-secret');"
$mysql2_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) VALUES ('federatedgroups', 'scim_token', 'something-super-secret');"

echo "Creating federated group 'TestGroup (uniharderwijk_surfdrive_test) (SRAM CO)' on ${EFSS1}1"
docker exec -it ${EFSS1}1.docker sh /curls/createGroup.sh ${EFSS1}1.docker

echo "Creating federated group 'TestGroup (uniharderwijk_surfdrive_test) (SRAM CO)' on ${EFSS2}"
docker exec -it ${EFSS2}2.docker sh /curls/createGroup.sh ${EFSS2}2.docker

docker exec -it ${EFSS1}1.docker sh /curls/excludeMarie.sh ${EFSS1}1.docker
docker exec -it ${EFSS2}2.docker sh /curls/excludeMarie.sh ${EFSS2}2.docker

echo ""
echo ""
echo "RD-SRAM app instructions:"
echo "share something from einstein@${EFSS1}1.docker to Test Group, then run:"
echo "$ docker exec -it ${EFSS2}2.docker sh /curls/includeMarie.sh ${EFSS2}2.docker"
echo "$ docker exec -it ${EFSS1}1.docker sh /curls/includeMarie.sh ${EFSS1}1.docker"
echo "then log in to ${EFSS2}2.docker as marie, you should not have received the share"
echo "refresh the ${EFSS2}2.docker page, the share from einstein to Test Group should now also arrive to Marie"
