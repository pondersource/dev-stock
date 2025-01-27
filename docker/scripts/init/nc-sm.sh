#!/usr/bin/env bash

ln -sf /ponder/apps/sciencemesh /var/html/www/apps/sciencemesh

php console.php app:enable --force sciencemesh
