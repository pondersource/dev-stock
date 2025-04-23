#!/bin/bash
set -euo pipefail

# This script clones a specific commit from a Nextcloud repository
# It's designed to be used in CI environments where we want to test
# the exact commit that triggered the pipeline

# Environment variables that should be provided:
# NEXTCLOUD_REPO_URL - The URL of the Nextcloud repository to clone
# NEXTCLOUD_COMMIT_HASH - The specific commit hash to checkout
# NEXTCLOUD_TAG - the specific tag to checkout
echo "Starting CI-specific Nextcloud clone..."

# Clone Nextcloud by:
#   repo + commit hash              (NEXTCLOUD_COMMIT_HASH)
#   repo + tag                      (NEXTCLOUD_TAG)
#
# Exactly one of NEXTCLOUD_COMMIT_HASH or NEXTCLOUD_TAG must be provided.
: "${NEXTCLOUD_REPO_URL:?NEXTCLOUD_REPO_URL is required}"

# Validate mutually‑exclusive options
if [[ -n "${NEXTCLOUD_COMMIT_HASH:-}" && -n "${NEXTCLOUD_TAG:-}" ]]; then
    echo "Error: provide either NEXTCLOUD_COMMIT_HASH or NEXTCLOUD_TAG, not both." >&2
    exit 1
fi
if [[ -z "${NEXTCLOUD_COMMIT_HASH:-}" && -z "${NEXTCLOUD_TAG:-}" ]]; then
    echo "Error: you must set NEXTCLOUD_COMMIT_HASH or NEXTCLOUD_TAG." >&2
    exit 1
fi

# @MahdiBaghbani: it is already installed in the base image, but we need to be sure.
# Ensure git is present (base image may already have it)
if ! command -v git &>/dev/null; then
    echo "Installing git…"
    apt-get update -qq && apt-get install -y --no-install-recommends git
fi

DEST=/usr/src/nextcloud
rm -rf "${DEST}"

# Clone Nextcloud source – tag or detached commit, always with sub-modules
if [[ -n ${NEXTCLOUD_TAG:-} ]]; then
    echo "Cloning ${NEXTCLOUD_REPO_URL} @ tag ${NEXTCLOUD_TAG} …"
    git clone \
      --branch  "${NEXTCLOUD_TAG}" \
      --depth   1 \
      --recurse-submodules --shallow-submodules \
      "${NEXTCLOUD_REPO_URL}"  "${DEST}"

else
    echo "Cloning ${NEXTCLOUD_REPO_URL} @ commit ${NEXTCLOUD_COMMIT_HASH} …"
    git init -q "${DEST}"
    cd       "${DEST}"

    git remote add origin "${NEXTCLOUD_REPO_URL}"
    # Fetch exactly the one commit and whatever its sub-module SHAs point to
    git fetch -q --depth 1 origin "${NEXTCLOUD_COMMIT_HASH}"
    git checkout -q        "${NEXTCLOUD_COMMIT_HASH}"

    # Bring in sub-modules at the versions recorded in that commit, shallowly.
    git submodule update --init --recursive --depth 1
fi

# Clean‑up & prepare runtime dirs
rm -rf "${DEST}/.git"
mkdir -p "${DEST}/data" "${DEST}/custom_apps"
chmod +x "${DEST}/occ"

echo "Removing git..."
apt-get purge -y git
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Nextcloud clone completed successfully."
