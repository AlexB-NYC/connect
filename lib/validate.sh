#!/usr/bin/env bash
set -euo pipefail

# expects: lib/common.sh sourced by caller

_test_ssh_accept_new_supported() {
  ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=1 \
    -o StrictHostKeyChecking=accept-new \
    localhost true \
    >/dev/null 2>&1
}


test_ssh_connection() {
  local user="$1" host="$2" key_path="${3:-}" insecure="${4:-0}" verbose="${5:-0}"

  local opts=()
  opts+=( -o ConnectTimeout=7 )

  if [[ -n "$key_path" ]]; then
    opts+=( -o BatchMode=yes )
  fi

  if (( insecure )); then
    opts+=( -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null )
  else
    if _test_ssh_accept_new_supported; then
      opts+=( -o StrictHostKeyChecking=accept-new )
    fi
  fi

  if (( verbose )); then
    opts+=( -vvv )
  fi

  if [[ -n "$key_path" ]]; then
    opts=( -i "$key_path" "${opts[@]}" )
  fi

  ssh "${opts[@]}" "$user@$host" "true" >/dev/null 2>&1
}
