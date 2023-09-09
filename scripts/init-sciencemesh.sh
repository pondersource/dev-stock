#!/usr/bin/env bash

set -e

# repositories and branches.
REPO_NEXTCLOUD_APP=https://github.com/sciencemesh/nc-sciencemesh
BRANCH_NEXTCLOUD_APP=nextcloud

REPO_NEXTCLOUD=https://github.com/nextcloud/server.git
BRANCH_NEXTCLOUD=fix/noid/ocm-controller

REPO_OWNCLOUD=https://github.com/owncloud/core
BRANCH_OWNCLOUD=v10.13.0

REPO_OWNCLOUD_APP=https://github.com/sciencemesh/nc-sciencemesh
BRANCH_OWNCLOUD_APP=owncloud

# Nextcloud source code.
[ ! -d "nextcloud" ] &&                                                         \
    git clone                                                                   \
    --depth 1                                                                   \
    --branch ${BRANCH_NEXTCLOUD}                                                \
    ${REPO_NEXTCLOUD}                                                           \
    nextcloud

# Nextcloud Sciencemesh source code.
[ ! -d "nextcloud-sciencemesh" ] &&                                             \
    git clone                                                                   \
    --branch ${BRANCH_NEXTCLOUD_APP}                                            \
    ${REPO_NEXTCLOUD_APP}                                                       \
    nextcloud-sciencemesh                                                       \
    &&                                                                          \
    docker run -it                                                              \
    -v "$(pwd)/nextcloud-sciencemesh:/var/www/html/apps/sciencemesh"            \
    --workdir /var/www/html/apps/sciencemesh                                    \
    pondersource/dev-stock-nextcloud-sciencemesh                                \
    make composer

# ownCloud source code.
[ ! -d "owncloud" ] &&                                                          \
    git clone                                                                   \
    --depth 1                                                                   \
    --branch ${BRANCH_OWNCLOUD}                                                 \
    ${REPO_OWNCLOUD}                                                            \
    owncloud

# ownCloud Sciencemesh source code.
[ ! -d "owncloud-sciencemesh" ] &&                                              \
    git clone                                                                   \
    --branch ${BRANCH_OWNCLOUD_APP}                                             \
    ${REPO_OWNCLOUD_APP}                                                        \
    owncloud-sciencemesh                                                        \
    &&                                                                          \
    docker run -it                                                              \
    -v "$(pwd)/owncloud-sciencemesh:/var/www/html/apps/sciencemesh"             \
    --workdir /var/www/html/apps/sciencemesh                                    \
    pondersource/dev-stock-owncloud-sciencemesh                                 \
    composer install

# move app to its place inside efss and create symbolic links
[ ! -d "nextcloud/apps/sciencemesh" ] &&                                        \
    mv nextcloud-sciencemesh nextcloud/apps/sciencemesh                         \
    &&                                                                          \
    ln -s nextcloud/apps/sciencemesh nextcloud-sciencemesh

[ ! -d "owncloud/apps/sciencemesh" ] &&                                         \
    mv owncloud-sciencemesh owncloud/apps/sciencemesh                           \
    &&                                                                          \
    ln -s owncloud/apps/sciencemesh owncloud-sciencemesh
