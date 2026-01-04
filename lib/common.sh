# lib/common.sh
#!/usr/bin/env bash

set -euo pipefail

die() {
  echo "ERROR: $*" >&2
  exit 1
}

warn() {
  echo "WARN: $*" >&2
}

info() {
  echo "INFO: $*" >&2
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf "%s" "$s"
}

expand_tilde() {
  local v="$1"
  case "$v" in
    "~") printf "%s" "$HOME" ;;
    "~/"*) printf "%s/%s" "$HOME" "${v#~/}" ;;
    *) printf "%s" "$v" ;;
  esac
}

os_family() {
  case "$(uname -s)" in
    Darwin) echo "mac" ;;
    Linux)  echo "linux" ;;
    *)      echo "other" ;;
  esac
}

prompt() {
  # prompt "Question" "default"
  local q="$1" def="${2:-}"
  local ans
  if [[ -n "$def" ]]; then
    printf "%s [%s]: " "$q" "$def" >&2
  else
    printf "%s: " "$q" >&2
  fi
  IFS= read -r ans || true
  ans="$(trim "$ans")"
  if [[ -z "$ans" ]]; then
    printf "%s" "$def"
  else
    printf "%s" "$ans"
  fi
}

confirm() {
  # confirm "Question" (default yes)
  local q="$1"
  local ans
  printf "%s [Y/n]: " "$q" >&2
  IFS= read -r ans || true
  ans="$(trim "$ans")"
  [[ -z "$ans" || "$ans" == "Y" || "$ans" == "y" ]]
}

safe_tmpfile() {
  if command -v mktemp >/dev/null 2>&1; then
    mktemp "${TMPDIR:-/tmp}/connect.XXXXXX"
  else
    echo "/tmp/connect.$$.$RANDOM"
  fi
}

normalize_key_path() {
  local key="${1:-}"
  [[ -z "$key" ]] && { echo ""; return; }

  key="$(expand_tilde "$key")"
  if [[ "$key" != /* ]]; then
    key="$HOME/.ssh/$key"
  fi
  echo "$key"
}

valid_section_name() {
  local name="$1"
  [[ -n "$name" ]] || return 1
  [[ "$name" != *"["* && "$name" != *"]"* ]] || return 1
  [[ "$name" != *[[:space:]]* ]] || return 1
  return 0
}
