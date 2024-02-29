#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

php console.php maintenance:install --admin-user "$USER" --admin-pass "$PASS" --database "mysql"                \
                                    --database-name "efss" --database-user "root" --database-host "$DBHOST"     \
                                    --database-pass "eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek"
php console.php app:disable firstrunwizard

# change/add lines in config.php
sed -i "3 i\  'allow_local_remote_servers' => true,"        /var/www/html/config/config.php
sed -i "8 i\  1 => 'nc1.docker',"                           /var/www/html/config/config.php
sed -i "9 i\  2 => 'nc2.docker',"                           /var/www/html/config/config.php
sed -i "10 i\ 3 => 'nextcloud1.docker',"                    /var/www/html/config/config.php
sed -i "11 i\ 4 => 'nextcloud2.docker',"                    /var/www/html/config/config.php

php console.php app:enable user_saml
# php console.php app:enable mfachecker
php console.php app:enable files_accesscontrol
php console.php app:enable mfazones
# php console.php app:enable twofactor_totp
