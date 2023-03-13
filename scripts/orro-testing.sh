#!/bin/bash
set -e

REPO_ROOT=$(pwd)
export REPO_ROOT=$REPO_ROOT
export EFSS1=oc
export EFSS2=oc
./scripts/sciencemesh-testing.sh
