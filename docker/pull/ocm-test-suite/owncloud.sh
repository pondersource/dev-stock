#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# 3rd party images.
docker pull mariadb:11.4.2
docker pull cypress/included:13.13.1

# dev-stock images.
docker pull pondersource/dev-stock-owncloud-ocm-test-suite:latest
