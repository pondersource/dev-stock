#!/usr/bin/env bash


# fetch revad from source.
REPO_REVA=https://github.com/cs3org/reva
BRANCH_REVA=master

# reva source code.
[ ! -d "reva" ] &&                                          \
    git clone                                               \
    --branch=${BRANCH_REVA}                                 \
    ${REPO_REVA}                                            \
    reva

docker run -it                                              \
    --volume "$(pwd)/reva:/reva"                            \
    --workdir /reva                                         \
    pondersource/dev-stock-revad                            \
    /bin/bash -c "go mod vendor &&                          \
    git config --global --add safe.directory /reva  &&      \
    /bin/bash"
