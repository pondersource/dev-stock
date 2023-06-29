# dev-stock
Docker images we use in development.

# Note
If you do build on Codespaces, make sure you set `DOCKER_BUILDKIT=0` .

# EFSS versions
## Nextcloud version

upstream: [Nextcloud Server Official](https://github.com/nextcloud/server)

branch: [v26.0.1](https://github.com/nextcloud/server/releases/tag/v26.0.1)

## ownCloud version

upstream: [ownCloud Core Official](https://github.com/owncloud/core)

branch: [v10.12.2](https://github.com/owncloud/core/releases/tag/v10.12.2)

# Debugging
## Reva-to-reva
```
./scripts/init-reva.sh
REVA_CMD="sleep 30000" ./scripts/testing-reva.sh
docker exec -it revad1.docker bash
> cd /reva
> git config --global --add safe.directory /reva
> make revad
> make reva
```
Then follow e.g. https://reva.link/docs/tutorials/datatx-tutorial/