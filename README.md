# Development Stockpile (dev-stock)

Docker images we use in development.

# Open Cloud Mesh Test Suite

### Login Tests
| Test Name | Nextcloud v27.1.10 | Nextcloud v28.0.12 | oCIS v5.0.6 | OcmStub v1.0.0 | ownCloud v10.14.0 | Seafile v11.0.5 |
|-----------|--------------------|--------------------|-------------|----------------|-------------------|-----------------|
| Login     | [![OCM Test Login Nextcloud v27.1.10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-nextcloud-v27.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/login-nextcloud-v27.yml) | [![OCM Test Login Nextcloud v28.0.12](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-nextcloud-v28.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/login-nextcloud-v28.yml) | [![OCM Test Login oCIS v5.0.6](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-ocis-v5.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/login-ocis-v5.yml) | [![OCM Test Login OcmStub v1.0](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-ocmstub-v1.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/login-ocmstub-v1.yml) | [![OCM Test Login ownCloud v10.14.0](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-owncloud-v10.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/login-owncloud-v10.yml) | [![OCM Test Login Seafile v11.0.5](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/login-seafile-v11.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/login-seafile-v11.yml)

### Share With Tests
| Sender(R)/Receiver(C) | Nextcloud v27.1.10 | Nextcloud v28.0.12 | oCIS v5.0.6 | OcmStub v1.0.0 | ownCloud v10.14.0 | Seafile v11.0.5 |
|-----------------------|--------------------|--------------------|-------------|----------------|-------------------|-----------------|
| Nextcloud v27.1.10    | [![OCM Test Share With NC v27.1.10 to NC v27.1.10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v27-nc-v27.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v27-nc-v27.yml) | [![OCM Test Share With NC v27.1.10 to NC v28.0.12](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v27-nc-v28.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v27-nc-v28.yml) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square) | [![OCM Test Share With NC v27.1.10 to OC v10.14.0](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v27-oc-v10.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v27-oc-v10.yml) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) |
| Nextcloud v28.0.12    | [![OCM Test Share With NC v28.0.12 to NC v27.1.10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v28-nc-v27.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v28-nc-v27.yml) | [![OCM Test Share With NC v28.0.12 to NC v28.0.12](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v28-nc-v28.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v28-nc-v28.yml) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square) | [![OCM Test Share With NC v28.0.12 to OC v10.14.0](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-nc-v28-oc-v10.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-nc-v28-0c-v10.yml) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) |
| oCIS v5.0.6           | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) |
| OcmStub v1.0.0        | ![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square) | ![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square) | ![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) |
| ownCloud v10.14.0     | [![OCM Test Share With OC v10.14.0 to NC v27.1.10](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-oc-v10-nc-v27.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-oc-v10-nc-v27.yml) | [![OCM Test Share With OC v10.14.0 to NC v28.0.12](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-oc-v10-nc-v28.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-oc-v10-nc-v28.yml) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square)  | ![Possible](https://img.shields.io/badge/Possible-blue?style=flat-square) | [![OCM Test Share With OC v10.14.0 to OC v10.14.0](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-oc-v10-oc-v10.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-oc-v10-oc-v10.yml) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) |
| Seafile v11.0.5       | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | ![Impossible](https://img.shields.io/badge/Impossible-orange?style=flat-square) | [![OCM Test Share With SF v11.0.5 to SF v11.0.5](https://img.shields.io/github/actions/workflow/status/pondersource/dev-stock/share-with-sf-v11-sf-v11.yml?branch=matrix-ci-tests&style=flat-square&label=)](https://github.com/pondersource/dev-stock/actions/workflows/share-with-sf-v11-sf-v11.yml) |

# EFSS versions
## Nextcloud version

***tag: latest, v30.0.0***

upstream: [Nextcloud Server Official](https://github.com/nextcloud/server)

branch: [v30.0.0](https://github.com/nextcloud/server/releases/tag/v30.0.0)

***tag: v29.0.8***

upstream: [Nextcloud Server Official](https://github.com/nextcloud/server)

branch: [v29.0.8](https://github.com/nextcloud/server/releases/tag/v29.0.8)

***tag: v28.0.12***

upstream: [Nextcloud Server Official](https://github.com/nextcloud/server)

branch: [v28.0.12](https://github.com/nextcloud/server/releases/tag/v28.0.12)

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
