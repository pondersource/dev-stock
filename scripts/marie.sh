#!/bin/bash
set -e

docker exec -it revad1.docker /reva/cmd/reva/reva -insecure -host localhost:19000
