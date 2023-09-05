#!/usr/bin/env bash

set -e

REPO_ROOT=$(pwd)
export REPO_ROOT=$REPO_ROOT
export EFSS1=nextcloud
export EFSS2=nextcloud
"${REPO_ROOT}/tests/sciencemesh.sh"