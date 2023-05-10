php console.php maintenance:install --admin-user $USER --admin-pass $PASS --database "mysql" --database-name "efss" --database-user "root" --database-pass "eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek" --database-host "$DBHOST"
php console.php app:disable firstrunwizard
sed -i "8 i\      1 => 'oc1.docker'," /var/www/html/config/config.php
sed -i "9 i\      2 => 'oc2.docker'," /var/www/html/config/config.php


echo Installing Custom Groups
php console.php app:enable customgroups
echo Installing Federated Groups
php console.php app:enable federatedgroups
echo Installing OpenCloudMesh
php console.php app:enable opencloudmesh
echo Editing Config
sed -i "3 i\  'sharing.managerFactory' => 'OCA\\\\FederatedGroups\\\\ShareProviderFactory'," /var/www/html/config/config.php
sed -i "4 i\  'sharing.remoteShareesSearch' => 'OCA\\\\OpenCloudMesh\\\\ShareeSearchPlugin'," /var/www/html/config/config.php
sed -i "5 i\  'sharing.ocmController' => 'OCA\\\\OpenCloudMesh\\\\Controller\\\\OcmController'," /var/www/html/config/config.php
sed -i "6 i\  'sharing.groupExternalManager' => 'OCA\\\\OpenCloudMesh\\\\GroupExternalManager'," /var/www/html/config/config.php
