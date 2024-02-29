#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

# create symbolic link if it doesn't exists.
if [[ ! -d "/var/www/html/apps/federatedgroups" ]]; then
    ln --symbolic --force /var/www/html/apps/rd-sram-integration/federatedgroups /var/www/html/apps/federatedgroups
fi

php console.php maintenance:install --admin-user "${USER}" --admin-pass "${PASS}" --database "mysql"            \
                                    --database-name "efss" --database-user "root" --database-host "$DBHOST"     \
                                    --database-pass "eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek"
php console.php app:disable firstrunwizard

# change/add lines in config.php
sed -i "8 i\    1 => 'oc1.docker',"                                                             /var/www/html/config/config.php
sed -i "9 i\    2 => 'oc2.docker',"                                                             /var/www/html/config/config.php
sed -i "10 i\    3 => 'owncloud1.docker',"                                                      /var/www/html/config/config.php
sed -i "11 i\    4 => 'owncloud2.docker',"                                                      /var/www/html/config/config.php
sed -i "12 i\    5 => (isset(\$_SERVER['HTTP_HOST']) ? \$_SERVER['HTTP_HOST'] : 'localhost'),"  /var/www/html/config/config.php

echo "Installing Custom Groups"
php console.php app:enable customgroups

echo "Installing OpenCloudMesh"
php console.php app:enable opencloudmesh

echo "Installing Federated Groups"
php console.php app:enable federatedgroups

echo "Editing Config"
sed -i "3 i\  'sharing.managerFactory' => 'OCA\\\\FederatedGroups\\\\ShareProviderFactory'," /var/www/html/config/config.php
sed -i "4 i\  'sharing.remoteShareesSearch' => 'OCA\\\\OpenCloudMesh\\\\ShareeSearchPlugin'," /var/www/html/config/config.php
sed -i "5 i\  'sharing.ocmController' => 'OCA\\\\OpenCloudMesh\\\\Controller\\\\OcmController'," /var/www/html/config/config.php
sed -i "6 i\  'sharing.groupExternalManager' => 'OCA\\\\OpenCloudMesh\\\\GroupExternalManager'," /var/www/html/config/config.php
