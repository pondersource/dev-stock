#!/usr/bin/env bash

set -e

REPO_ROOT=$(pwd)
export REPO_ROOT=$REPO_ROOT
export EFSS1=oc
export EFSS2=oc
"${REPO_ROOT}/scripts/testing-sciencemesh.sh"
