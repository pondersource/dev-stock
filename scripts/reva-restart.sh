#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

# get reva container names. (this assumes only 2 containers with reva in their names exist)
REVA1=$(docker ps --filter "name=reva" --format "{{.Names}}" | tail -1)
REVA2=$(docker ps --filter "name=reva" --format "{{.Names}}" | head -1)

docker restart "${REVA1}"
docker restart "${REVA2}"
