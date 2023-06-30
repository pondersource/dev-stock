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
## RD-SRAM
```
./scripts/init-rd-sram.sh
./scripts/testing-rd-sram.sh
```

## ScienceMesh
```
./script/init-sciencemesh.sh
./tests/nrro.sh
./script/clean.sh
./tests/orro.sh
```

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

### Running the ocmd tutorial
After you've run `make revad` and `make reva` once in one of the two containers as detailed above, to build reva on the host,
You do:
* `docker exec -it revad1.docker bash` and then:
```
cd /etc/revad/ocmd
/reva/cmd/revad/revad -dev-dir server-1
```
* `docker exec -it revad2.docker bash` and then:
```
cd /etc/revad/ocmd
/reva/cmd/revad/revad -dev-dir server-2
```
* `docker exec -it revad1.docker bash` again for `/reva/cmd/reva/reva -insecure -host localhost:19000` etc.
* `docker exec -it revad2.docker bash` again for `/reva/cmd/reva/reva -insecure -host localhost:17000` etc. (notice the port number!)
* follow the rest of https://reva.link/docs/tutorials/share-tutorial/
