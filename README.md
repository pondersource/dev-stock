# dev-stock
[![Open Cloud Mesh Test Suite](https://github.com/pondersource/dev-stock/actions/workflows/ocm-test-suite.yml/badge.svg)](https://github.com/pondersource/dev-stock/actions/workflows/ocm-test-suite.yml)

Docker images we use in development.

# EFSS versions
## Nextcloud version

***tag: latest, v28.0.7***

upstream: [Nextcloud Server Official](https://github.com/nextcloud/server)

branch: [v28.0.7](https://github.com/nextcloud/server/releases/tag/v28.0.7)

***tag: v27.1.10***

upstream: [Nextcloud Server Official](https://github.com/nextcloud/server)

branch: [v27.1.10](https://github.com/nextcloud/server/releases/tag/v27.1.10)

## ownCloud version

upstream: [ownCloud Core Official](https://github.com/owncloud/core)

branch: [v10.14.0](https://github.com/owncloud/core/releases/tag/v10.14.0)

# OCM Test Suite
Run specific tests with this command syntax.
1. test scenario: login. share-with, invite-link, share-link
2. platform 1: ocis, nextcloud, owncloud, seafile
3. run mode: dev, ci
4. cypress runner: electron, chrome, firefox, edge

```bash
./dev/ocm-test-suite.sh [test scenario] [platform 1] [platform 1 version] [run mode] [cypress runner] [platform 2] [platform 2 version]
```

example:
```bash
./dev/ocm-test-suite.sh share-with nextcloud v27.1.10 ci electron nextcloud v27.1.10
```

# Debugging
## RD-SRAM

See https://github.com/SURFnet/rd-sram-integration#testing-environment for up-to-date instructions.

## ScienceMesh

This was moved to https://github.com/cs3org/reva/tree/sciencemesh-testing/examples/sciencemesh .

The scripts for ScienceMesh still exist here but are not guaranteed to work as expected.

### Reva version

upstream: [Reva](https://github.com/cs3org/reva)

branch: [v1.28.0](https://github.com/owncloud/core/releases/tag/v1.28.0)

## Trashbin

See https://github.com/pondersource/surf-trashbin-app

# Using XDebug

See [docs](./docs/xdebug.md)

# SOLID RemoteStorage
for development see [docs](./docs/solid-remotestorage.md)
