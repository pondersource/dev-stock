#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# 3rd party images.
docker pull mariadb:latest
docker pull memcached:1.6.18
docker pull cypress/included:13.3.0
docker pull seafileltd/seafile-mc:11.0.5
