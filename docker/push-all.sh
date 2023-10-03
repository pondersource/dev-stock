#!/usr/bin/env bash
set -e

echo "Log in as pondersource"
docker login

docker push pondersource/dev-stock-ocmstub

docker push pondersource/dev-stock-revad

docker push pondersource/dev-stock-php-base

docker push pondersource/dev-stock-nextcloud

docker push pondersource/dev-stock-nextcloud-mfa

docker push pondersource/dev-stock-nextcloud-solid

docker push pondersource/dev-stock-nextcloud-sciencemesh

docker push pondersource/dev-stock-owncloud

docker push pondersource/dev-stock-owncloud-sciencemesh

docker push pondersource/dev-stock-owncloud-surf-trashbin

docker push pondersource/dev-stock-owncloud-token-based-access

docker push pondersource/dev-stock-owncloud-opencloudmesh

docker push pondersource/dev-stock-owncloud-rd-sram
