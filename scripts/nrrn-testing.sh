#!/bin/bash
set -e

export REPO_ROOT=`pwd`
export EFSS1=nc
export EFSS2=nc
./scripts/sciencemesh-testing.sh
