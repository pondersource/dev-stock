#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

mkdir -p /tls
ln --symbolic --force "/tls-host/${HOST}.crt" /tls/server.cert
ln --symbolic --force "/tls-host/${HOST}.key" /tls/server.key

sed -i "s/ServerName localhost/ServerName ${HOST}.docker/g" /etc/apache2/conf-available/servername.conf

# This will exec the CMD from your Dockerfile, i.e. "npm start"
exec "$@"
