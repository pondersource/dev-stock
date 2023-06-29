#!/usr/bin/env bash

set -e

REPO_REVA=https://github.com/cs3org/reva
BRANCH_REVA=sciencemesh-testing

# Reva source code.
[ ! -d "reva" ] &&                                                              \
    git clone                                                                   \
    --branch ${BRANCH_REVA}                                                     \
    ${REPO_REVA}                                                                \
    reva                                                                        \
    &&                                                                          \
    cd reva                                                                     \
    &&                                                                          \
    go mod tidy                                                                 \
    &&                                                                          \
    go mod vendor                                                               \
    &&                                                                          \
    make revad                                                                  \
    &&                                                                          \
    cd ..

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet
