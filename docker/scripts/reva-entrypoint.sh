#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

# see https://github.com/golang/go/issues/22846#issuecomment-380809416
echo "hosts: files dns" > /etc/nsswitch.conf
echo "127.0.0.1 ${HOST}.docker" >> /etc/hosts

# create log file.
touch /var/log/revad.log

# run revad.
reva-run.sh

# This will exec the CMD from your Dockerfile, i.e. "npm start"
exec "$@"
