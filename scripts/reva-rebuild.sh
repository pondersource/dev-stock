#!/usr/bin/env bash

set -e

REPO_ROOT=$(pwd)

# get reva container names. (this assumes only 2 containers with reva in their names exist)
REVA1=$(docker ps --filter "name=reva" --format "{{.Names}}" | tail -1)
REVA2=$(docker ps --filter "name=reva" --format "{{.Names}}" | head -1)

# stop revad containers.
docker stop "${REVA1}"
docker stop "${REVA2}"

cd "${REPO_ROOT}/reva"

# rebuild reva.
go mod tidy
go mod vendor
make revad

# start revad containers.
docker start "${REVA1}"
docker start "${REVA2}"
