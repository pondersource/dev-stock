#!/usr/bin/env bashBRANCH_MFAZONES_APP

set -e

REPO_ROOT=$(pwd)

"${REPO_ROOT}/scripts/clean.sh"

# repositories and branches.
REPO_MFAZONES_APP=https://github.com/MahdiBaghbani/mfazones
BRANCH_MFAZONES_APP=test-release

[ ! -d "temp" ] && mkdir -p temp

# copy init file.
cp -f ./docker/scripts/init-nextcloud-mfa.sh ./temp/nc.sh

# Nextcloud mfazones source code.
[ ! -d "mfazones-release" ] &&                                                  \
    git clone                                                                   \
    --depth 1                                                                   \
    --branch ${BRANCH_MFAZONES_APP}                                             \
    ${REPO_MFAZONES_APP}                                                        \
    mfazones-release                                                            \
    &&                                                                          \
    docker run -it                                                              \
    -v "${REPO_ROOT}/mfazones-release:/var/www/html/apps/mfazones"              \
    --workdir /var/www/html/apps/mfazones                                       \
    pondersource/dev-stock-nextcloud                                            \
    make composer

"${REPO_ROOT}/release/tag-release.py" none none mfazones-release

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
  -v "${REPO_ROOT}/mfazones-release:/var/www/html/apps/mfazones"                \
  -v "${REPO_ROOT}/release/mfazones.key:/var/www/mfazones.key"                  \
  "pondersource/dev-stock-nextcloud"

docker exec --user root nc-release.docker bash -c "chown www-data:www-data -R /var/www/html/apps/mfazones && chown www-data:www-data /var/www/mfazones.key"
docker exec --user www-data nc-release.docker bash -c "cd /var/www/html/apps/mfazones                   \
                                                    &&                                                  \
                                                    mkdir -p build/mfazones                             \
                                                    &&                                                  \
                                                    rm -rf build/mfazones/*                             \
                                                    &&                                                  \
                                                    cp -r appinfo build/mfazones/                       \
                                                    &&                                                  \
                                                    cp -r css build/mfazones/                           \
                                                    &&                                                  \
                                                    cp -r img build/mfazones/                           \
                                                    &&                                                  \
                                                    cp -r js build/mfazones/                            \
                                                    &&                                                  \
                                                    cp -r lib build/mfazones/                           \
                                                    &&                                                  \
                                                    cp -r templates build/mfazones/                     \
                                                    &&                                                  \
                                                    cp -r composer.* build/mfazones/                    \
                                                    &&                                                  \
                                                    cd build/mfazones/                                  \
                                                    &&                                                  \
                                                    composer install                                    \
                                                    &&                                                  \
                                                    cd ..                                               \
                                                    &&                                                  \
                                                    tar -cf mfazones.tar mfazones"

echo "NextCloud Signature start:"
docker exec --user root nc-release.docker bash -c "cd /var/www/html/apps/mfazones/release               \
                                                    &&                                                  \
                                                    mv ../build/mfazones.tar .                          \
                                                    &&                                                  \
                                                    rm -f -- mfazones.tar.gz                            \
                                                    &&                                                  \
                                                    gzip mfazones.tar                                   \
                                                    &&                                                  \
                                                    openssl dgst                                        \
                                                    -sha512                                             \
                                                    -sign /var/www/mfazones.key                         \
                                                    ./mfazones.tar.gz | openssl base64"
echo "NextCloud Signature end"

"${REPO_ROOT}/scripts/clean.sh"

# clear contents of mfazones key.
sudo chown gitpod:gitpod "${REPO_ROOT}/release/mfazones.key"
truncate -s 0 "${REPO_ROOT}/release/mfazones.key"

# add new tar.gz to git and push.
sudo chown gitpod:gitpod -R "${REPO_ROOT}/mfazones-release"
cd "${REPO_ROOT}/mfazones-release"
git add "${REPO_ROOT}/mfazones-release/release/mfazones.tar.gz"
git commit -m "Update release tarball of the application"
git push origin

# remove the release folder.
cd "${REPO_ROOT}"
sudo rm -rf "${REPO_ROOT}/mfazones-release"
