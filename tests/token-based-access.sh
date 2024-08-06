#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

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
cp -f "${ENV_ROOT}/docker/scripts/init/owncloud-token-based-access.sh" "${ENV_ROOT}/temp/oc-token-based-access.sh"

docker run --detach --name=firefox          --network=testnet -p 5800:5800  --shm-size 2g jlesage/firefox:latest
docker run --detach --name=firefox-legacy   --network=testnet -p 5900:5800  --shm-size 2g jlesage/firefox:v1.18.0

# echo "starting keycloak.docker service"
# docker run --detach --network=testnet                                                               \
#   --name keycloak.docker                                                                            \
#   -e KEYCLOAK_ADMIN=admin                                                                           \
#   -e KEYCLOAK_ADMIN_PASSWORD=admin                                                                  \
#   -v "${ENV_ROOT}/docker/scripts/init/keycloak.sh:/init.sh"                                        \
#   -v "${ENV_ROOT}/docker/configs/keycloak.json:/opt/keycloak_import/keycloak.json"                 \
#   quay.io/keycloak/keycloak:latest                                                                  \
#   start-dev                                                                                         \
#   --http-port=80

# echo "importing realms and users into keycloak"
# docker exec keycloak.docker bash /init.sh

# sleep 2

# echo "restart keycloak"
# docker restart keycloak.docker

# sleep 2

echo "starting redis1.docker service"
docker run --detach --network=testnet                                                               \
  --name redis1.docker                                                                              \
  redis

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
  -e REDIS_HOST="redis1.docker"                                                                     \
  -v "${ENV_ROOT}/temp/oc-token-based-access.sh:/init.sh"                                          \
  -v "${ENV_ROOT}/surf-token-based-access:/var/www/html/apps/token-based-access"                   \
  -v "${ENV_ROOT}/open-id-connect:/var/www/html/apps/openidconnect"                                \
  pondersource/dev-stock-owncloud-token-based-access

echo "starting redis2.docker service"
docker run --detach --network=testnet                                                               \
  --name redis2.docker                                                                              \
  redis

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
  -e REDIS_HOST="redis2.docker"                                                                     \
  -v "${ENV_ROOT}/temp/oc-token-based-access.sh:/init.sh"                                          \
  -v "${ENV_ROOT}/surf-token-based-access:/var/www/html/apps/token-based-access"                   \
  -v "${ENV_ROOT}/open-id-connect:/var/www/html/apps/openidconnect"                                \
  pondersource/dev-stock-owncloud-token-based-access

waitForPort maria1.docker 3306
waitForPort oc1.docker 443

docker exec "oc1.docker" bash -c "cp /tls/*.crt /usr/local/share/ca-certificates/"
docker exec "oc1.docker" bash -c "cp /tls-host/*.crt /usr/local/share/ca-certificates/"
docker exec "oc1.docker" update-ca-certificates
docker exec "oc1.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt"

echo "executing init.sh on oc1.docker"
docker exec -u www-data oc1.docker bash /init.sh

waitForPort maria2.docker 3306
waitForPort oc2.docker 443

docker exec "oc2.docker" bash -c "cp /tls/*.crt /usr/local/share/ca-certificates/"
docker exec "oc2.docker" bash -c "cp /tls-host/*.crt /usr/local/share/ca-certificates/"
docker exec "oc2.docker" update-ca-certificates
docker exec "oc2.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt"

echo "executing init.sh on oc2.docker"
docker exec -u www-data oc2.docker bash /init.sh
