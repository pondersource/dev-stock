#!/usr/bin/env bash

REPO_ROOT=$(pwd)
export REPO_ROOT=$REPO_ROOT
[ ! -d "./scripts" ] && echo "Directory ./scripts DOES NOT exist inside $REPO_ROOT, are you running this from the repo root?" && exit 1
[ ! -d "./nc-sciencemesh" ] && echo "Directory ./nc-sciencemesh DOES NOT exist inside $REPO_ROOT, did you run ./scripts/init-sciencemesh.sh?" && exit 1
[ ! -d "./nc-sciencemesh/vendor" ] && echo "Directory ./nc-sciencemesh/vendor DOES NOT exist inside $REPO_ROOT. Try: rmdir ./nc-sciencemesh ; ./scripts/init-sciencemesh.sh" && exit 1
[ ! -d "./oc-sciencemesh" ] && echo "Directory ./oc-sciencemesh DOES NOT exist inside $REPO_ROOT, did you run ./scripts/init-sciencemesh.sh?" && exit 1
[ ! -d "./oc-sciencemesh/vendor" ] && echo "Directory ./oc-sciencemesh/vendor DOES NOT exist inside $REPO_ROOT. Try: rmdir ./oc-sciencemesh ; ./scripts/init-sciencemesh.sh" && exit 1

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

docker run --detach --network=testnet --name=meshdir.docker pondersource/dev-stock-ocmstub
docker run --detach --name=firefox -p 5800:5800 -v /tmp/shm:/config:rw --network=testnet --shm-size 2g jlesage/firefox:latest
# docker run --detach --network=testnet --name=rclone.docker rclone/rclone rcd -vv --rc-user=rcloneuser --rc-pass=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek --rc-addr=0.0.0.0:5572 --server-side-across-configs=true --log-file=/dev/stdout

docker run --detach --network=testnet --name="reva${EFSS1}1.docker" -e HOST="reva${EFSS1}1" pondersource/dev-stock-revad
docker run --detach --network=testnet --name=maria1.docker -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek mariadb --transaction-isolation=READ-COMMITTED --binlog-format=ROW --innodb-file-per-table=1 --skip-innodb-read-only-compressed
docker run --detach --network=testnet --name="${EFSS1}1.docker" --add-host "host.docker.internal:host-gateway" -e HOST="${EFSS1}1" -e DBHOST="maria1.docker" -e USER="einstein" -e PASS="relativity" -v "$REPO_ROOT/$EFSS1-sciencemesh:/var/www/html/apps/sciencemesh" "pondersource/dev-stock-${EFSS1}1-sciencemesh"

docker run --detach --network=testnet --name="reva${EFSS2}2.docker" -e HOST="reva${EFSS2}2" pondersource/dev-stock-revad
docker run --detach --network=testnet --name=maria2.docker -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek mariadb --transaction-isolation=READ-COMMITTED --binlog-format=ROW --innodb-file-per-table=1 --skip-innodb-read-only-compressed
docker run --detach --network=testnet --name="${EFSS2}2.docker" --add-host "host.docker.internal:host-gateway" -e HOST="${EFSS2}2" -e DBHOST="maria2.docker" -e USER="marie" -e PASS="radioactivity" -v "$REPO_ROOT/$EFSS2-sciencemesh:/var/www/html/apps/sciencemesh" "pondersource/dev-stock-${EFSS2}2-sciencemesh"

waitForPort maria1.docker 3306
waitForPort "${EFSS1}1.docker" 443
docker exec -e DBHOST=maria1.docker -e USER=einstein -e PASS=relativity  -u www-data "${EFSS1}1.docker" sh /init.sh
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'iopUrl', 'https://reva${EFSS1}1.docker/');"
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'revaSharedSecret', 'shared-secret-1');"
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'meshDirectoryUrl', 'https://meshdir.docker/meshdir');"

waitForPort maria2.docker 3306
waitForPort "${EFSS2}2.docker" 443
docker exec -e DBHOST=maria2.docker -e USER=marie -e PASS=radioactivity -u www-data "${EFSS2}2.docker" sh /init.sh
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'iopUrl', 'https://reva${EFSS2}2.docker/');"
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'revaSharedSecret', 'shared-secret-2');"
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'meshDirectoryUrl', 'https://meshdir.docker/meshdir');"

echo "Now browse to http://ocmhost:5800 and inside there to https://${EFSS1}1.docker"
echo "Log in as einstein / relativity"
echo "Go to the ScienceMesh app and generate a token"
echo "Click it to go to the meshdir server, and choose ${EFSS2}2 there."
echo "Log in on https://${EFSS2}2.docker as marie / radioactivity"
