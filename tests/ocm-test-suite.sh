#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

export EFSS1=nextcloud
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
sudo rm --force --recursive "${ENV_ROOT}/temp/.X11-unix"

docker run --detach --network=testnet                                         \
  --name=meshdir.docker                                                       \
  -v "${ENV_ROOT}/docker/scripts/stub.js:/ocm-stub/stub.js"                   \
  pondersource/dev-stock-ocmstub

docker run --detach --network=testnet                                         \
  --name=firefox                                                              \
  -p 5800:5800                                                                \
  -v "${ENV_ROOT}/docker/tls/cert9.db:/config/profile/cert9.db"               \
  --shm-size 2g                                                               \
  jlesage/firefox:latest

#docker run --detach --name=rclone.docker    --network=testnet                \
# rcd -vv --rc-addr=0.0.0.0:5572                                              \
# --rc-user=rcloneuser --rc-pass=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek     \
# --server-side-across-configs=true --log-file=/dev/stdout                    \
# rclone/rclone:latest

docker run --detach --network=testnet                                         \
  --name=collabora.docker                                                     \
  -p 9980:9980 -t                                                             \
  -e "extra_params=--o:ssl.enable=false"                                      \
  -v "${ENV_ROOT}/docker/collabora/coolwsd.xml:/etc/coolwsd/coolwsd.xml"      \
  -v "${ENV_ROOT}/tls:/tls"                                                   \
  collabora/code:latest 

#TODO the native container does not allow root shells, for now we disable SSL verification
#docker exec collabora.docker bash -c "cp /tls/*.crt /usr/local/share/ca-certificates/"
#docker exec collabora.docker update-ca-certificates

# VNC server.
docker run --detach --network=testnet                                         \
  --name=vnc-server                                                           \
  -p 5700:8080                                                                \
  -e RUN_XTERM=no                                                             \
  -e DISPLAY_WIDTH=1080                                                       \
  -e DISPLAY_HEIGHT=720                                                       \
  -v "${ENV_ROOT}/temp/.X11-unix:/tmp/.X11-unix"                              \
  theasp/novnc:latest


# this is used only by CERNBox so far, and might be used by OCIS in the future (though OCIS embeds an IDP)
docker run --detach --network=testnet                                         \
  --name=idp.docker                                                           \
  -e KEYCLOAK_ADMIN="admin" -e KEYCLOAK_ADMIN_PASSWORD="admin"                \
  -e KC_HOSTNAME="idp.docker"                                                 \
  -e KC_HTTPS_CERTIFICATE_FILE="/tls/idp.crt"                                 \
  -e KC_HTTPS_CERTIFICATE_KEY_FILE="/tls/idp.key"                             \
  -e KC_HTTPS_PORT="8443"                                                     \
  -v "${ENV_ROOT}/docker/tls:/tls"                                            \
  -v "${ENV_ROOT}/docker/cernbox/keycloak:/opt/keycloak/data/import"          \
  -p 8443:8443                                                                \
  quay.io/keycloak/keycloak:21.1.1                                            \
  start-dev --import-realm

# EFSS1
if [ "${EFSS1}" != "cernbox" ]; then

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

  # setup
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

else

  # setup only
  sed < "${ENV_ROOT}/docker/cernbox/nginx/nginx.conf"                           \
    "s/your.revad.org/reva${EFSS1}1.docker/" |                                  \
    sed "s|your.cert.pem|/usr/local/share/ca-certificates/${EFSS1}1.crt|" |     \
    sed "s|your.key.pem|/usr/local/share/ca-certificates/${EFSS1}1.key|"        \
    > "${ENV_ROOT}/temp/cernbox-1-conf/nginx.conf"

  sed < "${ENV_ROOT}/docker/cernbox/web.json"                                   \
    "s/your.nginx.org/${EFSS1}1.docker/"                                        \
    > "${ENV_ROOT}/temp/cernbox-1-conf/config.json"

fi

# EFSS2
if [ "${EFSS2}" != "cernbox" ]; then

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

  # setup
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

else

  # setup only
  sed < "${ENV_ROOT}/docker/cernbox/nginx/nginx.conf"                           \
    "s/your.revad.org/reva${EFSS2}2.docker/" |                                  \
    sed "s|your.cert.pem|/usr/local/share/ca-certificates/${EFSS2}2.crt|" |     \
    sed "s|your.key.pem|/usr/local/share/ca-certificates/${EFSS2}2.key|"        \
    > "${ENV_ROOT}/temp/cernbox-2-conf/nginx.conf"

  sed < "${ENV_ROOT}/docker/cernbox/web.json"                                   \
    "s/your.nginx.org/${EFSS2}2.docker/"                                        \
    > "${ENV_ROOT}/temp/cernbox-2-conf/config.json"

fi

# collabora should be availabe before 
# we start Reva, or it will hang
waitForCollabora

# IOP: Reva setup

# make sure scripts are executable.
chmod +x "${ENV_ROOT}/docker/scripts/reva-run.sh"
chmod +x "${ENV_ROOT}/docker/scripts/reva-kill.sh"
chmod +x "${ENV_ROOT}/docker/scripts/reva-entrypoint.sh"

docker run --detach --network=testnet                                         \
  --name="reva${EFSS1}1.docker"                                               \
  -e HOST="reva${EFSS1}1"                                                     \
  -p 8080:80                                                                  \
  -v "${ENV_ROOT}/reva:/reva"                                                 \
  -v "${ENV_ROOT}/docker/revad:/configs/revad"                                \
  -v "${ENV_ROOT}/docker/cernbox:/configs/cernbox"                            \
  -v "${ENV_ROOT}/docker/tls:/etc/tls"                                        \
  -v "${ENV_ROOT}/docker/scripts/reva-run.sh:/usr/bin/reva-run.sh"            \
  -v "${ENV_ROOT}/docker/scripts/reva-kill.sh:/usr/bin/reva-kill.sh"          \
  -v "${ENV_ROOT}/docker/scripts/reva-entrypoint.sh:/entrypoint.sh"           \
  pondersource/dev-stock-revad

docker run --detach --network=testnet                                         \
  --name="reva${EFSS2}2.docker"                                               \
  -e HOST="reva${EFSS2}2"                                                     \
  -p 8180:80                                                                  \
  -v "${ENV_ROOT}/reva:/reva"                                                 \
  -v "${ENV_ROOT}/docker/revad:/configs/revad"                                \
  -v "${ENV_ROOT}/docker/cernbox:/configs/cernbox"                            \
  -v "${ENV_ROOT}/docker/tls:/etc/tls"                                        \
  -v "${ENV_ROOT}/docker/scripts/reva-run.sh:/usr/bin/reva-run.sh"            \
  -v "${ENV_ROOT}/docker/scripts/reva-kill.sh:/usr/bin/reva-kill.sh"          \
  -v "${ENV_ROOT}/docker/scripts/reva-entrypoint.sh:/entrypoint.sh"           \
  pondersource/dev-stock-revad

# IOP: wopi
sed < "${ENV_ROOT}/wopi-sciencemesh/docker/etc/wopiserver.cs3.conf"           \
  "s/your.wopi.org/wopi${EFSS1}1.docker/g" |                                  \
  sed "s/your.revad.org/reva${EFSS1}1.docker/g" |                             \
  sed "s|your.cert.pem|/usr/local/share/ca-certificates/wopi${EFSS1}1.crt|" | \
  sed "s|your.key.pem|/usr/local/share/ca-certificates/wopi${EFSS1}1.key|"    \
  > "${ENV_ROOT}/temp/wopi-1-conf/wopiserver.conf"

docker run --detach --network=testnet                                         \
  --name="wopi${EFSS1}1.docker"                                               \
  -e HOST="wopi${EFSS1}1"                                                     \
  -p 8880:8880                                                                \
  -v "${ENV_ROOT}/temp/wopi-1-conf:/etc/wopi"                                 \
  -v "${ENV_ROOT}/tls:/usr/local/share/ca-certificates"                       \
  cs3org/wopiserver:latest

