#!/usr/bin/env bash

set -e

REPO_ROOT=$(pwd)
export REPO_ROOT=$REPO_ROOT
export EFSS1=nc
export EFSS2=oc
./scripts/beta-sciencemesh-testing.sh