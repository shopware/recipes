#!/usr/bin/env bash

CWD="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

export PROJECT_ROOT="${PROJECT_ROOT:-"$(dirname "$CWD")"}"
export ENV_FILE=${ENV_FILE:-"${PROJECT_ROOT}/.env"}

LOAD_DOTENV=${LOAD_DOTENV:-"1"}

if [[ "$LOAD_DOTENV" == "1" ]]; then
    source "${ENV_FILE}"
fi

export HOST=${HOST:-"localhost"}
export ESLINT_DISABLE
export PORT
export APP_URL

bin/console bundle:dump
bin/console feature:dump || true

if [ ! -d vendor/shopware/administration/Resources/app/administration/node_modules ]; then
    npm install --prefix vendor/shopware/administration/Resources/app/administration/
fi

npm run --prefix vendor/shopware/administration/Resources/app/administration/ dev
