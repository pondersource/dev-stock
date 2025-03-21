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

# create temp dirctory if it doesn't exist.
[ ! -d "${ENV_ROOT}/temp" ] && mkdir -p "${ENV_ROOT}/temp"

EFSS1=nc

# copy init files.
cp -f ./docker/scripts/init/nextcloud-sunet.sh ./temp/init-nextcloud-sunet.sh

docker run --detach --name=firefox          --network=testnet -p 5800:5800  --shm-size 2g jlesage/firefox:latest
docker run --detach --name=firefox-legacy   --network=testnet -p 5900:5800  --shm-size 2g jlesage/firefox:v1.18.0

docker run --detach --network=testnet                                                                                             \
  --name=maria1.docker                                                                                                            \
  -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek                                                               \
  mariadb:11.4.2                                                                                                                 \
  --transaction-isolation=READ-COMMITTED                                                                                          \
  --binlog-format=ROW                                                                                                             \
  --innodb-file-per-table=1                                                                                                       \
  --skip-innodb-read-only-compressed

docker run --detach --network=testnet                                                                                             \
  --name="${EFSS1}1.docker"                                                                                                       \
  --add-host "host.docker.internal:host-gateway"                                                                                  \
  -e HOST="${EFSS1}1"                                                                                                             \
  -e DBHOST="maria1.docker"                                                                                                       \
  -e USER="einstein"                                                                                                              \
  -e PASS="relativity"                                                                                                            \
  -v "${ENV_ROOT}/docker/tls:/tls-host"                                                                                           \
  -v "${ENV_ROOT}/docker/sunet/entrypoint:/entrypoint"                                                                            \
  -v "${ENV_ROOT}/temp/init-nextcloud-sunet.sh:/init.sh"                                                                          \
  -v "${ENV_ROOT}/mfazones:/var/www/html/apps/mfazones"                                                                           \
  -v "${ENV_ROOT}/server/apps/workflowengine:/var/www/html/apps/workflowengine"                                                   \
  -v "${ENV_ROOT}/server/dist/workflowengine-workflowengine.js:/var/www/html/dist/workflowengine-workflowengine.js"               \
  -v "${ENV_ROOT}/server/dist/workflowengine-workflowengine.js.map:/var/www/html/dist/workflowengine-workflowengine.js.map"       \
  "pondersource/nextcloud-sunet"

docker run --detach --network=testnet                                                                                             \
  --name=sunet-ssp-mdb                                                                                                            \
  -e MYSQL_ROOT_PASSWORD=r00tp@ssw0rd                                                                                             \
  -e MYSQL_PASSWORD=sspus3r                                                                                                       \
  -e MYSQL_USER=sspuser                                                                                                           \
  -e MYSQL_DATABASE=saml                                                                                                          \
  mariadb

docker run --detach --network=testnet                                                                                             \
  --name=sunet-ssp                                                                                                                \
  pondersource/dev-stock-simple-saml-php

echo Done starting Docker containers in testnet...

# EFSS1
waitForPort "${EFSS1}1.docker" 443
waitForPort maria1.docker 3306
waitForPort sunet-ssp-mdb 3306

docker exec "${EFSS1}1.docker" bash -c "cp /tls/*.crt /usr/local/share/ca-certificates/"
docker exec "${EFSS1}1.docker" bash -c "cp /tls-host/*.crt /usr/local/share/ca-certificates/"
docker exec "${EFSS1}1.docker" update-ca-certificates
docker exec "${EFSS1}1.docker" bash -c "cat /etc/ssl/certs/ca-certificates.crt >> /var/www/html/resources/config/ca-bundle.crt"

docker exec -u www-data "${EFSS1}1.docker" bash "/init.sh"

# run db injections.
mysql1_cmd="docker exec maria1.docker mariadb -u root -peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss"
mysql2_cmd="docker exec sunet-ssp-mdb mariadb -u sspuser -psspus3r saml"

$mysql1_cmd -e "INSERT INTO oc_appconfig (appid, configkey, configvalue) VALUES \
(\"user_saml\", \"type\", \"saml\")"

