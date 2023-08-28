# dev-stock
Docker images we use in development.

# Note
If you do build on Codespaces, make sure you set `DOCKER_BUILDKIT=0` .

# EFSS versions
## Nextcloud version

upstream: [Nextcloud Server Official](https://github.com/nextcloud/server)

branch: [v27.0.0](https://github.com/nextcloud/server/releases/tag/v27.0.0)

## ownCloud version

upstream: [ownCloud Core Official](https://github.com/owncloud/core)

branch: [v10.13.0](https://github.com/owncloud/core/releases/tag/v10.13.0)

# Debugging
## RD-SRAM
See https://github.com/SURFnet/rd-sram-integration#testing-environment for up-to-date instructions.

## ScienceMesh
This was moved to https://github.com/cs3org/reva/tree/sciencemesh-testing/examples/sciencemesh .
It is now a Reva example and no longer part of dev-stock scripts, but it does still use Docker images from here.

## Trashbin
See https://github.com/pondersource/surf-trashbin-app

# Using XDebug
See https://github.com/pondersource/dev-stock/blob/main/docs/xdebug.md
