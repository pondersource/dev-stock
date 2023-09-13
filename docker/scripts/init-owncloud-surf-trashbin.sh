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

mysql_cmd="mysql -h $DBHOST -u root --password=eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek efss"

###########################
# create user and set quota
create_user() {
    user=$1
    group=$2
    quota=$3
    OC_PASS=$user php console.php user:add --password-from-env $user --group $group
    if [ ! -z "$quota" ]
    then
        echo "UPDATE oc_accounts  SET quota='0 B' WHERE user_id='$user'"  | $mysql_cmd
    fi
}

share_folder_group() {
    f_user=$1
    f_pass=$2
    group=$3

    # get file id of shared folder
    fileid=$( ( echo "SELECT oc_filecache.fileid FROM oc_storages, oc_filecache "
                echo "WHERE id ='home::$f_user' AND "
                echo "oc_filecache.storage=oc_storages.numeric_id AND "
                echo "oc_filecache.path = 'files/shared'" ) | \
                  $mysql_cmd --skip-column-names )
    # share file
    ( echo "INSERT INTO oc_share "
      echo "SET share_type=1, share_with='$group', uid_owner='$f_user', uid_initiator='$f_user',"
      echo "item_type='folder', item_source=$fileid, file_source=$fileid,"
      echo "file_target='/${group}_shared', permissions=31" ) | \
        $mysql_cmd
}

share_folder_user() {
    f_user=$1
    f_pass=$2
    s_user=$3

    # get file id of shared folder
    fileid=$( ( echo "SELECT oc_filecache.fileid FROM oc_storages, oc_filecache "
                echo "WHERE id ='home::$f_user' AND "
                echo "oc_filecache.storage=oc_storages.numeric_id AND "
                echo "oc_filecache.path = 'files/shared'" ) | \
                  $mysql_cmd --skip-column-names )
    # share file
    ( echo "INSERT INTO oc_share "
      echo "SET share_type=0, share_with='$s_user', uid_owner='$f_user', uid_initiator='$f_user',"
      echo "item_type='folder', item_source=$fileid, file_source=$fileid,"
      echo "file_target='/${f_user}_shared', permissions=31" ) | \
        $mysql_cmd
}

# Create research groups and functional accounts
for group in bioinformatics astrophysics biochemistry
do
    f_user=f_$group
    f_pass=$f_user
    php console.php group:add $group
    OC_PASS=$f_pass php console.php user:add --password-from-env $f_user --group $group
    echo "INSERT INTO oc_group_admin SET gid='$group', uid='$f_user';" | $mysql_cmd

    # create shared folder
    curl --insecure -u $f_user:$f_pass -X MKCOL "https://$HOST.docker/remote.php/dav/files/$f_user/shared"

    #share_folder_group $f_user $f_pass $group
done

####################################
#
# Create researchers in each group
#
####################################

# bioinformatics
for i in jennifer katharine
do
    create_user $i bioinformatics "0 B"

    f_user=f_bioinformatics
    f_pass=$f_user
    share_folder_user $f_user $f_pass $i
done

# astrophysics
for i in jolynn deanne
do
    create_user $i astrophysics "0 B"

    f_user=f_astrophysics
    f_pass=$f_user
    share_folder_user $f_user $f_pass $i
done

# biochemistry
for i in lucretia sherrie
do
    create_user $i biochemistry "0 B"

    f_user=f_biochemistry
    f_pass=$f_user
    share_folder_user $f_user $f_pass $i
done


# biochemistry
for i in jennifer
do
    f_user=f_biochemistry
    f_pass=$f_user
    share_folder_user $f_user $f_pass $i
done


# many trashbins for jennifer, to test https://github.com/pondersource/surf-trashbin-app/issues/5
for group in one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty
do
    f_user=f_$group
    f_pass=$f_user
    echo Creating group $group $f_user $f_pass
    php console.php group:add $group
    OC_PASS=$f_pass php console.php user:add --password-from-env $f_user --group $group
    echo "INSERT INTO oc_group_admin SET gid='$group', uid='$f_user';" | $mysql_cmd

    echo Creating shared folder $HOST $f_user
    curl --insecure -u $f_user:$f_pass -X MKCOL "https://$HOST.docker/remote.php/dav/files/$f_user/shared"

   echo share_folder_user $f_user $f_pass jennifer
    share_folder_user $f_user $f_pass jennifer
done

echo Sleeping for 5 seconds to make sure accounts are created
sleep 5
# for testing display names
echo "UPDATE oc_accounts SET display_name = CONCAT('Display ', user_id)"  | $mysql_cmd
