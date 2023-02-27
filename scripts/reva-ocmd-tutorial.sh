#!/bin/bash
set -e

docker run -d --network=testnet --name=revad1.docker -e HOST=revad1 pondersource/dev-stock-revad-network-beta
# docker run -d --network=testnet --name=revad2.docker -e HOST=revad2 pondersource/dev-stock-revad-network-beta
docker container cp ./example.txt revad1.docker:/etc/revad/example.txt

docker container cp ./reva/examples/ocmd/ocmd-server-1.toml revad1.docker:/etc/revad/revad1.toml
docker container cp ./reva/examples/ocmd/ocmd-server-2.toml revad1.docker:/etc/revad/revad2.toml
docker container cp ./reva/examples/ocmd/providers.demo.json revad1.docker:/etc/revad/providers.demo.json
docker container cp ./reva/examples/ocmd/users.demo.json revad1.docker:/etc/revad/users.demo.json
docker restart revad1.docker

# docker container cp ./reva/examples/ocmd/ocmd-server-1.toml revad2.docker:/etc/revad/revad1.toml
# docker container cp ./reva/examples/ocmd/ocmd-server-2.toml revad2.docker:/etc/revad/revad2.toml
# docker container cp ./reva/examples/ocmd/providers.demo.json revad2.docker:/etc/revad/providers.demo.json
# docker container cp ./reva/examples/ocmd/users.demo.json revad2.docker:/etc/revad/users.demo.json
# docker restart revad2.docker

echo Now log in as einstein/relativity
docker exec -it revad1.docker /reva/cmd/reva/reva -insecure -host localhost:19000 login basic
docker exec -it revad1.docker /reva/cmd/reva/reva -insecure -host localhost:19000 mkdir /home/my-folder
docker exec -it revad1.docker /reva/cmd/reva/reva -insecure -host localhost:19000 upload ./example.txt /home/my-folder/example.txt
