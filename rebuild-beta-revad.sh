#!/bin/bash
set -e

cd servers/ocmstub

echo Building pondersource/dev-stock-revad-network-beta 
cd ../revad-beta
cp -r ../../tls .
docker build -t pondersource/dev-stock-revad-network-beta .

