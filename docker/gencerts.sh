#!/usr/bin/env bash

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

cd "$DIR" || exit

function createCert {
  echo "Generating key and CSR for ${1}.docker"
  openssl req -new -nodes \
    -out "./tls/${1}.csr" \
    -keyout "./tls/${1}.key" \
    -subj "/C=RO/ST=Bucharest/L=Bucharest/O=IT/CN=${1}.docker"
  echo Creating extfile
  echo "subjectAltName = @alt_names" > "./tls/${1}.cnf"
  echo "[alt_names]" >> "./tls/${1}.cnf"
  echo "DNS.1 = ${1}.docker" >> "./tls/${1}.cnf"

  echo "Signing CSR for ${1}.docker, creating cert."
  openssl x509 -req -days 3650 -in "./tls/${1}.csr" \
    -CA ./tls/ocm-ca.crt -CAkey ./tls/ocm-ca.key -CAcreateserial \
    -out "./tls/${1}.crt" -extfile "./tls/${1}.cnf"
}

rm --recursive --force ./tls
mkdir -p ./tls

# Don't need this anymore as we store ocm-ca in separate folder and copy it back into tls.
# I'm keeping this code commented for future use.

# echo "Generating CA key"
# openssl genrsa -out ./tls/ocm-ca.key 2058

# echo "Generate CA self-signed certificate"
# openssl req -new -x509 -days 3650 \
#     -key ./tls/ocm-ca.key \
#     -out ./tls/ocm-ca.crt \
#     -subj "/C=RO/ST=Bucharest/L=Bucharest/O=IT/CN=ocm-ca"

echo "Copying CA certificate and CA browser db"
cp ./ca/* ./tls

createCert idp
sudo chown 1000:root ./tls/idp.*

createCert meshdir
createCert stub1
createCert stub2
createCert revad1
createCert revad2

for efss in owncloud nextcloud cernbox nc oc; do
  createCert ${efss}1
  createCert ${efss}2
  createCert reva${efss}1
  createCert reva${efss}2
  createCert wopi${efss}1
  createCert wopi${efss}2
done
