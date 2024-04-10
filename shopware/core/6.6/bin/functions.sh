#!/usr/bin/env bash

load_dotenv() {
    LOAD_DOTENV=${LOAD_DOTENV:-"1"}

    if [[ "$LOAD_DOTENV" == "0" ]]; then
        return
    fi

    CURRENT_ENV=${APP_ENV:-"dev"}
    local env_file="$1"

    # If we have an actual .env file load it
    if [[ -e "$env_file" ]]; then
        # shellcheck source=/dev/null
        source "$env_file"
    elif [[ -e "$env_file.dist" ]]; then
        # shellcheck source=/dev/null
        source "$env_file.dist"
    fi

    # If we have an local env file load it
    if [[ -e "$env_file.local" ]]; then
        # shellcheck source=/dev/null
        source "$env_file.local"
    fi

    # If we have an env file for the current env load it
    if [[ -e "$env_file.$CURRENT_ENV" ]]; then
        # shellcheck source=/dev/null
        source "$env_file.$CURRENT_ENV"
    fi

    # If we have an env file for the current env load it'
    if [[ -e "$env_file.$CURRENT_ENV.local" ]]; then
        # shellcheck source=/dev/null
        source "$env_file.$CURRENT_ENV.local"
    fi
}

get_bin_tool() {
    local bin_tool_path="${CWD}/console"

    if [[ -n ${CI:-} ]]; then
        bin_tool_path="${CWD}/ci"

        if [[ ! -x "$bin_tool_path" ]]; then
            chmod +x "$bin_tool_path"
        fi
    fi

    BIN_TOOL="$bin_tool_path"
}

dump_entity_schema() {
    # Check if entity schema dump should be skipped or the file exists
    if [[ -z "${SHOPWARE_SKIP_ENTITY_SCHEMA_DUMP:-}" ]] && \
       [[ -f "${ADMIN_ROOT}/Resources/app/administration/scripts/entitySchemaConverter/entity-schema-converter.ts" ]]; then

        local mocks_dir="${ADMIN_ROOT}/Resources/app/administration/test/_mocks_"

        # Ensure mocks directory exists
        mkdir -p "$mocks_dir"

        # Generate entity schema JSON
        "${BIN_TOOL}" -e prod framework:schema -s 'entity-schema' "${mocks_dir}/entity-schema.json"

        # Convert entity schema JSON
        npm --prefix "${ADMIN_ROOT}/Resources/app/administration" run convert-entity-schema
    fi
}

install_extensions_npm_dependencies() {
    local component_name="$1"
    local npm_args=${2:-""}

    if [[ $(command -v jq) ]]; then
        OLDPWD=$(pwd)
        cd "$PROJECT_ROOT" || exit

        jq -c '.[]' "var/plugins.json" | while read -r config; do
            srcPath=$(echo "$config" | jq -r "(.basePath + .${component_name}.path)")

            # the package.json files are always one upper
            path=$(dirname "$srcPath")
            name=$(echo "$config" | jq -r '.technicalName' )

            skippingEnvVarName="SKIP_$(echo "$name" | sed -e 's/\([a-z]\)/\U\1/g' -e 's/-/_/g')"

            if [[ ${!skippingEnvVarName:-""} ]]; then
                continue
            fi

            if [[ -f "$path/package.json" && ! -d "$path/node_modules" && $name != "$component_name" ]]; then
                echo "=> Installing npm dependencies for ${name}"

                npm --prefix "$path" install $npm_args
            fi
        done
        cd "$OLDPWD" || exit
    else
        echo "Cannot check extensions for required npm installations as jq is not installed"
    fi
}

install_and_build_storefront() {
    local storefront_app_dir="${STOREFRONT_ROOT}/Resources/app/storefront"

    # Install npm dependencies for storefront
    npm --prefix "$storefront_app_dir" install --prefer-offline --production

    # Copy to vendor
    node "$storefront_app_dir/copy-to-vendor.js"

    # Run production build
    npm --prefix "$storefront_app_dir" run production
}
