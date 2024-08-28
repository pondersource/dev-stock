#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e
rm 
sed -i "8 i\  1 => 'nc1.docker',"                           /var/www/html/config/config.php
sed -i "9 i\  2 => 'nc2.docker',"                           /var/www/html/config/config.php
sed -i "10 i\ 3 => 'nextcloud1.docker',"                    /var/www/html/config/config.php
sed -i "11 i\ 4 => 'nextcloud2.docker',"                    /var/www/html/config/config.php
sed -i "12 i\ 5 => 'nextcloud3.docker',"                    /var/www/html/config/config.php
sed -i "13 i\ 6 => 'nextcloud4.docker',"                    /var/www/html/config/config.php

# php console.php app:enable sciencemesh
