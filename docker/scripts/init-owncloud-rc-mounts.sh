#!/usr/bin/env bash

# create symbolic link (by force)
ln --symbolic --force /var/www/html/apps/rc-mounts/tokenbasedav /var/www/html/apps/tokenbasedav

php console.php maintenance:install --admin-user "${USER}" --admin-pass "${PASS}" --database "mysql"            \
                                    --database-name "efss" --database-user "root" --database-host "$DBHOST"     \
                                    --database-pass "eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek"
php console.php app:disable firstrunwizard

sed -i "8 i\      1 => 'oc1.docker'," /var/www/html/config/config.php
sed -i "9 i\      2 => 'oc2.docker'," /var/www/html/config/config.php

# insert redis cache details into config.php
cat <<EOT >> /var/www/html/config/config.php
'filelocking.enabled' => true,
'memcache.locking' => '\OC\Memcache\Redis',
'memcache.local' => '\OC\Memcache\Redis',
'memcache.distributed' => '\OC\Memcache\Redis',
'redis' => [
    'host' => '${REDIS_HOST}',  // For a Unix domain socket, use '/var/run/redis/redis.sock'
    'port' => 6379,         // Set to 0 when using a Unix socket
    'timeout' => 0,         // Optional, keep connection open forever
    'password' => '',       // Optional, if not defined no password will be used.
    'dbindex' => 0,         // Optional, if undefined SELECT will not run and will
                            // use Redis Server's default DB Index.
],
EOT

echo "Installing DAV Token Access"
php console.php app:enable tokenbasedav

echo "Installing Open ID Connect"
cd make /var/www/html/apps/openidconnect && make install-php-deps
cd /var/www/html && php console.php app:enable openidconnect
