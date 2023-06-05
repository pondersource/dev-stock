#!/usr/bin/env bash

set -e

REPO_ROOT=$(pwd)
export REPO_ROOT=$REPO_ROOT
[ ! -d "./scripts" ] && echo "Directory ./scripts DOES NOT exist inside $REPO_ROOT, are you running this from the repo root?" && exit 1

docker run -d --network=testnet --name=revad1.docker -v "$REPO_ROOT/reva:/reva" -e HOST=revad1 pondersource/dev-stock-revad
docker run -d --network=testnet --name=rclone1.docker rclone/rclone rcd -vv --rc-user=rcloneuser --rc-pass=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek --rc-addr=0.0.0.0:5572 --server-side-across-configs=true --log-file=/dev/stdout
docker run -d --network=testnet --name=revad2.docker -v "$REPO_ROOT/reva:/reva" -e HOST=revad2 pondersource/dev-stock-revad
docker run -d --network=testnet --name=rclone2.docker rclone/rclone rcd -vv --rc-user=rcloneuser --rc-pass=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek --rc-addr=0.0.0.0:5572 --server-side-across-configs=true --log-file=/dev/stdout
