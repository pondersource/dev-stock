#!/usr/bin/env bash

set -e

REPO_ROOT=$(pwd)

"${REPO_ROOT}/scripts/clean.sh"

# repositories and branches.
REPO_OWNCLOUD_APP=https://github.com/sciencemesh/nc-sciencemesh
BRANCH_OWNCLOUD_APP=nextcloud

[ ! -d "temp" ] && mkdir -p temp

# copy init file.
cp --force ./docker/scripts/init-nextcloud-sciencemesh.sh ./temp/nc.sh

# add additional tagging for docker images.
docker tag pondersource/dev-stock-nextcloud-sciencemesh pondersource/dev-stock-nc1-sciencemesh

# ownCloud Sciencemesh source code.
[ ! -d "nc-sciencemesh-release" ] &&                                            \
    git clone                                                                   \
    --depth 1                                                                   \
    --branch ${BRANCH_OWNCLOUD_APP}                                             \
    ${REPO_OWNCLOUD_APP}                                                        \
    nc-sciencemesh-release                                                      \
    &&                                                                          \
    docker run -it                                                              \
    -v "${REPO_ROOT}/nc-sciencemesh-release:/var/www/html/apps/sciencemesh"     \
    --workdir /var/www/html/apps/sciencemesh                                    \
    pondersource/dev-stock-nc1-sciencemesh                                      \
    make composer

"${REPO_ROOT}/release/tag-release.py" nc none nc-sciencemesh-release

docker run --detach --network=testnet                                           \
  --name=maria1.docker                                                          \
  -e MARIADB_ROOT_PASSWORD=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek             \
  mariadb                                                                       \
  --transaction-isolation=READ-COMMITTED                                        \
  --binlog-format=ROW                                                           \
  --innodb-file-per-table=1                                                     \
  --skip-innodb-read-only-compressed

docker run --detach --network=testnet                                           \
  --name=nc-release.docker                                                      \
  --add-host "host.docker.internal:host-gateway"                                \
  -e HOST="nc1"                                                                 \
  -e DBHOST="maria1.docker"                                                     \
  -e USER="einstein"                                                            \
  -e PASS="relativity"                                                          \
  -v "${REPO_ROOT}/temp/nc.sh:/nc-init.sh"                                      \
  -v "${REPO_ROOT}/nc-sciencemesh-release:/var/www/html/apps/sciencemesh"       \
  -v "${REPO_ROOT}/release/sciencemesh.key:/var/www/sciencemesh.key"            \
  "pondersource/dev-stock-nextcloud-sciencemesh"

docker exec --user root nc-release.docker bash -c "chown www-data:www-data -R /var/www/html/apps/sciencemesh && chown www-data:www-data /var/www/sciencemesh.key"
docker exec --user www-data nc-release.docker bash -c "cd /var/www/html/apps/sciencemesh                \
                                                    &&                                                  \
                                                    mkdir -p build/sciencemesh                          \
                                                    &&                                                  \
                                                    rm -rf build/sciencemesh/*                          \
                                                    &&                                                  \
                                                    cp -r appinfo build/sciencemesh/                    \
                                                    &&                                                  \
                                                    cp -r css build/sciencemesh/                        \
                                                    &&                                                  \
                                                    cp -r img build/sciencemesh/                        \
                                                    &&                                                  \
                                                    cp -r js build/sciencemesh/                         \
                                                    &&                                                  \
                                                    cp -r lib build/sciencemesh/                        \
                                                    &&                                                  \
                                                    cp -r templates build/sciencemesh/                  \
                                                    &&                                                  \
                                                    cp -r composer.* build/sciencemesh/                 \
                                                    &&                                                  \
                                                    cd build/sciencemesh/                               \
                                                    &&                                                  \
                                                    composer install                                    \
                                                    &&                                                  \
                                                    cd ..                                               \
                                                    &&                                                  \
                                                    tar -cf sciencemesh.tar sciencemesh"

echo "NextCloud Signature start:"
docker exec --user root nc-release.docker bash -c "cd /var/www/html/apps/sciencemesh/release            \
                                                    &&                                                  \
                                                    mv ../build/sciencemesh.tar .                       \
                                                    &&                                                  \
                                                    rm -f -- sciencemesh.tar.gz                         \
                                                    &&                                                  \
                                                    gzip sciencemesh.tar                                \
                                                    &&                                                  \
                                                    openssl dgst                                        \
                                                    -sha512                                             \
                                                    -sign /var/www/sciencemesh.key                      \
                                                    ./sciencemesh.tar.gz | openssl base64"
echo "NextCloud Signature end"

"${REPO_ROOT}/scripts/clean.sh"

# clear contents of sciencemesh key.
sudo chown gitpod:gitpod "${REPO_ROOT}/release/sciencemesh.key"
truncate -s 0 "${REPO_ROOT}/release/sciencemesh.key"

# add new tar.gz to git and push.
sudo chown gitpod:gitpod -R "${REPO_ROOT}/nc-sciencemesh-release"
cd "${REPO_ROOT}/nc-sciencemesh-release"
git add "${REPO_ROOT}/nc-sciencemesh-release/release/sciencemesh.tar.gz"
git commit -m "Update release tarball of the application"
git push origin

# remove the release folder.
cd "${REPO_ROOT}"
sudo rm -rf "${REPO_ROOT}/nc-sciencemesh-release"