docker exec "wopi${EFSS1}1.docker" update-ca-certificates >& /dev/null

sed < "${ENV_ROOT}/wopi-sciencemesh/docker/etc/wopiserver.cs3.conf"           \
  "s/your.wopi.org/wopi${EFSS2}2.docker/g" |                                  \
  sed "s/your.revad.org/reva${EFSS2}2.docker/g" |                             \
  sed "s|your.cert.pem|/usr/local/share/ca-certificates/wopi${EFSS2}2.crt|" | \
  sed "s|your.key.pem|/usr/local/share/ca-certificates/wopi${EFSS2}2.key|"    \
  > "${ENV_ROOT}/temp/wopi-2-conf/wopiserver.conf"

docker run --detach --network=testnet                                         \
  --name="wopi${EFSS2}2.docker"                                               \
  -e HOST="wopi${EFSS2}2"                                                     \
  -p 8980:8880                                                                \
  -v "${ENV_ROOT}/temp/wopi-2-conf:/etc/wopi"                                 \
  -v "${ENV_ROOT}/tls:/usr/local/share/ca-certificates"                       \
  cs3org/wopiserver:latest

docker exec "wopi${EFSS2}2.docker" update-ca-certificates >& /dev/null

# nginx for CERNBox, after reva
if [ "${EFSS1}" == "cernbox" ]; then

  docker run --detach --network=testnet                                         \
    --name="${EFSS1}1.docker"                                                   \
    -v "${ENV_ROOT}/temp/cernbox-1-conf:/etc/nginx"                             \
    -v "${ENV_ROOT}/temp/cernbox-1-conf/config.json:/var/www/web/config.json"   \
    -v "${ENV_ROOT}/tls:/usr/local/share/ca-certificates"                       \
    -v "${ENV_ROOT}/cernbox-web-sciencemesh/web:/var/www/web"                   \
    -v "${ENV_ROOT}/cernbox-web-sciencemesh/cernbox:/var/www/cernbox"           \
    nginx

  docker exec "${EFSS1}1.docker" update-ca-certificates >& /dev/null

fi

if [ "${EFSS2}" == "cernbox" ]; then

  docker run --detach --network=testnet                                         \
    --name="${EFSS2}2.docker"                                                   \
    -v "${ENV_ROOT}/temp/cernbox-2-conf:/etc/nginx"                             \
    -v "${ENV_ROOT}/temp/cernbox-2-conf/config.json:/var/www/web/config.json"   \
    -v "${ENV_ROOT}/tls:/usr/local/share/ca-certificates"                       \
    -v "${ENV_ROOT}/cernbox-web-sciencemesh/web:/var/www/web"                   \
    -v "${ENV_ROOT}/cernbox-web-sciencemesh/cernbox:/var/www/cernbox"           \
    nginx

  docker exec "${EFSS2}2.docker" update-ca-certificates >& /dev/null

fi

# Cypress Setup.
docker run --detach --network=testnet                                         \
  --name="cypress.docker"                                                     \
  -e DISPLAY=vnc-server:0.0                                                   \
  -v "${ENV_ROOT}/tests/e2e:/e2e"                                             \
  -v "${ENV_ROOT}/temp/.X11-unix:/tmp/.X11-unix"                              \
  -w /e2e                                                                     \
  --entrypoint cypress                                                        \
  cypress/included:13.3.2                                                     \
  open --project .

# instructions.
echo "Now browse to http://localhost:5800 and inside there to https://${EFSS1}1.docker"
echo "Log in as einstein / relativity"
echo "Go to the ScienceMesh app and generate a token"
echo "Click it to go to the meshdir server, and choose ${EFSS2}2 there."
echo "Log in on https://${EFSS2}2.docker as marie / radioactivity"
