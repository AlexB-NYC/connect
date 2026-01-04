# lib/validate.sh
#!/usr/bin/env bash
set -euo pipefail

# expects: lib/common.sh sourced by caller

check_key_file() {
  local key_path="$1"
  [[ -n "$key_path" ]] || return 0

  if [[ ! -f "$key_path" ]]; then
    die "SSH key not found: $key_path"
  fi

  # best-effort perms check
  local perm
  perm="$(ls -l "$key_path" 2>/dev/null | awk '{print $1}')"
  if [[ -n "$perm" ]]; then
    local group="${perm:4:3}" other="${perm:7:3}"
    if [[ "$group" != "---" || "$other" != "---" ]]; then
      warn "Key permissions look open ($perm). Recommended: chmod 600 '$key_path'"
    fi
  fi
}

_test_ssh_accept_new_supported() {
  ssh -o StrictHostKeyChecking=accept-new -G localhost >/dev/null 2>&1
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
