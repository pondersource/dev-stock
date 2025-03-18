# Incomplete Documentation
# TODO @MahdiBaghbani: I have started writing this documentation but it is not complete yet.
# TODO @MahdiBaghbani: I will complete it when I have time.

# OCM Test Suite

This directory contains test scripts for Open Cloud Mesh (OCM) functionality across different EFSS platforms.

## Overview

The OCM Test Suite allows you to test OCM functionality between different platforms and versions, including:

- Login tests
- Share-with tests
- Share-link tests
- Invite-link tests

## Using the nextcloud-ci Docker Image

The test suite now supports using the `pondersource/nextcloud-ci` Docker image, which allows you to test against any specific commit of Nextcloud, not just pre-built versioned images.

### Benefits of Using the CI Image

- Test against any arbitrary commit, not just released versions
- Simplify maintenance by using a single image for all versions
- Enable testing against unreleased features or specific bug fixes
- Ensure consistent testing environment across all versions

### How to Use the CI Image

1. Set the `USE_CI_IMAGE` environment variable to `true`
2. Provide the repository URL, branch, and commit hash via environment variables

Example:

```bash
# For testing a specific commit
export USE_CI_IMAGE=true
export SENDER_ENV="-e NEXTCLOUD_REPO_URL=https://github.com/nextcloud/server -e NEXTCLOUD_BRANCH=master -e NEXTCLOUD_COMMIT_HASH=abcdef1234567890"
export RECEIVER_ENV="-e NEXTCLOUD_REPO_URL=https://github.com/nextcloud/server -e NEXTCLOUD_BRANCH=v30.0.2 -e NEXTCLOUD_COMMIT_HASH=v30.0.2"

# Run the test
./ocm-test-suite.sh share-with nextcloud current ci electron nextcloud v30.0.2
```

## Running Tests

### Basic Usage

```bash
./ocm-test-suite.sh [TEST_CASE] [PLATFORM_1] [VERSION_1] [MODE] [BROWSER] [PLATFORM_2] [VERSION_2]
```

### Arguments

- `TEST_CASE`: The test case to run (login, share-with, share-link, invite-link)
- `PLATFORM_1`: The first platform (nextcloud, owncloud, seafile)
- `VERSION_1`: The version of the first platform (e.g., v30.0.2, current)
- `MODE`: The mode to run in (dev, ci)
- `BROWSER`: The browser to use for tests (electron, chrome, firefox, edge)
- `PLATFORM_2`: The second platform (for interop tests)
- `VERSION_2`: The version of the second platform

### Examples

```bash
# Test login on Nextcloud v30.0.2
./ocm-test-suite.sh login nextcloud v30.0.2 dev electron

# Test share-with between Nextcloud v30.0.2 and v29.0.10
./ocm-test-suite.sh share-with nextcloud v30.0.2 dev electron nextcloud v29.0.10

# Test share-link between current code and Nextcloud v30.0.2
./ocm-test-suite.sh share-link nextcloud current dev electron nextcloud v30.0.2
```

## GitHub Actions Integration

The OCM test suite is integrated with GitHub Actions to automatically test OCM functionality on pull requests and pushes to the master branch. The workflow uses the nextcloud-ci Docker image to test the current code against various stable Nextcloud versions.

See `.github/workflows/integration-ocm.yml` for the full workflow configuration. 