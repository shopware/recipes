#!/usr/bin/env sh
# This script is run as part of the .platform.app.yaml deployment step
# On dedicated generation 2 clusters, this should be setup by Platform.sh team as part of pre_start hook

set -e

echo "removing var/cache/${APP_ENV}_*/*.*"
rm -Rf var/cache/${APP_ENV}_*/*.*

echo "clearing application cache"
php bin/console cache:clear

echo "done executing pre_start cache clear"