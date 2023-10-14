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

function waitForCollabora {
  x=$(docker logs collabora.docker | grep -c "Ready")
  until [ "${x}" -ne 0 ]
  do
    echo Waiting for Collabora to be ready, this usually takes about 10 seconds ... "${x}"
    sleep 1
    x=$(docker logs collabora.docker | grep -c "Ready")
  done
  echo "Collabora is ready"
}

# create temp directory if it doesn't exist.
[ ! -d "${ENV_ROOT}/temp" ] && mkdir --parents "${ENV_ROOT}/temp"

# copy init files.
cp --force ./docker/scripts/init-owncloud-sciencemesh.sh  ./temp/owncloud.sh
cp --force ./docker/scripts/init-nextcloud-sciencemesh.sh ./temp/nextcloud.sh

docker run --detach --name=meshdir.docker   --network=testnet -v "${ENV_ROOT}/docker/scripts/stub.js:/ocm-stub/stub.js" pondersource/dev-stock-ocmstub
docker run --detach --name=firefox          --network=testnet -p 5800:5800  --shm-size 2g jlesage/firefox:latest
docker run --detach --name=firefox-legacy   --network=testnet -p 5900:5800  --shm-size 2g jlesage/firefox:v1.18.0
docker run --detach --name=collabora.docker --network=testnet -p 9980:9980 -t -e "extra_params=--o:ssl.enable=false" collabora/code:latest 
docker run --detach --name=wopi.docker      --network=testnet -p 8880:8880 -t cs3org/wopiserver:latest

#docker run --detach --name=rclone.docker    --network=testnet  rclone/rclone rcd -vv --rc-user=rcloneuser --rc-pass=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek --rc-addr=0.0.0.0:5572 --server-side-across-configs=true --log-file=/dev/stdout

# EFSS1
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
  -v "${ENV_ROOT}/docker/tls:/tls-host"                                       \
  -v "${ENV_ROOT}/temp/${EFSS1}.sh:/${EFSS1}-init.sh"                         \
  -v "${ENV_ROOT}/docker/scripts/entrypoint.sh:/entrypoint.sh"                \
  -v "${ENV_ROOT}/${EFSS1}/apps/sciencemesh:/var/www/html/apps/sciencemesh"   \
  "pondersource/dev-stock-${EFSS1}-sciencemesh"

# EFSS2
docker run --detach --network=testnet                                         \
  --name=maria2.docker                                                        \
  -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek           \
  mariadb                                                                     \
  --transaction-isolation=READ-COMMITTED                                      \
  --binlog-format=ROW                                                         \
  --innodb-file-per-table=1                                                   \
  --skip-innodb-read-only-compressed

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
  "pondersource/dev-stock-${EFSS2}-sciencemesh"

# EFSS1
waitForPort maria1.docker 3306
waitForPort "${EFSS1}1.docker" 443

docker exec "${EFSS1}1.docker" bash -c "cp /tls/*.crt /usr/local/share/ca-certificates/"
docker exec "${EFSS1}1.docker" bash -c "cp /tls-host/*.crt /usr/local/share/ca-certificates/"
docker exec "${EFSS1}1.docker" update-ca-certificates
docker exec "${EFSS1}1.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt"

docker exec -u www-data "${EFSS1}1.docker" sh "/${EFSS1}-init.sh"

# run db injections.
mysql1_cmd="docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss"

$mysql1_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'iopUrl', 'https://reva${EFSS1}1.docker/');"

$mysql1_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'revaSharedSecret', 'shared-secret-1');"

$mysql1_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'meshDirectoryUrl', 'https://meshdir.docker/meshdir');"

$mysql1_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'inviteManagerApikey', 'invite-manager-endpoint');"

# EFSS2
waitForPort maria2.docker 3306
waitForPort "${EFSS2}2.docker" 443

docker exec "${EFSS2}2.docker" bash -c "cp /tls/*.crt /usr/local/share/ca-certificates/"
docker exec "${EFSS2}2.docker" bash -c "cp /tls-host/*.crt /usr/local/share/ca-certificates/"
docker exec "${EFSS2}2.docker" update-ca-certificates
docker exec "${EFSS2}2.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt"

docker exec -u www-data "${EFSS2}2.docker" sh "/${EFSS2}-init.sh"

mysql2_cmd="docker exec maria2.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss"

$mysql2_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'iopUrl', 'https://reva${EFSS2}2.docker/');"

$mysql2_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'revaSharedSecret', 'shared-secret-1');"

$mysql2_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'meshDirectoryUrl', 'https://meshdir.docker/meshdir');"

$mysql2_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'inviteManagerApikey', 'invite-manager-endpoint');"

# Reva Setup.

# make sure scripts are executable.
chmod +x "${ENV_ROOT}/docker/scripts/reva-run.sh"
chmod +x "${ENV_ROOT}/docker/scripts/reva-kill.sh"
chmod +x "${ENV_ROOT}/docker/scripts/reva-entrypoint.sh"

waitForCollabora
docker run --detach --network=testnet                                         \
  --name="reva${EFSS1}1.docker"                                               \
  -e HOST="reva${EFSS1}1"                                                     \
  -p 8080:80                                                                  \
  -v "${ENV_ROOT}/reva:/reva"                                                 \
  -v "${ENV_ROOT}/docker/revad:/etc/revad"                                    \
  -v "${ENV_ROOT}/docker/tls:/etc/revad/tls"                                  \
  -v "${ENV_ROOT}/docker/scripts/reva-run.sh:/usr/bin/reva-run.sh"            \
  -v "${ENV_ROOT}/docker/scripts/reva-kill.sh:/usr/bin/reva-kill.sh"          \
  -v "${ENV_ROOT}/docker/scripts/reva-entrypoint.sh:/entrypoint.sh"           \
  pondersource/dev-stock-revad

docker run --detach --network=testnet                                         \
  --name="reva${EFSS2}2.docker"                                               \
  -e HOST="reva${EFSS2}2"                                                     \
  -p 8180:80                                                                  \
  -v "${ENV_ROOT}/reva:/reva"                                                 \
  -v "${ENV_ROOT}/docker/revad:/etc/revad"                                    \
  -v "${ENV_ROOT}/docker/tls:/etc/revad/tls"                                  \
  -v "${ENV_ROOT}/docker/scripts/reva-run.sh:/usr/bin/reva-run.sh"            \
  -v "${ENV_ROOT}/docker/scripts/reva-kill.sh:/usr/bin/reva-kill.sh"          \
  -v "${ENV_ROOT}/docker/scripts/reva-entrypoint.sh:/entrypoint.sh"           \
  pondersource/dev-stock-revad

# instructions.
echo "Now browse to http://localhost:5800 and inside there to https://${EFSS1}1.docker"
echo "Log in as einstein / relativity"
echo "Go to the ScienceMesh app and generate a token"
echo "Click it to go to the meshdir server, and choose ${EFSS2}2 there."
echo "Log in on https://${EFSS2}2.docker as marie / radioactivity"
