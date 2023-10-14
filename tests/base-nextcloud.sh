#!/usr/bin/env bash

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

# create temp dirctory if it doesn't exist.
[ ! -d "${ENV_ROOT}/temp" ] && mkdir -p "${ENV_ROOT}/temp"

# copy init files.
cp --force "${ENV_ROOT}/docker/scripts/init-nextcloud.sh" "${ENV_ROOT}/temp/nc-base.sh"

# echo "starting firefox tester"
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

echo "starting nc1.docker"
docker run --detach --network=testnet                                                               \
  --name=nc1.docker                                                                                 \
  --publish 8080:80                                                                                 \
  --add-host "host.docker.internal:host-gateway"                                                    \
  -e HOST="nc1"                                                                                     \
  -e DBHOST="maria1.docker"                                                                         \
  -e USER="einstein"                                                                                \
  -e PASS="relativity"                                                                              \
  -v "${ENV_ROOT}/temp/nc-base.sh:/init.sh"                                                        \
  pondersource/dev-stock-nextcloud

echo "starting maria2.docker"
docker run --detach --network=testnet                                                               \
  --name=maria2.docker                                                                              \
  -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek                                 \
  mariadb                                                                                           \
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
  -v "${ENV_ROOT}/temp/nc-base.sh:/init.sh"                                                        \
  pondersource/dev-stock-nextcloud

waitForPort maria1.docker 3306
waitForPort nc1.docker 443

docker exec "nc1.docker" bash -c "cp /tls/*.crt /usr/local/share/ca-certificates/"
docker exec "nc1.docker" bash -c "cp /tls-host/*.crt /usr/local/share/ca-certificates/"
docker exec "nc1.docker" update-ca-certificates
docker exec "nc1.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt"

echo "executing init.sh on nc1.docker"
docker exec -u www-data nc1.docker bash /init.sh

waitForPort maria2.docker 3306
waitForPort nc2.docker 443

docker exec "nc2.docker" bash -c "cp /tls/*.crt /usr/local/share/ca-certificates/"
docker exec "nc2.docker" bash -c "cp /tls-host/*.crt /usr/local/share/ca-certificates/"
docker exec "nc2.docker" update-ca-certificates
docker exec "nc2.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt"

echo "executing init.sh on nc2.docker"
docker exec -u www-data nc2.docker bash /init.sh
