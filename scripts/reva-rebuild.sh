#!/usr/bin/env bash

set -e

# find this scripts location.
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
   # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

cd "$DIR/.." || exit

REPO_ROOT=$(pwd)

# get reva container names. (this assumes only 2 containers with reva in their names exist)
REVA1=$(docker ps --filter "name=reva" --format "{{.Names}}" | tail -1)
REVA2=$(docker ps --filter "name=reva" --format "{{.Names}}" | head -1)

# stop revad containers.
docker stop "${REVA1}"
docker stop "${REVA2}"

docker run -it --rm                                                             \
    -v "${REPO_ROOT}/reva:/reva"                                                \
    --workdir /reva                                                             \
    pondersource/pondersource/dev-stock-revad                                   \
    bash -c "go mod vendor && make revad"

# start revad containers.
docker start "${REVA1}"
docker start "${REVA2}"
