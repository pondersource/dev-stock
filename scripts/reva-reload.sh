#!/usr/bin/env bash

set -e

REPO_ROOT=$(pwd)

# get reva container names. (this assumes only 2 containers with reva in their names exist)
REVA1=$(docker ps --filter "name=reva" --format "{{.Names}}" | tail -1)
REVA2=$(docker ps --filter "name=reva" --format "{{.Names}}" | head -1)

# kill reva.
docker exec "${REVA1}" bash -c "reva-kill.sh"
docker exec "${REVA2}" bash -c "reva-kill.sh"

cd "${REPO_ROOT}/reva"

# rebuild reva.
go mod tidy
go mod vendor
make revad

# run revad.
docker exec "${REVA1}" bash -c "reva-run.sh"
docker exec "${REVA2}" bash -c "reva-run.sh"
