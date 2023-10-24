#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

# run /reva/cmd/reva/reva inside /bin/bash -c "..." so /root/.reva-token is accessible
docker exec -it revad2.docker /bin/bash -c "/reva/cmd/reva/reva -insecure -host localhost:19000"
