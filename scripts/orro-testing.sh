#!/bin/bash
set -e

export REPO_ROOT=`pwd`
export EFSS1=oc
export EFSS2=oc
./scripts/sciencemesh-testing.sh
