#!/usr/bin/env bash

REPO_ROOT=$(pwd)
export REPO_ROOT=$REPO_ROOT

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

EFSS1=nc

# copy init files.
cp --force ./docker/scripts/init-nextcloud-solid.sh ./temp/init-nextcloud-solid.sh

docker run --detach --name=firefox -p 5800:5800 --network=testnet --shm-size 2g jlesage/firefox:latest


docker run --detach --network=testnet                                         \
  --name=maria1.docker                                                        \
  -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek           \
  mariadb                                                                     \
  --transaction-isolation=READ-COMMITTED                                      \
  --binlog-format=ROW                                                         \
  --innodb-file-per-table=1                                                   \
  --skip-innodb-read-only-compressed

docker run --detach --network=testnet                                         \
  --name="${EFSS1}1.docker"                                                   \
  --add-host "host.docker.internal:host-gateway"                              \
  -e HOST="${EFSS1}1"                                                         \
  -e DBHOST="maria1.docker"                                                   \
  -e USER="einstein"                                                          \
  -e PASS="relativity"                                                        \
  -v "${REPO_ROOT}/temp/init-nextcloud-solid.sh:/init.sh"                     \
  -v "${REPO_ROOT}/solid-nextcloud:/var/www/html/apps/solid-nextcloud"        \
  "pondersource/dev-stock-nextcloud-solid"

# EFSS1
waitForPort maria1.docker 3306
waitForPort "${EFSS1}1.docker" 443

docker exec -e DBHOST=maria1.docker -e USER=einstein -e PASS=relativity -u www-data "${EFSS1}1.docker" bash "/init.sh"

# instructions.
echo "Now browse to firefox and inside there to https://${EFSS1}1.docker"
echo "Log in as einstein / relativity"
