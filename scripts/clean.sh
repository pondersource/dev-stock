#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

running=$(docker ps -q)
([ -z "$running" ] && echo "no running containers!") || docker kill $running
existing=$(docker ps -qa)
([ -z "$existing" ] && echo "no existing containers!") || docker rm $existing
docker network remove testnet || true
docker network create testnet
