#!/bin/bash
set -e


export REPO_ROOT=`pwd`
export EFSS1=nc
export EFSS2=nc

# before running this, build the sunet-sciencemesh image, using:
# cd ..
# git clone https://github.com/SUNET/nextcloud-custom
# cd nextcloud-custom
# git checkout b9097abdcf6757e34f19442b28de6e4d8d0637e8
# docker build -t sunet-sciencemesh-b9097abdcf6757e34f19442 .
# git checkout db6fbc2d56b44f406e3
# docker build -t sunet-sciencemesh-db6fbc2d56b44f406e3 .
# cd ../dev-stock
# ./scripts/clean.sh
# ./scripts/sunet-sciencemesh-testing.shc

export REPO_ROOT=`pwd`
[ ! -d "./scripts" ] && echo "Directory ./scripts DOES NOT exist inside $REPO_ROOT, are you running this from the repo root?" && exit 1

function waitForPort {
  x=$(docker exec -it $1 ss -tulpn | grep $2 | wc -l)
  until [ $x -ne 0 ]
  do
    echo Waiting for $1 to open port $2, this usually takes about 10 seconds ... $x
    sleep 1
    x=$(docker exec -it $1 ss -tulpn | grep $2 | wc -l)
  done
  echo $1 port $2 is open
}

docker run -d --network=testnet --name=reva${EFSS1}1.docker -e HOST=reva${EFSS1}1 pondersource/dev-stock-revad
docker run -d --network=testnet --name=maria1.docker -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek mariadb --transaction-isolation=READ-COMMITTED --binlog-format=ROW --innodb-file-per-table=1 --skip-innodb-read-only-compressed
docker run -d --network=testnet --name=${EFSS1}1.docker -v $REPO_ROOT/$EFSS1-sciencemesh:/var/www/html/apps/sciencemesh sunet-sciencemesh-db6fbc2d56b44f406e3 /usr/sbin/apache2ctl -DFOREGROUND

docker run -d --network=testnet --name=reva${EFSS2}2.docker -e HOST=reva${EFSS2}2 pondersource/dev-stock-revad
docker run -d --network=testnet --name=maria2.docker -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek mariadb --transaction-isolation=READ-COMMITTED --binlog-format=ROW --innodb-file-per-table=1 --skip-innodb-read-only-compressed
docker run -d --network=testnet --name=${EFSS2}2.docker -v $REPO_ROOT/$EFSS2-sciencemesh:/var/www/html/apps/sciencemesh sunet-sciencemesh-b9097abdcf6757e34f19442 /usr/sbin/apache2ctl -DFOREGROUND
docker run -d --network=testnet --name=meshdir.docker pondersource/dev-stock-ocmstub
docker run -d --network=testnet --name=rclone.docker rclone/rclone rcd -vv --rc-user=rcloneuser --rc-pass=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek --rc-addr=0.0.0.0:5572 --server-side-across-configs=true --log-file=/dev/stdout
docker run -d --name=firefox -p 5800:5800 -v /tmp/shm:/config:rw --network=testnet --shm-size 2g jlesage/firefox:v1.17.1

waitForPort maria1.docker 3306
# waitForPort ${EFSS1}1.docker 80
sleep 15
docker exec  -u www-data --workdir /var/www/html nc1.docker php console.php maintenance:install --admin-user einstein --admin-pass relativity --database "mysql" --database-name "efss" --database-user "root" --database-pass "eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek" --database-host "maria1.docker"
docker exec  -u www-data --workdir /var/www/html nc1.docker php console.php app:disable firstrunwizard
docker exec  -u www-data --workdir /var/www/html nc1.docker sed -i "8 i\      1 => 'nc1.docker'," /var/www/html/config/config.php
docker exec  -u www-data --workdir /var/www/html nc1.docker sed -i "9 i\      2 => 'nc2.docker'," /var/www/html/config/config.php
docker exec  -u www-data --workdir /var/www/html nc1.docker sed -i "3 i\  'allow_local_remote_servers' => true," config/config.php
docker exec  -u www-data --workdir /var/www/html nc1.docker php console.php app:enable sciencemesh

docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'iopUrl', 'https://reva${EFSS1}1.docker/');"
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'revaSharedSecret', 'shared-secret-1');"
docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'meshDirectoryUrl', 'https://meshdir.docker/meshdir');"

waitForPort maria2.docker 3306
# waitForPort ${EFSS2}2.docker 80
docker exec  -u www-data --workdir /var/www/html nc2.docker php console.php maintenance:install --admin-user maria --admin-pass radioactivity --database "mysql" --database-name "efss" --database-user "root" --database-pass "eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek" --database-host "maria2.docker"
docker exec  -u www-data --workdir /var/www/html nc2.docker php console.php app:disable firstrunwizard
docker exec  -u www-data --workdir /var/www/html nc2.docker sed -i "8 i\      1 => 'nc1.docker'," /var/www/html/config/config.php
docker exec  -u www-data --workdir /var/www/html nc2.docker sed -i "9 i\      2 => 'nc2.docker'," /var/www/html/config/config.php
docker exec  -u www-data --workdir /var/www/html nc2.docker sed -i "3 i\  'allow_local_remote_servers' => true," config/config.php
docker exec  -u www-data --workdir /var/www/html nc2.docker php console.php app:enable sciencemesh

docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'iopUrl', 'https://reva${EFSS2}2.docker/');"
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'revaSharedSecret', 'shared-secret-2');"
docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'meshDirectoryUrl', 'https://meshdir.docker/meshdir');"

echo Now browse to http://ocmhost:5800 and inside there to https://${EFSS1}1.docker
echo Log in as einstein / relativity
echo Go to the ScienceMesh app and generate a token
echo Click it to go to the meshdir server, and choose ${EFSS2}2 there.
echo Log in on https://${EFSS2}2.docker as marie / radioactivity
