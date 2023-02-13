#!/bin/bash
set -e

export REPO_ROOT=`pwd`
export EFSS1=nc1
export EFSS2=oc2
export DB1=nextcloud
export DB2=owncloud
./scripts/sciencemesh-testing.sh
