#!/bin/bash
echo Log in as pondersource
docker login
docker push pondersource/dev-stock-ocmstub
docker push pondersource/dev-stock-revad
docker push pondersource/dev-stock-nc1
docker push pondersource/dev-stock-nc2
docker push pondersource/dev-stock-oc1
docker push pondersource/dev-stock-oc2
docker push pondersource/dev-stock-nc1-sciencemesh
docker push pondersource/dev-stock-nc2-sciencemesh
docker push pondersource/dev-stock-nc1-sciencemesh-network-beta
docker push pondersource/dev-stock-nc2-sciencemesh-network-beta
docker push pondersource/dev-stock-oc1-sciencemesh
docker push pondersource/dev-stock-oc2-sciencemesh
docker push pondersource/dev-stock-oc1-rd-sram
docker push pondersource/dev-stock-oc2-rd-sram
# docker push pondersource/dev-stock-nc1-solid
# docker push pondersource/dev-stock-nc2-mfa-awareness
# docker push pondersource/dev-stock-nc1-peppolnext
# docker push pondersource/dev-stock-nc2-peppolnext
