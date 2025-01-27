#!/usr/bin/env bash

ln -sf /ponder/apps/sciencemesh /var/www/html/apps/sciencemesh

php console.php app:enable --force sciencemesh
