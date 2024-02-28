#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e
# create symbolic link if it doesn't exists.
if [[ ! -d "/var/www/html/apps/tokenbaseddav" ]]; then
    ln --symbolic --force /var/www/html/apps/token-based-access/tokenbaseddav /var/www/html/apps/tokenbaseddav
fi

php console.php maintenance:install --admin-user "${USER}" --admin-pass "${PASS}" --database "mysql"            \
                                    --database-name "efss" --database-user "root" --database-host "$DBHOST"     \
                                    --database-pass "eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek"

php console.php app:disable firstrunwizard

# change/add lines in config.php
sed -i "8 i\  1 => 'oc1.docker',"                                       /var/www/html/config/config.php
sed -i "9 i\  2 => 'oc2.docker',"                                       /var/www/html/config/config.php
sed -i "10 i\ 3 => 'owncloud1.docker',"                                 /var/www/html/config/config.php
sed -i "11 i\ 4 => 'owncloud2.docker',"                                 /var/www/html/config/config.php

# insert redis cache details into config.php
sed -i "42 i\  'filelocking.enabled' => true,"                          /var/www/html/config/config.php
sed -i "43 i\  'memcache.locking' => '\\OC\\Memcache\\Redis',"          /var/www/html/config/config.php
sed -i "44 i\  'memcache.local' => '\\OC\\Memcache\\Redis',"            /var/www/html/config/config.php
sed -i "45 i\  'memcache.distributed' => '\\OC\\Memcache\\Redis',"      /var/www/html/config/config.php
sed -i "46 i\  'redis' => ["                                            /var/www/html/config/config.php
sed -i "47 i\      'host' => '${REDIS_HOST}',"                          /var/www/html/config/config.php
sed -i "48 i\      'port' => 6379,"                                     /var/www/html/config/config.php
sed -i "49 i\      'timeout' => 0,"                                     /var/www/html/config/config.php
sed -i "50 i\      'password' => '',"                                   /var/www/html/config/config.php
sed -i "51 i\      'dbindex' => 0,"                                     /var/www/html/config/config.php
sed -i "52 i\  ],"                                                      /var/www/html/config/config.php

# some how above command doesn't have the corrct backslash escaping and we have to do it again! 
sed -i 's/OCMemcacheRedis/\\OC\\Memcache\\Redis/g' /var/www/html/config/config.php

echo "Installing Token Based Access"
php console.php app:enable tokenbaseddav
