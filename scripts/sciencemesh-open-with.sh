#!/bin/bash
set -e

# git clone https://github.com/ether/etherpad-lite
sudo mkdir -p /etc/grid-security
sudo touch /etc/grid-security/cernbox-hostcert.pem
sudo touch /etc/grid-security/cernbox-hostkey.pem
sudo touch /etc/grid-security/hostcert.pem
sudo touch /etc/grid-security/hostkey.pem
sudo touch /etc/grid-security/dhparam.pem
sudo mkdir -p /root/APPS/etc
sudo touch /root/APPS/etc/ca-chain.pem
sudo mkdir -p /etc/wopi
sudo touch /etc/wopi/codimd_apikey
sudo touch /etc/wopi/etherpad_apikey
docker network create appsnet || true

docker compose -f ./sciencemesh-open-with.yaml up -d

docker run -d --network=testnet --name=revad1.docker -e HOST=revad1 pondersource/dev-stock-revad-network-beta
docker container cp ./example.txt revad1.docker:/etc/revad/example.txt
docker container cp ./sciencemesh-open-with.toml revad1.docker:/etc/revad/revad1.toml
docker restart revad1.docker
echo Now log in as einstein/relativity
docker exec -it revad1.docker /reva/cmd/reva/reva -insecure -host localhost:19000 login basic
docker exec -it revad1.docker /reva/cmd/reva/reva -insecure -host localhost:19000 upload --protocol=simple ./example.txt /home/example.txt
docker exec -it revad1.docker /reva/cmd/reva/reva -insecure -host localhost:19000 open-in-app /home/example.txt read
