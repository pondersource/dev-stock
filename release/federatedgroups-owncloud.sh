#!/usr/bin/env bash

set -e

REPO_ROOT=$(pwd)

"${REPO_ROOT}/scripts/clean.sh"

# repositories and branches.
REPO_OWNCLOUD_APP=https://github.com/SURFnet/rd-sram-integration
BRANCH_OWNCLOUD_APP=release

# create temp dirctory if it doesn't exist.
[ ! -d "${REPO_ROOT}/temp" ] && mkdir -p "${REPO_ROOT}/temp"

# copy init files.
cp -f "${REPO_ROOT}/docker/scripts/init/owncloud-rd-sram.sh"  "${REPO_ROOT}/temp/oc-rd-sram.sh"

# ownCloud federatedgroups source code.
[ ! -d "rd-sram-release" ] &&                                                                                     \
    git clone                                                                                                     \
    --branch ${BRANCH_OWNCLOUD_APP}                                                                               \
    ${REPO_OWNCLOUD_APP}                                                                                          \
    rd-sram-release

mkdir -p "${REPO_ROOT}/rd-sram-release/federatedgroups/release"

"${REPO_ROOT}/release/tag-release.py" oc none rd-sram-release/federatedgroups

docker run --detach --network=testnet                                                                             \
  --name=maria1.docker                                                                                            \
  -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek                                               \
  mariadb                                                                                                         \
  --transaction-isolation=READ-COMMITTED                                                                          \
  --binlog-format=ROW                                                                                             \
  --innodb-file-per-table=1                                                                                       \
  --skip-innodb-read-only-compressed

docker run --detach --network=testnet                                                                             \
  --name=oc-release.docker                                                                                        \
  --add-host "host.docker.internal:host-gateway"                                                                  \
  -e HOST="oc1"                                                                                                   \
  -e DBHOST="maria1.docker"                                                                                       \
  -e USER="einstein"                                                                                              \
  -e PASS="relativity"                                                                                            \
  -v "${REPO_ROOT}/temp/oc-rd-sram.sh:/init.sh"                                                                   \
  -v "${REPO_ROOT}/rd-sram-release:/var/www/html/apps/rd-sram-integration"                                        \
  -v "${REPO_ROOT}/release/federatedgroups.key:/var/www/federatedgroups.key"                                      \
  pondersource/dev-stock-owncloud-rd-sram


docker exec --user root oc-release.docker bash -c "chown www-data:www-data -R /var/www/html/apps/rd-sram-integration && chown www-data:www-data /var/www/federatedgroups.key"

docker exec --user www-data oc-release.docker bash -c "cd /var/www/html/apps/federatedgroups                      \
                                                      &&                                                          \
                                                      mkdir -p build/federatedgroups                              \
                                                      &&                                                          \
                                                      rm -rf build/federatedgroups/*                              \
                                                      &&                                                          \
                                                      cp -r appinfo build/federatedgroups/                        \
                                                      &&                                                          \
                                                      cp -r lib build/federatedgroups/                            \
                                                      &&                                                          \
                                                      cd build/federatedgroups/                                   \
                                                      &&                                                          \
                                                      cd /var/www/html                                            \
                                                      &&                                                          \
                                                      ./occ integrity:sign-app                                    \
                                                      --privateKey=/var/www/federatedgroups.key                   \
                                                      --certificate=apps/federatedgroups/federatedgroups.crt      \
                                                      --path=apps/federatedgroups/build/federatedgroups           \
                                                      &&                                                          \
                                                      cd apps/federatedgroups/build                               \
                                                      &&                                                          \
                                                      tar -cf federatedgroups.tar federatedgroups"

docker exec --user root oc-release.docker bash -c "mkdir -p /var/www/html/apps/federatedgroups/release            \
                                                  &&                                                              \
                                                  cd /var/www/html/apps/federatedgroups/release                   \
                                                  &&                                                              \
                                                  mv ../build/federatedgroups.tar .                               \
                                                  &&                                                              \
                                                  rm -f -- federatedgroups.tar.gz                                 \
                                                  &&                                                              \
                                                  gzip federatedgroups.tar"

"${REPO_ROOT}/scripts/clean.sh"

# clear contents of federatedgroups key.
sudo chown gitpod:gitpod "${REPO_ROOT}/release/federatedgroups.key"
truncate -s 0 "${REPO_ROOT}/release/federatedgroups.key"

# add new tar.gz to git and push.
sudo chown gitpod:gitpod -R "${REPO_ROOT}/rd-sram-release"
cd "${REPO_ROOT}/rd-sram-release"
git add "${REPO_ROOT}/rd-sram-release/federatedgroups/release/federatedgroups.tar.gz"
git commit -m "Update release tarball of the application"
git push origin

# remove the release folder.
cd "${REPO_ROOT}"
sudo rm -rf "${REPO_ROOT}/rd-sram-release"
