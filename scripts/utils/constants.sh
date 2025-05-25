#!/usr/bin/env bash

# Docker network name
DOCKER_NETWORK="testnet"
export DOCKER_NETWORK

# default to false if unset
: "${DEVSTOCK_DEBUG:=false}"
: "${NO_CLEANING:=false}"
export DEVSTOCK_DEBUG NO_CLEANING

# MariaDB root password
MARIADB_ROOT_PASSWORD="eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek"
export MARIADB_ROOT_PASSWORD

# Paths to required directories
TEMP_DIR="${ENV_ROOT}/temp"
TLS_CA_DIR="${ENV_ROOT}/docker/tls/certificate-authority"
TLS_CERT_DIR="${ENV_ROOT}/docker/tls/certificates"
DOCKER_CONFIGS_DIR="${ENV_ROOT}/docker/configs"
DOCKER_SCRIPTS_DIR="${ENV_ROOT}/docker/scripts"
export TEMP_DIR TLS_CA_DIR TLS_CERT_DIR DOCKER_CONFIGS_DIR DOCKER_SCRIPTS_DIR

# 3rd party containers
CYPRESS_REPO=pondersource/cypress
CYPRESS_TAG=latest
FIREFOX_REPO=jlesage/firefox
FIREFOX_TAG=v24.11.1
MARIADB_REPO=mariadb
MARIADB_TAG=11.4.4
MEMCACHED_REPO=memcached
MEMCACHED_TAG=1.6.18
VNC_REPO=theasp/novnc
VNC_TAG=latest

# Default script modes and platforms
DEFAULT_SCRIPT_MODE="dev"
DEFAULT_BROWSER_PLATFORM="electron"

# Export all constants
export CYPRESS_REPO CYPRESS_TAG FIREFOX_REPO FIREFOX_TAG
export MARIADB_REPO MARIADB_TAG MEMCACHED_REPO MEMCACHED_TAG 
export VNC_REPO VNC_TAG
export DEFAULT_SCRIPT_MODE DEFAULT_BROWSER_PLATFORM
