#!/usr/bin/env bash

unset CDPATH
CWD="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

set -euo pipefail

export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PROJECT_ROOT="${PROJECT_ROOT:-"$(dirname "$CWD")"}"
export NPM_CONFIG_FUND=false
export NPM_CONFIG_AUDIT=false
export NPM_CONFIG_UPDATE_NOTIFIER=false

if [[ -e "${PROJECT_ROOT}/vendor/shopware/platform" ]]; then
    STOREFRONT_ROOT="${STOREFRONT_ROOT:-"${PROJECT_ROOT}/vendor/shopware/platform/src/Storefront"}"
else
    STOREFRONT_ROOT="${STOREFRONT_ROOT:-"${PROJECT_ROOT}/vendor/shopware/storefront"}"
fi

BIN_TOOL="${CWD}/console"

if [[ ${CI:-""} ]]; then
    BIN_TOOL="${CWD}/ci"

    if [[ ! -x "$BIN_TOOL" ]]; then
        chmod +x "$BIN_TOOL"
    fi
fi

keep_cache=0
parallel=0
for arg in "$@"; do
    case "$arg" in
        --keep-cache) keep_cache=1 ;;
        --parallel)   parallel=1 ;;
    esac
done
[[ ${SHOPWARE_THEME_COMPILE_PARALLEL:-""} ]] && parallel=1

# build storefront
[[ ${SHOPWARE_SKIP_BUNDLE_DUMP:-""} ]] || "${BIN_TOOL}" bundle:dump
[[ ${SHOPWARE_SKIP_FEATURE_DUMP:-""} ]] || "${BIN_TOOL}" feature:dump

if [[ $(command -v jq) ]]; then
    OLDPWD=$(pwd)
    cd "$PROJECT_ROOT" || exit

    jq -c '.[]' "var/plugins.json" | while read -r config; do
        srcPath=$(echo "$config" | jq -r '(.basePath + .storefront.path)')

        # the package.json files are always one upper
        path=$(dirname "$srcPath")
        name=$(echo "$config" | jq -r '.technicalName' )

        skippingEnvVarName="SKIP_$(echo "$name" | sed -e 's/\([a-z]\)/\U\1/g' -e 's/-/_/g')"

        if [[ ${!skippingEnvVarName:-""} ]]; then
            continue
        fi

        if [[ -f "$path/package.json" && ! -d "$path/node_modules" && $name != "storefront" ]]; then
            echo "=> Installing npm dependencies for ${name}"

            npm install --prefix "$path" --prefer-offline
        fi
    done
    cd "$OLDPWD" || exit
else
    echo "Cannot check extensions for required npm installations as jq is not installed"
fi

npm --prefix "${STOREFRONT_ROOT}"/Resources/app/storefront install --prefer-offline --omit=dev
node "${STOREFRONT_ROOT}"/Resources/app/storefront/copy-to-vendor.js
npm --prefix "${STOREFRONT_ROOT}"/Resources/app/storefront run production
[[ ${SHOPWARE_SKIP_ASSET_COPY:-""} ]] ||"${BIN_TOOL}" assets:install
if [[ -z ${SHOPWARE_SKIP_THEME_COMPILE:-""} ]]; then
    if [[ $parallel -eq 1 ]] && command -v jq >/dev/null 2>&1; then
        # Parallelize theme:compile across sales channels.
        # First channel compiles with assets (writes theme/<themeId>/ serially to avoid races).
        # Remaining channels run in parallel with --keep-assets (CSS only, no shared write path).
        channels=$("${BIN_TOOL}" sales-channel:list --output=json \
            | jq -r '[.[] | select(.active=="active")] | .[] | .id + "|" + .name')

        if [[ -z "$channels" ]]; then
            echo "No active sales channels, skipping theme compile."
        else
            first_channel=$(echo "$channels" | head -1)
            rest_channels=$(echo "$channels" | tail -n +2)
            rest_count=$(echo -n "$rest_channels" | grep -c . 2>/dev/null || true)
            cpu_count=$(sysctl -n hw.logicalcpu 2>/dev/null || nproc 2>/dev/null || echo 4)
            workers="${SHOPWARE_THEME_COMPILE_WORKERS:-$(( rest_count < cpu_count ? rest_count : cpu_count ))}"
            [[ $workers -lt 1 ]] && workers=1

            compile_channel() {
                local pair="$1"; shift
                local id="${pair%%|*}"
                local name="${pair##*|}"
                local output exit_code
                output=$("$BIN_TOOL" theme:compile --only "$id" --sync "$@" 2>&1); exit_code=$?
                if [[ $exit_code -eq 0 ]]; then
                    printf "  ok  %s\n" "$name"
                else
                    printf "  FAIL  %s\n%s\n" "$name" "$output"
                    return $exit_code
                fi
            }
            export -f compile_channel
            export BIN_TOOL

            total=$(echo "$channels" | wc -l | tr -d ' ')
            echo "Compiling themes: ${total} sales channel(s), ${workers} parallel worker(s)"

            compile_channel "$first_channel"
            if [[ -n "$rest_channels" ]]; then
                # shellcheck disable=SC2016
                echo "$rest_channels" \
                    | xargs -P"$workers" -I{} bash -c 'compile_channel "$1" --keep-assets' _ {}
            fi
        fi
    else
        "${BIN_TOOL}" theme:compile --active-only --sync
    fi
fi

if [[ $keep_cache -eq 0 ]]; then
    "${BIN_TOOL}" cache:clear
fi
