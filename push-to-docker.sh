#!/bin/bash
echo Log in as pondersource
docker login
docker push pondersource/dev-stock-ocmstub
docker push pondersource/dev-stock-revad
docker push pondersource/dev-stock-nc1-sciencemesh
docker push pondersource/dev-stock-nc2-sciencemesh
docker push pondersource/dev-stock-oc1-sciencemesh
docker push pondersource/dev-stock-oc2-sciencemesh