#!/usr/bin/env sh
# This script is run as part of the .platform.app.yaml deployment step
# On dedicated generation 2 clusters, this should be setup by Platform.sh team as part of pre_start hook

set -e

echo "removing ${APP_CACHE_DIR}/var/cache/${APP_ENV}_*/*.*"
rm -Rf ${APP_CACHE_DIR}/var/cache/${APP_ENV}_*/*.*
php bin/console cache:clear

echo "clearing application cache"


echo "done executing pre_start cache clear"
