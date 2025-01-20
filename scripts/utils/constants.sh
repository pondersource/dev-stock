#!/usr/bin/env bash

# Docker network name
DOCKER_NETWORK="testnet"
export DOCKER_NETWORK

# MariaDB root password
MARIADB_ROOT_PASSWORD="eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek"
export MARIADB_ROOT_PASSWORD

# Paths to required directories
TEMP_DIR="temp"
TLS_CA_DIR="docker/tls/certificate-authority"
TLS_CERTIFICATES_DIR="docker/tls/certificates"
export TEMP_DIR TLS_CA_DIR TLS_CERTIFICATES_DIR

# 3rd party containers
CYPRESS_REPO=cypress/included
CYPRESS_TAG=13.13.1
FIREFOX_REPO=jlesage/firefox
FIREFOX_TAG=v24.11.1
MARIADB_REPO=mariadb
MARIADB_TAG=11.4.4
VNC_REPO=theasp/novnc
VNC_TAG=latest

# Export the constants
export CYPRESS_REPO CYPRESS_TAG FIREFOX_REPO FIREFOX_TAG
export MARIADB_REPO MARIADB_TAG VNC_REPO VNC_TAG
