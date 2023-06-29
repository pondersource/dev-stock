#!/usr/bin/env bash

REPO_ROOT=$(pwd)
export REPO_ROOT=${REPO_ROOT}
[ ! -d "./scripts" ] && echo "Directory ./scripts DOES NOT exist inside $REPO_ROOT, are you running this from the repo root?" && exit 1

# make sure scripts are executable.
chmod +x "${REPO_ROOT}/docker/scripts/reva-run.sh"
chmod +x "${REPO_ROOT}/docker/scripts/reva-kill.sh"
chmod +x "${REPO_ROOT}/docker/scripts/reva-entrypoint.sh"

docker run --detach --name=rclone.docker    --network=testnet  rclone/rclone rcd -vv --rc-user=rcloneuser --rc-pass=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek --rc-addr=0.0.0.0:5572 --server-side-across-configs=true --log-file=/dev/stdout

# revad1
docker run --detach --network=testnet                                         \
  --name="revad1.docker"                                                      \
  -e HOST="revad1"                                                            \
  -v "${REPO_ROOT}/reva:/reva"                                                \
  -v "${REPO_ROOT}/docker/revad:/etc/revad"                                   \
  -v "${REPO_ROOT}/docker/tls:/etc/revad/tls"                                 \
  -v "${REPO_ROOT}/docker/scripts/reva-run.sh:/usr/bin/reva-run.sh"           \
  -v "${REPO_ROOT}/docker/scripts/reva-kill.sh:/usr/bin/reva-kill.sh"         \
  -v "${REPO_ROOT}/docker/scripts/reva-entrypoint.sh:/entrypoint.sh"          \
  pondersource/dev-stock-revad ${REVA_CMD}


# revad2
docker run --detach --network=testnet                                         \
  --name="revad2.docker"                                               \
  -e HOST="revad2"                                                     \
  -v "${REPO_ROOT}/reva:/reva"                                                \
  -v "${REPO_ROOT}/docker/revad:/etc/revad"                                   \
  -v "${REPO_ROOT}/docker/tls:/etc/revad/tls"                                 \
  -v "${REPO_ROOT}/docker/scripts/reva-run.sh:/usr/bin/reva-run.sh"           \
  -v "${REPO_ROOT}/docker/scripts/reva-kill.sh:/usr/bin/reva-kill.sh"         \
  -v "${REPO_ROOT}/docker/scripts/reva-entrypoint.sh:/entrypoint.sh"          \
  pondersource/dev-stock-revad ${REVA_CMD}

