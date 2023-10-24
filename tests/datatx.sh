#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

docker run -d --network=testnet --name=revad1.docker -v "$(pwd)/../reva:/reva" -e HOST=revad1 pondersource/dev-stock-revad
docker run -d --network=testnet --name=rclone1.docker rclone/rclone rcd -vv --rc-user=rcloneuser --rc-pass=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek --rc-addr=0.0.0.0:5572 --server-side-across-configs=true --log-file=/dev/stdout
docker run -d --network=testnet --name=revad2.docker -v "$(pwd)/../reva:/reva" -e HOST=revad2 pondersource/dev-stock-revad
docker run -d --network=testnet --name=rclone2.docker rclone/rclone rcd -vv --rc-user=rcloneuser --rc-pass=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek --rc-addr=0.0.0.0:5572 --server-side-across-configs=true --log-file=/dev/stdout
