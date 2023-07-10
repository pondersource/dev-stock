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
```
./scripts/init-sciencemesh.sh
./tests/nrro.sh
./scripts/clean.sh
./tests/orro.sh
```

## Reva-to-reva
To initialize your development environment and build reva on the host, do:
```
./scripts/init-reva.sh
# passing sleep as the main container command will allow us
# to run revad interactively later:
REVA_CMD="sleep 30000" ./scripts/testing-reva.sh
docker exec -it revad1.docker bash
> cd /reva
> git config --global --add safe.directory /reva
> make revad
> make reva
```

### Running the ocmd tutorial
After you've run `make revad` and `make reva` once in one of the two containers as detailed above, you do:
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

### Running the datatx tutorial
After you've run `make revad` and `make reva` once in one of the two containers as detailed above, you do:
* `docker exec -it revad1.docker bash` and then:
```
cd /etc/revad/datatx
/reva/cmd/revad/revad -dev-dir server-1
```
* `docker exec -it revad2.docker bash` and then:
```
cd /etc/revad/datatx
/reva/cmd/revad/revad -dev-dir server-2
```
* `docker exec -it revad1.docker bash` again for `/reva/cmd/reva/reva -insecure -host localhost:19000` etc.
* `docker exec -it revad2.docker bash` again for `/reva/cmd/reva/reva -insecure -host localhost:17000` etc. (notice the port number!)
* get einstein to generate an invite, and marie to accept it, following the usual way as described in https://reva.link/docs/tutorials/share-tutorial/#4-invitation-workflow
* follow the rest of https://reva.link/docs/tutorials/datatx-tutorial/#3-create-a-datatx-protocol-type-ocm-share
