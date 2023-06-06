#!/usr/bin/env bash

ln --symbolic "/tls/${HOST}.crt" /tls/server.cert
ln --symbolic "/tls/${HOST}.key" /tls/server.key

# This will exec the CMD from your Dockerfile, i.e. "npm start"
exec "$@"
