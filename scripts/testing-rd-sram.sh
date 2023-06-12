#!/usr/bin/env bash

REPO_ROOT=$(pwd)
export REPO_ROOT=$REPO_ROOT
[ ! -d "rd-sram" ] && echo Please run ./scripts/init-rd-sram.sh first! && exit
[ ! -d "owncloud" ] && echo Please run ./scripts/init-rd-sram.sh first! && exit
[ ! -d "ocm" ] && echo Please run ./scripts/init-rd-sram.sh first! && exit

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

# copy init files.
cp --force ./docker/scripts/init-owncloud-rd-sram.sh  ./temp/oc-rd-sram.sh

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
  -v "${REPO_ROOT}/owncloud/apps/files_sharing:/var/www/html/apps/files_sharing"                    \
  -v "${REPO_ROOT}/owncloud/apps/federatedfilesharing:/var/www/html/apps/federatedfilesharing"      \
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
  -v "${REPO_ROOT}/owncloud/apps/files_sharing:/var/www/html/apps/files_sharing"                    \
  -v "${REPO_ROOT}/owncloud/apps/federatedfilesharing:/var/www/html/apps/federatedfilesharing"      \
  pondersource/dev-stock-owncloud-rd-sram

waitForPort maria1.docker 3306
waitForPort oc1.docker 443

echo "executing init.sh on oc1.docker"
docker exec -u www-data oc1.docker sh /init.sh

waitForPort maria2.docker 3306
waitForPort oc2.docker 443

echo "executing init.sh on oc2.docker"
docker exec -u www-data oc2.docker sh /init.sh

# run db injections.
echo Creating regular group 'federalists' on oc1
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek owncloud -e "insert into oc_groups (gid) values ('federalists');"
echo Adding local user to regular group on oc1
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek owncloud -e "insert into oc_group_user (gid, uid) values ('federalists', 'einstein');"
echo Adding foreign user to regular group on oc1
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek owncloud -e "insert into oc_group_user (gid, uid) values ('federalists', 'marie#oc2.docker');"

echo Creating regular group 'federalists' on oc2
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek owncloud -e "insert into oc_groups (gid) values ('federalists');"
echo Adding foreign user to regular group on oc2
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek owncloud -e "insert into oc_group_user (gid, uid) values ('federalists', 'einstein#oc1.docker');"
echo Adding local user to regular group on oc2
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek owncloud -e "insert into oc_group_user (gid, uid) values ('federalists', 'marie');"

echo Creating regular group 'helpdesk' on oc2
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek owncloud -e "insert into oc_groups (gid) values ('helpdesk');"
echo Adding foreign user to regular group on oc2
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek owncloud -e "insert into oc_group_user (gid, uid) values ('helpdesk', 'marie');"

echo Creating regular group 'federalists' on oc1
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_groups (gid) values ('federalists');"
echo Adding local user to regular group on oc1
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_group_user (gid, uid) values ('federalists', 'einstein');"
echo Adding foreign user to regular group on oc1
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_group_user (gid, uid) values ('federalists', 'marie#oc2.docker');"

echo Creating regular group 'federalists' on oc2
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_groups (gid) values ('federalists');"
echo Adding foreign user to regular group on oc2
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_group_user (gid, uid) values ('federalists', 'einstein#oc1.docker');"
echo Adding local user to regular group on oc2
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_group_user (gid, uid) values ('federalists', 'marie');"

echo Creating regular group 'helpdesk' on oc2
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_groups (gid) values ('helpdesk');"
echo Adding foreign user to regular group on oc2
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_group_user (gid, uid) values ('helpdesk', 'marie');"

echo Creating custom group 'custard with mustard' on oc1
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_custom_group (group_id, uri, display_name) values (1, 'Custard with Mustard', 'Custard with Mustard');"
echo Adding local user to custom group on oc1
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_custom_group_member (group_id, user_id, role) values (1, 'einstein', 1);"
echo Adding foreign user to custom group on oc1
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_custom_group_member (group_id, user_id, role) values (1, 'marie#oc2.docker', 1);"

echo Creating custom group 'custard with mustard' on oc2
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_custom_group (group_id, uri, display_name) values (1, 'Custard with Mustard', 'Custard with Mustard');"
echo Adding foreign user to custom group on oc2
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_custom_group_member (group_id, user_id, role) values (1, 'einstein#oc1.docker', 1);"
echo Adding local user to custom group on oc2
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_custom_group_member (group_id, user_id, role) values (1, 'marie', 1);"

echo Now browse to http://\<host\>:5800 to see a Firefox instance that sits inside the Docker testnet.
