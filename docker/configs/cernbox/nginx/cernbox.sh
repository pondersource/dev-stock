#!/usr/bin/env sh

file_path="/var/www/web/config.json"
original="your.nginx.org"
replacement="${CERNBOX}"

sed -i "s#${original}#${replacement}#g" "${file_path}"
