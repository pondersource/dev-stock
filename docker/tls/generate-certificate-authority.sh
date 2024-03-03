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

echo "Generating Certificate Authority key"
openssl genrsa -out "${ENV_ROOT}/certificate-authority/dev-stock.key"

echo "Generate CA self-signed certificate"
openssl req -new -x509                                                                                        \
    -days 36500                                                                                               \
    -key "${ENV_ROOT}/certificate-authority/dev-stock.key"                                                    \
    -out "${ENV_ROOT}/certificate-authority/dev-stock.crt"                                                    \
    -subj "/C=RO/ST=Bucharest/L=Bucharest/O=IT/CN=dev-stock"
