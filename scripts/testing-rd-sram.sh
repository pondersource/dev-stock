#!/usr/bin/env bash
set -e

REPO_ROOT=$(pwd)
export REPO_ROOT=$REPO_ROOT
[ ! -d "rd-sram" ] && echo Please run ./scripts/init-rd-sram.sh first! && exit
[ ! -d "ocm" ] && echo Please run ./scripts/init-rd-sram.sh first! && exit

function waitForPort () {
  echo waitForPort $1 $2
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
[ ! -d "${REPO_ROOT}/temp" ] && mkdir -p "${REPO_ROOT}/temp"

# copy init files.
cp -rf ./docker/rd-sram/curls ./temp/curls
cp -f "${REPO_ROOT}/docker/scripts/init-owncloud-rd-sram.sh" "${REPO_ROOT}/temp/oc-rd-sram.sh"

echo "starting firefox tester"
docker run --detach --name=firefox        --network=testnet -p 5800:5800 --shm-size 2g jlesage/firefox:latest
docker run --detach --name=firefox-legacy --network=testnet -p 5900:5800 --shm-size 2g jlesage/firefox:v1.18.0

echo "starting maria1.docker"
docker run --detach --network=testnet                                                               \
  --name=maria1.docker                                                                              \
  -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek                                 \
  mariadb                                                                                           \
  --transaction-isolation=READ-COMMITTED                                                            \
  --binlog-format=ROW                                                                               \
  --innodb-file-per-table=1                                                                         \
  --skip-innodb-read-only-compressed

echo "starting oc1.docker"
docker run --detach --network=testnet                                                               \
  --name=oc1.docker                                                                                 \
  --publish 8080:80                                                                                 \
  --add-host "host.docker.internal:host-gateway"                                                    \
  -e HOST="oc1"                                                                                     \
  -e DBHOST="maria1.docker"                                                                         \
  -e USER="einstein"                                                                                \
  -e PASS="relativity"                                                                              \
  -v "${REPO_ROOT}/temp/oc-rd-sram.sh:/init.sh"                                                     \
  -v "${REPO_ROOT}/rd-sram:/var/www/html/apps/rd-sram-integration"                                  \
  -v "${REPO_ROOT}/ocm:/var/www/html/apps/oc-opencloudmesh"                                         \
  -v "${REPO_ROOT}/docker/rd-sram/curls:/curls"                                                     \
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

echo "starting oc2.docker"
docker run --detach --network=testnet                                                               \
  --name=oc2.docker                                                                                 \
  --publish 9080:80                                                                                 \
  --add-host "host.docker.internal:host-gateway"                                                    \
  -e HOST="oc2"                                                                                     \
  -e DBHOST="maria2.docker"                                                                         \
  -e USER="marie"                                                                                   \
  -e PASS="radioactivity"                                                                           \
  -v "${REPO_ROOT}/temp/oc-rd-sram.sh:/init.sh"                                                     \
  -v "${REPO_ROOT}/rd-sram:/var/www/html/apps/rd-sram-integration"                                  \
  -v "${REPO_ROOT}/ocm:/var/www/html/apps/oc-opencloudmesh"                                         \
  -v "${REPO_ROOT}/docker/rd-sram/curls:/curls"                                                     \
  pondersource/dev-stock-owncloud-rd-sram

waitForPort maria1.docker 3306
waitForPort oc1.docker 443

echo "executing init.sh on oc1.docker"
docker exec -u www-data oc1.docker bash /init.sh

waitForPort maria2.docker 3306
waitForPort oc2.docker 443

echo "executing init.sh on oc2.docker"
docker exec -u www-data oc2.docker bash /init.sh

echo "Setting up SCIM control for Federated Groups"
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_appconfig (appid, configkey, configvalue) VALUES ('federatedgroups', 'scim_token', 'something-super-secret');"
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_appconfig (appid, configkey, configvalue) VALUES ('federatedgroups', 'scim_token', 'something-super-secret');"

echo "Creating federated group 'TestGroup (uniharderwijk_surfdrive_test) (SRAM CO)' on oc1"
docker exec -it oc1.docker sh /curls/createGroup.sh oc1.docker

echo "Creating federated group 'TestGroup (uniharderwijk_surfdrive_test) (SRAM CO)' on oc2"
docker exec -it oc2.docker sh /curls/createGroup.sh oc2.docker

docker exec -it oc1.docker sh /curls/excludeMarie.sh oc1.docker
docker exec -it oc2.docker sh /curls/excludeMarie.sh oc2.docker

echo "share something from einstein@oc1.docker to Test Group, then run:"
echo "$ docker exec -it oc2.docker sh /curls/includeMarie.sh oc2.docker"
echo "$ docker exec -it oc1.docker sh /curls/includeMarie.sh oc1.docker"
echo "then log in to oc2.docker as marie, you should not have received the share"
echo "refresh the oc2.docker page, the share from einstein to Test Group should now also arrive to Marie"
