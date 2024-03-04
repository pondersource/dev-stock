#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

mkdir -p /tls

[ -d "/tls-host" ] &&                                                           \
  cp -f /tls-host/*.crt                   /tls/                                 \
  &&                                                                            \
  cp -f /tls-host/*.key                   /tls/

ln --symbolic --force "/tls/${HOST}.crt"    /tls/server.crt
ln --symbolic --force "/tls/${HOST}.key"    /tls/server.key

# This will exec the CMD from your Dockerfile, i.e. "npm start"
exec "$@"
