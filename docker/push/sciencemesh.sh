#!/usr/bin/env bash

set -e

echo "Log in as pondersource"
docker login

docker push pondersource/dev-stock-revad:latest
docker push pondersource/dev-stock-nextcloud-sciencemesh:latest
docker push pondersource/dev-stock-owncloud-sciencemesh:latest
