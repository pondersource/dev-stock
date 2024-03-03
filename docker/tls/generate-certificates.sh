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

cd "${DIR}" || exit

ENV_ROOT=$(pwd)
export ENV_ROOT=${ENV_ROOT}

function createCertificate {
  echo "Generating key and CSR for ${1}.docker"

  openssl req -new -nodes                                                                                     \
    -out    "${ENV_ROOT}/certificates/${1}.csr"                                                               \
    -keyout "${ENV_ROOT}/certificates/${1}.key"                                                               \
    -subj   "/C=RO/ST=Bucharest/L=Bucharest/O=IT/CN=${1}.docker"

  echo Creating extfile
  echo "subjectAltName = @alt_names"                                                       >   "./tls/${1}.cnf"
  echo "[alt_names]"                                                                       >>  "./tls/${1}.cnf"
  echo "DNS.1 = ${1}.docker"                                                               >>  "./tls/${1}.cnf"

  echo "Signing CSR for ${1}.docker, creating cert."

  openssl x509 -req                                                                                           \
    -days             36500                                                                                   \
    -in               "${ENV_ROOT}/certificates/${1}.csr"                                                     \
    -CA               "${ENV_ROOT}/certificate-authority/dev-stock.crt"                                       \
    -CAkey            "${ENV_ROOT}/certificate-authority/dev-stock.key"                                       \
    -CAcreateserial                                                                                           \
    -out              "${ENV_ROOT}/certificates/${1}.crt"                                                     \
    -extfile          "${ENV_ROOT}/certificates/${1}.cnf"
}

rm -rf "${ENV_ROOT}/certificates"
mkdir -p "${ENV_ROOT}/certificates"

createCertificate nc1
createCertificate nc2
createCertificate nextcloud1
createCertificate nextcloud2
createCertificate oc1
createCertificate oc2
createCertificate owncloud1
createCertificate owncloud2
createCertificate revad1
createCertificate revad2
createCertificate revanextcloud1
createCertificate revanextcloud2
createCertificate revaowncloud1
createCertificate revaowncloud2

createCert idp
sudo chown 1000:root "${ENV_ROOT}"/certificates/idp.*

createCert meshdir
createCert stub1
createCert stub2
createCert revad1
createCert revad2

for efss in owncloud nextcloud cernbox ocis nc oc; do
  createCert ${efss}1
  createCert ${efss}2
  createCert reva${efss}1
  createCert reva${efss}2
  createCert wopi${efss}1
  createCert wopi${efss}2
done
