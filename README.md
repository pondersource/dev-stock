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

branch: [v10.12.2](https://github.com/owncloud/core/releases/tag/v10.12.2)

# Debugging
## RD-SRAM
```
./scripts/init-rd-sram.sh
./scripts/testing-rd-sram.sh
```

## ScienceMesh
Moved to https://github.com/cs3org/reva/tree/sciencemesh-testing/examples/sciencemesh