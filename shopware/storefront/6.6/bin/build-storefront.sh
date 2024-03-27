#!/usr/bin/env bash

set -euo pipefail

# Set project root directory
CWD="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
export PROJECT_ROOT="${PROJECT_ROOT:-"$(dirname "$CWD")"}"

# Source functions
source "${PROJECT_ROOT}/bin/functions.sh"

# Set npm configuration
export NPM_CONFIG_FUND=false
export NPM_CONFIG_AUDIT=false
export NPM_CONFIG_UPDATE_NOTIFIER=false

# Puppeteer and storefront configurations
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export STOREFRONT_ROOT="${STOREFRONT_ROOT:-"${PROJECT_ROOT}/vendor/shopware/storefront"}"

# Ensure BIN_TOOL is set and executable
get_bin_tool

# Dump bundles and features if not skipped
[[ ${SHOPWARE_SKIP_BUNDLE_DUMP:-""} ]] || "${BIN_TOOL}" bundle:dump
[[ ${SHOPWARE_SKIP_FEATURE_DUMP:-""} ]] || "${BIN_TOOL}" feature:dump

# Install storefront npm dependencies for extensions
install_extensions_npm_dependencies "storefront" "--prefer-offline"

# Install and build storefront
install_and_build_storefront

# Install assets if not skipped
[[ ${SHOPWARE_SKIP_ASSET_COPY:-""} ]] ||"${BIN_TOOL}" assets:install

# Compile theme if not skipped
[[ ${SHOPWARE_SKIP_THEME_COMPILE:-""} ]] || "${BIN_TOOL}" theme:compile --active-only

# Clear cache if not instructed otherwise
if ! [ "${1:-default}" = "--keep-cache" ]; then
    "${BIN_TOOL}" cache:clear
fi
