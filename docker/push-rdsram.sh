#!/usr/bin/env bash

set -e

echo "Log in as pondersource"
docker login pondersource

docker push pondersource/dev-stock-owncloud-opencloudmesh

docker push pondersource/dev-stock-owncloud-rd-sram
