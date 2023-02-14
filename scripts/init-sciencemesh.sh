#!/bin/bash

docker pull pondersource/dev-stock-revad
docker pull pondersource/dev-stock-nc1-sciencemesh
docker pull pondersource/dev-stock-nc2-sciencemesh
docker pull pondersource/dev-stock-oc1-sciencemesh
docker pull pondersource/dev-stock-oc2-sciencemesh
docker pull pondersource/dev-stock-ocmstub
docker pull jlesage/firefox:v1.17.1
docker pull mariadb
[ ! -d "oc-sciencemesh" ] && git clone https://github.com/pondersource/oc-sciencemesh
[ ! -d "nc-sciencemesh" ] && git clone https://github.com/pondersource/nc-sciencemesh
