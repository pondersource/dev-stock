#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# create new dir and copy relevant configs there.
rm -rf                                                                                  /etc/revad
mkdir -p                                                                                /etc/revad
cp /configs/revad/*                                                                     /etc/revad/

if [ "${HOST::-1}" == "revacernbox" ]; then
  cp /configs/cernbox/*                                                                 /etc/revad/
  rm /etc/revad/sciencemesh*.toml
fi

# substitute placeholders and "external" values with valid ones for the testnet.
sed -i "s/your.revad.org/${HOST}.docker/"                                               /etc/revad/*.toml
sed -i "s/localhost/${HOST}.docker/"                                                    /etc/revad/*.toml
sed -i "s/your.efss.org/${HOST//reva/}.docker/"                                         /etc/revad/*.toml
sed -i "s/your.nginx.org/${HOST//reva/}.docker/"                                        /etc/revad/*.toml
# sed: -e expression #1, char 22: unknown option to `s'
# sed -i "s/your.wopi.org/${HOST/reva/wopi/}.docker/"                                     /etc/revad/*.toml
sed -i "s/debug/trace/"                                                                 /etc/revad/*.toml

# update OS certificate store.
mkdir -p /tls

[ -d "/tls-host" ] &&                                                           \
  cp -f /tls-host/*.crt                   /tls/                                 \
  &&                                                                            \
  cp -f /tls-host/*.key                   /tls/

[ -d "/certificate-authority" ] &&                                              \
  cp -f /certificate-authority/*.crt      /tls/                                 \
  &&                                                                            \
  cp -f /certificate-authority/*.key      /tls/

cp -f /tls/*.crt                             /usr/local/share/ca-certificates/ || true
update-ca-certificates

ln --symbolic --force "/tls/${HOST}.crt" /tls/server.crt
ln --symbolic --force "/tls/${HOST}.key" /tls/server.key

# run revad.
revad --dev-dir "/etc/revad" &
