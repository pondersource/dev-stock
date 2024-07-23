#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# find this scripts location.
SOURCE=${BASH_SOURCE[0]}
while [ -L "${SOURCE}" ]; do # resolve "${SOURCE}" until the file is no longer a symlink.
  DIR=$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "${SOURCE}")
   # if "${SOURCE}" was a relative symlink, we need to resolve it relative to the path where the symlink file was located.
  [[ "${SOURCE}" != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
DIR=$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )

cd "${DIR}/../../.." || exit

ENV_ROOT=$(pwd)
export ENV_ROOT=${ENV_ROOT}

# oCIS version:
#   - 5.0.6
EFSS_PLATFORM_1_VERSION=${1:-"5.0.6"}

# oCIS version:
#   - 5.0.6
EFSS_PLATFORM_2_VERSION=${2:-"5.0.6"}

# script mode:   dev, ci. default is dev.
SCRIPT_MODE=${3:-"dev"}

# browser platform: chrome, edge, firefox, electron. default is electron.
# only applies on SCRIPT_MODE=ci
BROWSER_PLATFORM=${4:-"electron"}

function redirect_to_null_cmd() {
    if [ "${SCRIPT_MODE}" = "ci" ]; then
        "$@" >/dev/null 2>&1
    else
        "$@"
    fi
}

function waitForPort () {
  redirect_to_null_cmd echo waitForPort "${1} ${2}"
  # the "| cat" after the "| grep" is to prevent the command from exiting with 1 if no match is found by grep.
  x=$(docker exec "${1}" ss -tulpn | grep -c "${2}" | cat)
  until [ "${x}" -ne 0 ]
  do
    redirect_to_null_cmd echo Waiting for "${1} to open port ${2}, this usually takes about 10 seconds ... ${x}"
    sleep 1
    x=$(docker exec "${1}" ss -tulpn | grep -c "${2}" |  cat)
  done
  redirect_to_null_cmd echo "${1} port ${2} is open"
}

function createEfssOcis() {
  local number="${1}"

  redirect_to_null_cmd echo "creating efss ocis ${number}"

  # redirect_to_null_cmd docker run --detach --network=testnet                                                                \
  #   --name="ldapocis${number}.docker"                                                                                       \
  #   -e BITNAMI_DEBUG=true                                                                                                   \
  #   -e  LDAP_TLS_VERIFY_CLIENT=never                                                                                        \
  #   -e  LDAP_ENABLE_TLS="yes"                                                                                               \
  #   -e  LDAP_TLS_CA_FILE="/certificate-authority/dev-stock.crt"                                                             \
  #   -e  LDAP_TLS_CERT_FILE="/certificates/ldapocis${number}.crt"                                                            \
  #   -e  LDAP_TLS_KEY_FILE="/certificates/ldapocis${number}.key"                                                             \
  #   -e  LDAP_ROOT="dc=owncloud,dc=com"                                                                                      \
  #   -e  LDAP_ADMIN_PASSWORD="admin"                                                                                         \
  #   -v "${ENV_ROOT}/temp/ldap/ldifs:/ldifs"                                                                                 \
  #   -v "${ENV_ROOT}/temp/ldap/schemas:/schemas"                                                                             \
  #   -v "${ENV_ROOT}/temp/certificates:/certificates"                                                                        \
  #   -v "${ENV_ROOT}/temp/certificate-authority:/certificate-authority"                                                      \
  #   bitnami/openldap:2.6

  redirect_to_null_cmd docker run --detach --network=testnet                                                                \
    --name="ocis${number}.docker"                                                                                           \
    -e OCIS_LOG_LEVEL=info                                                                                                  \
    -e OCIS_LOG_COLOR=true                                                                                                  \
    -e OCIS_LOG_PRETTY=true                                                                                                 \
    -e PROXY_HTTP_ADDR=0.0.0.0:443                                                                                          \
    -e OCIS_URL="https://ocis${number}.docker"                                                                              \
    -e OCIS_INSECURE=true                                                                                                   \
    -e PROXY_TRANSPORT_TLS_KEY="/certificates/ocis${number}.key"                                                            \
    -e PROXY_TRANSPORT_TLS_CERT="/certificates/ocis${number}.crt"                                                           \
    -e PROXY_ENABLE_BASIC_AUTH=true                                                                                         \
    -e IDM_ADMIN_PASSWORD=admin                                                                                             \
    -e IDM_CREATE_DEMO_USERS=true                                                                                           \
    -v "${ENV_ROOT}/temp/certificates:/certificates"                                                                        \
    -v "${ENV_ROOT}/temp/certificate-authority:/certificate-authority"                                                      \
    --entrypoint /bin/sh                                                                                                    \
    "owncloud/ocis:5.0.6"                                                                                                   \
    -c "ocis init || true; ocis server"


    # -e OCIS_LDAP_URI="ldaps://ldapocis${number}.docker:1636"                                                                \
    # -e OCIS_LDAP_INSECURE="true"                                                                                            \
    # -e OCIS_LDAP_BIND_DN="cn=admin,dc=owncloud,dc=com"                                                                      \
    # -e OCIS_LDAP_BIND_PASSWORD="admin"                                                                                      \
    # -e OCIS_LDAP_GROUP_BASE_DN="ou=groups,dc=owncloud,dc=com"                                                               \
    # -e OCIS_LDAP_GROUP_FILTER="(objectclass=owncloud)"                                                                      \
    # -e OCIS_LDAP_GROUP_OBJECTCLASS="groupOfNames"                                                                           \
    # -e OCIS_LDAP_USER_BASE_DN="ou=users,dc=owncloud,dc=com"                                                                 \
    # -e OCIS_LDAP_USER_FILTER="(objectclass=owncloud)"                                                                       \
    # -e OCIS_LDAP_USER_OBJECTCLASS="inetOrgPerson"                                                                           \
    # -e LDAP_LOGIN_ATTRIBUTES="uid"                                                                                          \
    # -e OCIS_ADMIN_USER_ID="ddc2004c-0977-11eb-9d3f-a793888cd0f8"                                                            \
    # -e IDP_LDAP_LOGIN_ATTRIBUTE="uid"                                                                                       \
    # -e IDP_LDAP_UUID_ATTRIBUTE="ownclouduuid"                                                                               \
    # -e IDP_LDAP_UUID_ATTRIBUTE_TYPE=binary                                                                                  \
    # -e GRAPH_LDAP_SERVER_WRITE_ENABLED="true"                                                                               \
    # -e GRAPH_LDAP_REFINT_ENABLED="true"                                                                                     \
    # -e OCIS_EXCLUDE_RUN_SERVICES=idm                                                                                        \
}

# delete and create temp directory.
rm -rf "${ENV_ROOT}/temp" && mkdir --parents "${ENV_ROOT}/temp/certificates"

# copy init files.
cp -fr "${ENV_ROOT}/docker/configs/ldap"                  "${ENV_ROOT}/temp/ldap"
cp -f "${ENV_ROOT}/docker/tls/certificates/ocis"*         "${ENV_ROOT}/temp/certificates"
cp -f "${ENV_ROOT}/docker/tls/certificates/ldap"*         "${ENV_ROOT}/temp/certificates"
cp -fr "${ENV_ROOT}/docker/tls/certificate-authority"     "${ENV_ROOT}/temp"

# fix permissions.
chmod -R 777  "${ENV_ROOT}/temp/certificates"
chmod -R 777  "${ENV_ROOT}/temp/certificate-authority"

# auto clean before starting.
"${ENV_ROOT}/scripts/clean.sh" "no"

# make sure network exists.
docker network inspect testnet >/dev/null 2>&1 || docker network create testnet >/dev/null 2>&1

############
### oCIS ###
############

# syntax:
# createEfssOcis number.
#
#
# number:         should be unique for each oCIS, for example: you cannot have two oCIS with same number.

# oCISes.
createEfssOcis    1
createEfssOcis    2

###############
### Firefox ###
###############

docker run --detach --network=testnet                                                                     \
  --name=firefox                                                                                          \
  -p 5800:5800                                                                                            \
  --shm-size 2g                                                                                           \
  -e USER_ID="${UID}"                                                                                     \
  -e GROUP_ID="${UID}"                                                                                    \
  -e DARK_MODE=1                                                                                          \
  -v "${ENV_ROOT}/docker/tls/browsers/firefox/cert9.db:/config/profile/cert9.db:rw"                       \
  -v "${ENV_ROOT}/docker/tls/browsers/firefox/cert_override.txt:/config/profile/cert_override.txt:rw"     \
  jlesage/firefox:latest                                                                                  \
  >/dev/null 2>&1
