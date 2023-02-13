#!/bin/bash
echo Log in as pondersource
docker login
docker push pondersource/build-stock-ocmstub
docker push pondersource/build-stock-revad
docker push pondersource/build-stock-nc1-sciencemesh
docker push pondersource/build-stock-nc2-sciencemesh
docker push pondersource/build-stock-oc1-sciencemesh
docker push pondersource/build-stock-oc2-sciencemesh