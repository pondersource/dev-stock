#!/usr/bin/env bash

# create symbolic link if it doesn't exists.
if [[ ! -d "/var/www/html/apps/surf_trashbin" ]]; then
    ln --symbolic --force /var/www/html/apps/surf-trashbin-app/surf_trashbin /var/www/html/apps/surf_trashbin
fi

php console.php maintenance:install --admin-user "${USER}" --admin-pass "${PASS}" --database "mysql"            \
                                    --database-name "efss" --database-user "root" --database-host "$DBHOST"     \
                                    --database-pass "eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek"

php console.php app:disable firstrunwizard

sed -i "8 i\    1 => 'oc1.docker'," /var/www/html/config/config.php
sed -i "9 i\    2 => 'oc2.docker'," /var/www/html/config/config.php

echo "Installing SURF Trashbin"
php console.php app:enable surf_trashbin
