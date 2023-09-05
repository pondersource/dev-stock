#!/usr/bin/env bash

set -e

REPO_ROOT=$(pwd)

"${REPO_ROOT}/scripts/clean.sh"

# repositories and branches.
REPO_OWNCLOUD_APP=https://github.com/pondersource/oc-opencloudmesh
BRANCH_OWNCLOUD_APP=release

# create temp dirctory if it doesn't exist.
[ ! -d "${REPO_ROOT}/temp" ] && mkdir -p "${REPO_ROOT}/temp"

# copy init files.
cp --force "${REPO_ROOT}/docker/scripts/init-owncloud-opencloudmesh.sh" "${REPO_ROOT}/temp/oc-opencloudmesh.sh"

# ownCloud opencloudmesh source code.
[ ! -d "oc-ocm-release" ] &&                                                    \
    git clone                                                                   \
    --depth 1                                                                   \
    --branch ${BRANCH_OWNCLOUD_APP}                                             \
    ${REPO_OWNCLOUD_APP}                                                        \
    oc-ocm-release

mkdir -p "${REPO_ROOT}/oc-ocm-release/opencloudmesh/release"

"${REPO_ROOT}/release/tag-release.py" oc none oc-ocm-release/opencloudmesh

docker run --detach --network=testnet                                           \
  --name=maria1.docker                                                          \
  -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek             \
  mariadb                                                                       \
  --transaction-isolation=READ-COMMITTED                                        \
  --binlog-format=ROW                                                           \
  --innodb-file-per-table=1                                                     \
  --skip-innodb-read-only-compressed

docker run --detach --network=testnet                                           \
  --name=oc-release.docker                                                      \
  --add-host "host.docker.internal:host-gateway"                                \
  -e HOST="oc1"                                                                 \
  -e DBHOST="maria1.docker"                                                     \
  -e USER="einstein"                                                            \
  -e PASS="relativity"                                                          \
  -v "${REPO_ROOT}/temp/oc-opencloudmesh.sh:/init.sh"                           \
  -v "${REPO_ROOT}/oc-ocm-release:/var/www/html/apps/oc-opencloudmesh"          \
  -v "${REPO_ROOT}/release/opencloudmesh.key:/var/www/opencloudmesh.key"        \
  pondersource/dev-stock-owncloud-opencloudmesh


docker exec --user root oc-release.docker bash -c "chown www-data:www-data -R /var/www/html/apps/oc-opencloudmesh && chown www-data:www-data /var/www/opencloudmesh.key"
docker exec --user www-data oc-release.docker bash -c "cd /var/www/html/apps/opencloudmesh              \
                                                    &&                                                  \
                                                    mkdir -p build/opencloudmesh                        \
                                                    &&                                                  \
                                                    rm -rf build/opencloudmesh/*                        \
                                                    &&                                                  \
                                                    cp -r appinfo build/opencloudmesh/                  \
                                                    &&                                                  \
                                                    cp -r lib build/opencloudmesh/                      \
                                                    &&                                                  \
                                                    cd build/opencloudmesh/                             \
                                                    &&                                                  \
                                                    cd /var/www/html                                    \
                                                    &&                                                  \
                                                    ./occ integrity:sign-app                            \
                                                    --privateKey=/var/www/opencloudmesh.key             \
                                                    --certificate=apps/opencloudmesh/opencloudmesh.crt  \
                                                    --path=apps/opencloudmesh/build/opencloudmesh       \
                                                    &&                                                  \
                                                    cd apps/opencloudmesh/build                         \
                                                    &&                                                  \
                                                    tar -cf opencloudmesh.tar opencloudmesh"

docker exec --user root oc-release.docker bash -c "cd /var/www/html/apps/opencloudmesh/release          \
                                                    &&                                                  \
                                                    mv ../build/opencloudmesh.tar .                     \
                                                    &&                                                  \
                                                    rm -f -- opencloudmesh.tar.gz                       \
                                                    &&                                                  \
                                                    gzip opencloudmesh.tar"

"${REPO_ROOT}/scripts/clean.sh"

# clear contents of opencloudmesh key.
sudo chown gitpod:gitpod "${REPO_ROOT}/release/opencloudmesh.key"
truncate -s 0 "${REPO_ROOT}/release/opencloudmesh.key"

# add new tar.gz to git and push.
sudo chown gitpod:gitpod -R "${REPO_ROOT}/oc-ocm-release"
cd "${REPO_ROOT}/oc-ocm-release"
git add "${REPO_ROOT}/oc-ocm-release/opencloudmesh/release/opencloudmesh.tar.gz"
git commit -m "Update release tarball of the application"
git push origin

# remove the release folder.
cd "${REPO_ROOT}"
sudo rm -rf "${REPO_ROOT}/oc-ocm-release"