$mysql1_cmd -e "INSERT INTO oc_user_saml_configurations (id, name, configuration) VALUES \
(1, \"samlidp\", \"{\
\\\"general-uid_mapping\\\":\\\"username\\\",\
\\\"general-idp0_display_name\\\":\\\"samlidp\\\",\
\\\"idp-entityId\\\":\\\"http:\/\/sunet-ssp\/simplesaml\/saml2\/idp\/metadata.php\\\",\
\\\"idp-singleSignOnService.url\\\":\\\"http:\/\/sunet-ssp\/simplesaml\/saml2\/idp\/SSOService.php\\\",\
\\\"idp-x509cert\\\":\\\"MIIDazCCAlOgAwIBAgIUTQg4Wn5st4nmtOT08sQhGRcUbl8wDQYJKoZIhvcNAQEL\
BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM\
GEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAeFw0yMjEwMjcxMzIxNTlaFw0zMjEw\
MjYxMzIxNTlaMEUxCzAJBgNVBAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEw\
HwYDVQQKDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQwggEiMA0GCSqGSIb3DQEB\
AQUAA4IBDwAwggEKAoIBAQC9hOJBGYdIAqzRNYBYk6BCXUQc8ECSDEFVp3hPxwoM\
7x4eGZNmpr2xrCVMR+YJZ2ofGdjzBwSbxQOWD1xO4e432taJAx9G4sDfNeJuJUGx\
dP4Id/jYMZJ/b6oQ8FTXEbi8ZflSBa/z7bvlGUDm/I7U6XYcAeDxCe0mvOUYVex5\
WcNLGeZO26iq/OOR2c2NuD/IwnIhDAcnyF/eWMeeuLWNxPIew15mUSK2uDzI5b82\
6GTNE9tgYc9TAoz95/IfvJAHyigqJTqjjpvDwGWPufOVUycFGRNCu7HsLSaapyg3\
JlnlRq5PJjmc8pJYGfj5gms0l+lbVvnhcPQHRzRgDsnbAgMBAAGjUzBRMB0GA1Ud\
DgQWBBTqLY1LIUEvyHaKUn90axnp1FPcOjAfBgNVHSMEGDAWgBTqLY1LIUEvyHaK\
Un90axnp1FPcOjAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQCD\
l+p9ZcRoG6z3+LJXZIexOzYVHFRr71UBv1NPiyO5bJw332RdiYhB0s8PAyTCavSL\
hVK4WhAam/lZX9sNMSXb9QwSqjHiYT+DA5loaGJJU7DMHeqvifL1kXz776Lv+70U\
h9qjuXIz74Ye4zQA+ALTb3M65kMaRJ9juLEdUVsnLUPvLhKBG8MHXX6sFv2mE6Cj\
KKNPSvliaChAFHL2gmAEfp2TOzwLF6icRMjuBBCiH/5OiwwViF5mwgpJ938HeC1G\
IIKsVDQgUIDr+KPqQbC4OEsGUCW8bybibdwNdtYgNpDYwysgYHgWDsRdmDmkh5Ly\
Q8CODPPBMk+mAN+xC5hX\\\",\
\\\"saml-attribute-mapping-displayName_mapping\\\":\\\"display_name\\\"}\")"

$mysql2_cmd -e "CREATE TABLE users (\
username varchar(255), \
password varbinary(255), \
display_name varchar(255), \
mfa_verified boolean \
)"

$mysql2_cmd -e "INSERT INTO users \
(username, password, display_name, mfa_verified) VALUES \
(\"usr1\", AES_ENCRYPT(\"pwd1\", \"SECRET\"), \"user 1\", true), \
(\"usr2\", AES_ENCRYPT(\"pwd2\", \"SECRET\"), \"user 2\", false)"

# instructions.
echo ""
echo ""
echo "SUNET MFA Testing Instrcution:"
echo ""
echo ""
echo "Now browse to firefox and inside there to https://${EFSS1}1.docker/index.php/login?direct=1"
echo "Log in as einstein / relativity"
echo ""
echo ""
echo "Visit https://${EFSS1}1.docker/index.php/settings/admin/workflow"
echo "You should see a flow there that prohibits access to files tagged with 'mfazone'"
echo "Unless the current user is MFA verified."
echo ""
echo ""
echo "Inside the opened browser go to http://${EFSS1}1.docker (make sure to use http and not https here,"
echo "and this time leave off the /index.php/login?direct=1 path)."
echo ""
echo ""
echo "We have two users with this creadentials:"
echo "User1:"
echo "* Username: usr1"
echo "* Password: pwd1"
echo "* MFA Verified"
echo ""
echo ""
echo "User2:"
echo "* Username: usr2"
echo "* Password: pwd2"
echo "* Not MFA Verified"
echo ""
echo ""
echo "Only **file owner** or **admin** users can toggle the MFA Zone button,"
echo "and they can only do this from within an MFA-verified session."
echo ""
echo ""
echo "Note that this tests the app on a server with local SAML login."
echo "The setups with gss and Nextcloud-native MFA which we researched in milestone"
echo "3 are separate (see below)."
