#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

php console.php maintenance:install --admin-user "$USER" --admin-pass "$PASS" --database "mysql"                \
                                    --database-name "efss" --database-user "root" --database-host "$DBHOST"     \
                                    --database-pass "eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek"
php console.php app:disable firstrunwizard

sed -i "8 i\      1 => 'nc1.docker'," /var/www/html/config/config.php
sed -i "9 i\      2 => 'nc2.docker'," /var/www/html/config/config.php
sed -i "3 i\  'allow_local_remote_servers' => true," config/config.php

php console.php app:enable solid

sed -i "109 i\  RewriteCond %{REQUEST_URI} \!^/\\\.well-known/openid-configuration" .htaccess
sed -i "72 i\  RewriteCond %{REQUEST_URI} \!^/\\\.well-known/openid-configuration" .htaccess
echo "<IfModule mod_headers.c>\n    Header set Access-Control-Allow-Origin \"*\"\n</IfModule>" >> .htaccess
mkdir -p .well-known
SERVER_ROOT_ESCAPED=$(printf '%s\n' "$SERVER_ROOT" | sed -e 's/[\/&]/\\&/g')
echo "{\"id_token_signing_alg_values_supported\":[\"RS256\"],\"response_types_supported\":[\"code\",\"code token\",\"code id_token\",\"id_token code\",\"id_token\",\"id_token token\",\"code id_token token\",\"none\"],\"subject_types_supported\":[\"public\"],\"issuer\":\"$SERVER_ROOT_ESCAPED\",\"authorization_endpoint\":\"$SERVER_ROOT_ESCAPED\/apps\/solid\/authorize\",\"jwks_uri\":\"$SERVER_ROOT_ESCAPED\/apps\/solid\/jwks\",\"response_modes_supported\":[\"query\",\"fragment\"],\"grant_types_supported\":[\"authorization_code\",\"implicit\",\"refresh_token\",\"client_credentials\"],\"token_endpoint_auth_methods_supported\":\"client_secret_basic\",\"token_endpoint_auth_signing_alg_values_supported\":[\"RS256\"],\"display_values_supported\":[],\"claim_types_supported\":[\"normal\"],\"claims_supported\":[],\"claims_parameter_supported\":false,\"request_parameter_supported\":true,\"request_uri_parameter_supported\":false,\"require_request_uri_registration\":false,\"token_endpoint\":\"$SERVER_ROOT_ESCAPED\/apps\/solid\/token\",\"userinfo_endpoint\":\"$SERVER_ROOT_ESCAPED\/apps\/solid\/userinfo\",\"registration_endpoint\":\"$SERVER_ROOT_ESCAPED\/apps\/solid\/register\"}" > .well-known/openid-configuration
sed -i "25 i\    1 => 'server'," config/config.php
echo configured