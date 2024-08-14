#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# create reva directory if it doesn't exist.
if [ ! -d /reva ]; then
    mkdir -p /reva
fi

# if /reva has any files in it, do not copy image binaries into it.
if [ -n "$(find /reva -prune -empty -type d 2>/dev/null)" ]; then
    echo "/reva is an empty directory, populating it with reva binaries."
    # populate /reva with Reva binaries.
    cp -ar /reva-git/cmd /reva
else
    ls -lsa /reva
    echo "/reva contains files, doing noting."
fi

# create new dir and copy relevant configs there.
rm -rf                                                                                  /etc/revad
mkdir -p                                                                                /etc/revad
cp /configs/revad/*                                                                     /etc/revad/

# substitute placeholders and "external" values with valid ones for the testnet.
sed -i "s/your.revad.org/${HOST}.docker/"                                               /etc/revad/*.toml
sed -i "s/localhost/${HOST}.docker/"                                                    /etc/revad/*.toml
sed -i "s/your.efss.org/${HOST//reva/}.docker/"                                         /etc/revad/*.toml
sed -i "s/your.nginx.org/${HOST//reva/}.docker/"                                        /etc/revad/*.toml

# update OS certificate store.
mkdir -p /tls

[ -d "/certificates" ] &&                                                               \
  cp -f /certificates/*.crt                     /tls/                                   \
  &&                                                                                    \
  cp -f /certificates/*.key                     /tls/

[ -d "/certificate-authority" ] &&                                                      \
  cp -f /certificate-authority/*.crt            /tls/                                   \
  &&                                                                                    \
  cp -f /certificate-authority/*.key            /tls/

cp -f /tls/*.crt                                /usr/local/share/ca-certificates/ || true
update-ca-certificates

ln -sf "/tls/${HOST}.crt"                       /tls/server.crt
ln -sf "/tls/${HOST}.key"                       /tls/server.key

# run revad.
revad --dev-dir "/etc/revad" &
