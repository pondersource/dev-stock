#!/bin/bash

./scripts/clean.sh

./scripts/init-rd-sram.sh

./scripts/testing-rd-sram.sh

docker exec -it oc2.docker sh /curls/includeMarie.sh oc2.docker

docker exec -it oc1.docker sh /curls/includeMarie.sh oc1.docker

# be aware that these optional command is going to break the occ command [https://github.com/SURFnet/rd-sram-integration/issues/237]

docker exec -it oc1.docker sed -i "14 i\      3 => (isset(\$_SERVER['HTTP_HOST']) ? \$_SERVER['HTTP_HOST'] : 'localhost')," /var/www/html/config/config.php
docker exec -it oc2.docker sed -i "14 i\      3 => (isset(\$_SERVER['HTTP_HOST']) ? \$_SERVER['HTTP_HOST'] : 'localhost')," /var/www/html/config/config.php
