#!/bin/bash

./scripts/clean.sh

./scripts/init-rd-sram.sh.

./scripts/testing-rd-sram.sh.

docker exec -it oc2.docker sh /curls/includeMarie.sh oc2.docker

docker exec -it oc1.docker sh /curls/includeMarie.sh oc1.docker