#!/usr/bin/env bash

set -euo pipefail

# Set project root directory
CWD="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
export PROJECT_ROOT="${PROJECT_ROOT:-"$(dirname "$CWD")"}"
export ENV_FILE=${ENV_FILE:-"${PROJECT_ROOT}/.env"}

# Source functions
source "${PROJECT_ROOT}/bin/functions.sh"

# Load environment variables from .env file
load_dotenv "$ENV_FILE"

# Load current environment variables
curenv=$(declare -p -x)

# Restore environment variables set globally
set -o allexport
eval "$curenv"
set +o allexport

# Set default values for environment variables
export APP_URL
export APP_URL=${BACKEND_URL:-${APP_URL}}
export ESLINT_DISABLE
export PROXY_URL
export STOREFRONT_ASSETS_PORT
export STOREFRONT_PROXY_PORT
export STOREFRONT_ROOT="${STOREFRONT_ROOT:-"${PROJECT_ROOT}/vendor/shopware/storefront"}"

# Ensure BIN_TOOL is set and executable
get_bin_tool
# Dump features and compile theme if not skipped
[[ ${SHOPWARE_SKIP_FEATURE_DUMP:-""} ]] || "${BIN_TOOL}" feature:dump
[[ ${SHOPWARE_SKIP_THEME_COMPILE:-""} ]] || "${BIN_TOOL}" theme:compile --active-only
"${BIN_TOOL}" theme:dump

# Install webpack-dev-server if not present
[[ ! -d "${STOREFRONT_ROOT}"/Resources/app/storefront/node_modules/webpack-dev-server ]] && npm --prefix "${STOREFRONT_ROOT}"/Resources/app/storefront install --prefer-offline || true

# Install extensions npm dependencies
install_extensions_npm_dependencies "storefront"

# Run hot-proxy script
npm --prefix "${STOREFRONT_ROOT}"/Resources/app/storefront run-script hot-proxy
