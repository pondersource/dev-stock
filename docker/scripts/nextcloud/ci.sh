#!/bin/bash
set -euo pipefail

# This script clones a specific commit from a Nextcloud repository
# It's designed to be used in CI environments where we want to test
# the exact commit that triggered the pipeline

# Environment variables that should be provided:
# NEXTCLOUD_REPO_URL - The URL of the Nextcloud repository to clone
# NEXTCLOUD_BRANCH - The branch to clone (optional, defaults to main)
# NEXTCLOUD_COMMIT_HASH - The specific commit hash to checkout

echo "Starting CI-specific Nextcloud clone..."

if [ -z "${NEXTCLOUD_REPO_URL:-}" ]; then
    echo "Error: NEXTCLOUD_REPO_URL environment variable is not set. Aborting."
    exit 1
fi
if [ -z "${NEXTCLOUD_COMMIT_HASH:-}" ]; then
    echo "Error: NEXTCLOUD_COMMIT_HASH environment variable is not set. Aborting."
    exit 1
fi

NEXTCLOUD_BRANCH=${NEXTCLOUD_BRANCH:-main}

# @MahdiBaghbani: it is already installed in the base image, but we need to be sure.
echo "Installing git for cloning..."
apt-get update
apt-get install -y git

echo "Cloning Nextcloud repository..."
echo "Repository: ${NEXTCLOUD_REPO_URL}"
echo "Branch: ${NEXTCLOUD_BRANCH}"
echo "Commit: ${NEXTCLOUD_COMMIT_HASH}"

if [ -d "/usr/src/nextcloud" ]; then
    echo "Removing existing Nextcloud directory..."
    rm -rf /usr/src/nextcloud
fi
git clone --depth 1 --recursive --shallow-submodules --branch "${NEXTCLOUD_BRANCH}" "${NEXTCLOUD_REPO_URL}" /usr/src/nextcloud

cd /usr/src/nextcloud

git fetch --depth=1 origin "${NEXTCLOUD_COMMIT_HASH}"
git checkout "${NEXTCLOUD_COMMIT_HASH}"

rm -rf /usr/src/nextcloud/.git
mkdir -p /usr/src/nextcloud/data
mkdir -p /usr/src/nextcloud/custom_apps
chmod +x /usr/src/nextcloud/occ

echo "Removing git..."
apt-get purge -y git
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Nextcloud clone completed successfully."
