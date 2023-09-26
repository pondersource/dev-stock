#!/usr/bin/env bash

mkdir -p /tls
ln --symbolic --force "/tls-host/${HOST}.crt"   /tls/server.cert
ln --symbolic --force "/tls-host/${HOST}.key"   /tls/server.key

# This will exec the CMD from your Dockerfile, i.e. "npm start"
exec "$@"
