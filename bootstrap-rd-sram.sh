#!/usr/bin/env bash

./scripts/clean.sh

./init/rd-sram.sh

./tests/rd-sram.sh

docker exec -it owncloud2.docker sh /curls/includeMarie.sh owncloud2.docker

docker exec -it owncloud1.docker sh /curls/includeMarie.sh owncloud1.docker

docker exec -it owncloud1.docker sed -i "14 i\      3 => (isset(\$_SERVER['HTTP_HOST']) ? \$_SERVER['HTTP_HOST'] : 'localhost')," /var/www/html/config/config.php
docker exec -it owncloud2.docker sed -i "14 i\      3 => (isset(\$_SERVER['HTTP_HOST']) ? \$_SERVER['HTTP_HOST'] : 'localhost')," /var/www/html/config/config.php
