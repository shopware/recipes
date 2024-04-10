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
export ESLINT_DISABLE
export HOST=${HOST:-"localhost"}
export PORT
export ADMIN_ROOT="${ADMIN_ROOT:-"${PROJECT_ROOT}/vendor/shopware/administration"}"

# Ensure BIN_TOOL is set and executable
get_bin_tool

# Dump bundles and features if not skipped
[[ ${SHOPWARE_SKIP_BUNDLE_DUMP:-""} ]] || "${BIN_TOOL}" bundle:dump
[[ ${SHOPWARE_SKIP_FEATURE_DUMP:-""} ]] || "${BIN_TOOL}" feature:dump

# Install webpack-dev-server if not present
[[ ! -d "${ADMIN_ROOT}"/Resources/app/administration/node_modules/webpack-dev-server ]] && npm --prefix "${ADMIN_ROOT}"/Resources/app/administration install || true

# Install administration npm dependencies for extensions
install_extensions_npm_dependencies "administration"

# Dump entity schema
dump_entity_schema

# Build administration in development mode
npm --prefix "${ADMIN_ROOT}/Resources/app/administration" run dev
