#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

REPO_ROOT=$(pwd)
export REPO_ROOT=$REPO_ROOT
[ ! -d "ocm" ] && echo Please run ./scripts/init/opencloudmesh.sh first! && exit

function waitForPort {
  x=$(docker exec -it "${1}" ss -tulpn | grep -c "${2}")
  until [ "${x}" -ne 0 ]
  do
    echo Waiting for "${1}" to open port "${2}", this usually takes about 10 seconds ... "${x}"
    sleep 1
    x=$(docker exec -it "${1}" ss -tulpn | grep -c "${2}")
  done
  echo "${1}" port "${2}" is open
}

# create temp dirctory if it doesn't exist.
[ ! -d "${REPO_ROOT}/temp" ] && mkdir -p "${REPO_ROOT}/temp"

# copy init files.
cp -f "${REPO_ROOT}/docker/scripts/init/nextcloud.sh" "${REPO_ROOT}/temp/nc-base.sh"
cp -f "${REPO_ROOT}/docker/scripts/init/owncloud-opencloudmesh.sh"  "${REPO_ROOT}/temp/oc-opencloudmesh.sh"

echo "starting firefox tester"
docker run --detach --name=firefox        --network=testnet -p 5800:5800 --shm-size 2g jlesage/firefox:latest
docker run --detach --name=firefox-legacy --network=testnet -p 5900:5800 --shm-size 2g jlesage/firefox:v1.18.0

echo "starting maria1.docker"
docker run --detach --network=testnet                                                               \
  --name=maria1.docker                                                                              \
  -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek                                 \
  mariadb:11.4.2                                                                                    \
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
  -v "${REPO_ROOT}/temp/oc-opencloudmesh.sh:/init.sh"                                               \
  -v "${REPO_ROOT}/ocm:/var/www/html/apps/oc-opencloudmesh"                                         \
  pondersource/owncloud-opencloudmesh

echo "starting maria2.docker"
docker run --detach --network=testnet                                                               \
  --name=maria2.docker                                                                              \
  -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek                                 \
  mariadb:11.4.2                                                                                    \
  --transaction-isolation=READ-COMMITTED                                                            \
  --binlog-format=ROW                                                                               \
  --innodb-file-per-table=1                                                                         \
  --skip-innodb-read-only-compressed

echo "starting nc2.docker"
docker run --detach --network=testnet                                                               \
  --name=nc2.docker                                                                                 \
  --publish 9080:80                                                                                 \
  --add-host "host.docker.internal:host-gateway"                                                    \
  -e HOST="nc2"                                                                                     \
  -e DBHOST="maria2.docker"                                                                         \
  -e USER="marie"                                                                                   \
  -e PASS="radioactivity"                                                                           \
  -v "${REPO_ROOT}/temp/nc-base.sh:/init.sh"                                                        \
  pondersource/nextcloud

waitForPort maria1.docker 3306
waitForPort oc1.docker 443

echo "executing init.sh on oc1.docker"
docker exec -u www-data oc1.docker bash /init.sh

waitForPort maria2.docker 3306
waitForPort nc2.docker 443

echo "executing init.sh on nc2.docker"
docker exec -u www-data nc2.docker bash /init.sh
