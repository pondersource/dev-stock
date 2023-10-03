#!/usr/bin/env bash
set -e

echo "Log in as pondersource"
docker login

docker push pondersource/dev-stock-revad

docker push pondersource/dev-stock-nextcloud-sciencemesh

docker push pondersource/dev-stock-owncloud-sciencemesh
