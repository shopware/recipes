#!/usr/bin/env bash

# fail on error
set -e

if [[ -z "$FASTLY_API_TOKEN" ]]; then
  echo "Environment variable FASTLY_API_TOKEN is not set. Skipping"
  exit 0
fi

if [[ -z "$FASTLY_SERVICE_ID" ]]; then
  echo "Environment variable FASTLY_SERVICE_ID is not set. Skipping"
  exit 0
fi

CWD="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="${PROJECT_ROOT:-"$(dirname "$CWD")"}"

cd "$PROJECT_ROOT"

created_version=0

create_version_if_not_done() {
    if [[ "$created_version" == "1" ]]; then
        return
    fi

    echo "Creating version from active version"
    fastly service-version clone --version=active
    created_version=1
}

get_md5()
{
  if builtin command -v md5 > /dev/null; then
    echo "$1" | md5
  elif builtin command -v md5sum > /dev/null ; then
    echo "$1" | md5sum | awk '{print $1}'
  else
    echo "Neither md5 nor md5sum were found in the PATH"
    return 1
  fi

  return 0
}

install_fastly_cli() {
    if [[ -f "/tmp/fastly/fastly" ]]; then
      export PATH="/tmp/fastly:$PATH"
      return
    fi

    mkdir -p /tmp/fastly

    arch=$(uname -m)
    os="linux"
    version="v10.6.4"

    if [[ "$arch" == "x86_64" ]]; then
        arch="amd64"
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        os="darwin"
    fi

    echo "Detected OS: ${os} and architecture: ${arch}"

    file="https://github.com/fastly/cli/releases/download/${version}/fastly_${version}_${os}-${arch}.tar.gz"

    echo "Downloading ${file}"

    curl -L "${file}" | tar xz -C /tmp/fastly/
    export PATH="/tmp/fastly:$PATH"
}

install_fastly_cli

# Fastly tries to write into /app on platformsh and this throws an error
export HOME=/tmp

for sub in ./config/fastly/*; do
  if ! find "$sub" -name '*.vcl' | grep . >/dev/null; then
    # No VCL files in "$sub"; moving on to the next dir
    continue
  fi
  for vcl in "$sub"/*.vcl; do
    trigger=$(basename "$vcl" .vcl)
    priority=$(echo "$trigger" | awk -F '.' '$2 ~ /^[0-9]+$/ { print $2 }')
    if test -z "$priority"; then
      priority="100"
    else
      trigger=$(basename "$trigger" ".$priority")
    fi
    vcl_type=$(basename "$sub")

    # For backward compatibility, default VCLs doesn't include trigger in their name
    if [[ "$trigger" == "default" ]]; then
      name="shopware_${vcl_type}"
    else
      name="shopware_${vcl_type}_${trigger}"
    fi

    echo "Found VCL snippet $trigger of type $vcl_type with priority $priority"

    if fastly vcl snippet describe --version=active "--name=$name" > /dev/null; then
        # The snippet exists on remote
        localContent=$(cat "$vcl")
        localContentMd5=$(get_md5 "$localContent")

        remoteContent=$(fastly vcl snippet describe --version=active "--name=$name" --json | jq -r '.Content')
        remoteContentMd5=$(get_md5 "$remoteContent")

        if [[ "$localContentMd5" != "$remoteContentMd5" ]]; then
            echo "Snippet ${name} has changed. Updating"

            create_version_if_not_done

            fastly vcl snippet update "--name=$name" "--content=${vcl}" "--type=${vcl_type}" "--priority=${priority}" --version=latest
        else
            echo "Snippet ${name} is up to date"
        fi
    else
        create_version_if_not_done

        fastly vcl snippet create "--name=shopware_${trigger}" "--content=${vcl}" "--type=${vcl_type}" "--priority=${priority}" --version=latest
    fi
  done
done


if [[ "$created_version" == "1" ]]; then
    echo "Activating latest version"

    fastly service-version activate --version latest
fi
