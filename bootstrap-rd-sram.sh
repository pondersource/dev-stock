#!/bin/bash

./scripts/clean.sh

./scripts/init-rd-sram.sh

./scripts/testing-rd-sram.sh

docker exec -it oc2.docker sh /curls/includeMarie.sh oc2.docker

docker exec -it oc1.docker sh /curls/includeMarie.sh oc1.docker

docker exec -it oc1.docker sed -i "14 i\      3 => (isset(\$_SERVER['HTTP_HOST']) ? \$_SERVER['HTTP_HOST'] : 'localhost')," /var/www/html/config/config.php
docker exec -it oc2.docker sed -i "14 i\      3 => (isset(\$_SERVER['HTTP_HOST']) ? \$_SERVER['HTTP_HOST'] : 'localhost')," /var/www/html/config/config.php
