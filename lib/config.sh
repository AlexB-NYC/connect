#!/usr/bin/env bash
set -euo pipefail

# expects: lib/common.sh sourced by caller

resolve_config_file() {
  local cfg="${CONNECT_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/connect/servers.conf}"
  if [[ ! -f "$cfg" && -f /etc/connect/servers.conf ]]; then
    cfg="/etc/connect/servers.conf"
  fi
  echo "$cfg"
}

list_servers() {
  local cfg="$1"
  [[ -r "$cfg" ]] || die "Config file not readable: $cfg"
  awk -F'[][]' '/^\[[^]]+\]/{print $2}' "$cfg"
}

section_exists() {
  local cfg="$1" section="$2"
  [[ -r "$cfg" ]] || die "Config file not readable: $cfg"
  awk -v s="[$section]" '
    $0==s {found=1}
    END {exit(found?0:1)}
  ' "$cfg"
}

config_get() {
  local cfg="$1" section="$2" key="$3"
  [[ -r "$cfg" ]] || die "Config file not readable: $cfg"
  awk -F= -v section="[$section]" -v key="$key" '
    $0==section {inside=1; next}
    /^\[/ {inside=0}
    inside {
      k=$1
      gsub(/[[:space:]]/, "", k)
      if (k==key) {
        v=$0
        sub(/^[^=]*=/, "", v)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
        print v
        exit
      }
    }
  ' "$cfg"
}


append_section() {
  local cfg="$1" _section="$2" block="$3"
  [[ -r "$cfg" || ! -e "$cfg" ]] || die "Config file not readable: $cfg"

  mkdir -p "$(dirname "$cfg")" 2>/dev/null || true

  if [[ ! -e "$cfg" ]]; then
    : > "$cfg" || die "Cannot create config file: $cfg"
  fi

  if [[ -s "$cfg" ]]; then
    printf "\n%s\n" "$block" >> "$cfg"
  else
    printf "%s\n" "$block" >> "$cfg"
  fi
}

delete_section() {
  local cfg="$1" section="$2"
  [[ -r "$cfg" ]] || die "Config file not readable: $cfg"
  local tmp
  tmp="$(safe_tmpfile)"

  awk -v section="[$section]" '
    BEGIN {skip=0}
    $0==section {skip=1; next}
    /^\[/ {skip=0}
    skip==0 {print}
  ' "$cfg" > "$tmp"

  mv "$tmp" "$cfg"
}

replace_section() {
  local cfg="$1" section="$2" new_block="$3"
  [[ -r "$cfg" ]] || die "Config file not readable: $cfg"
  local tmp
  tmp="$(safe_tmpfile)"

  awk -v section="[$section]" -v nb="$new_block" '
    BEGIN {skip=0}
    $0==section {
      print nb
      skip=1
      next
    }
    /^\[/ {
      if (skip==1) skip=0
    }
    skip==0 {print}
  ' "$cfg" > "$tmp"

  mv "$tmp" "$cfg"
}

build_section_block() {
  local section="$1"
  local remote_user="$2"
  local remote_host="$3"
  local remote_path="$4"
  local mount_label="$5"
  local ssh_key="${6:-}"
  local mount_point="${7:-}"
  local log_file="${8:-}"

  printf "[%s]\n" "$section"
  printf "remote_user=%s\n" "$remote_user"
  printf "remote_host=%s\n" "$remote_host"
  printf "remote_path=%s\n" "$remote_path"
  [[ -n "$ssh_key" ]] && printf "ssh_key=%s\n" "$ssh_key"
  printf "mount_label=%s\n" "$mount_label"
  [[ -n "$mount_point" ]] && printf "mount_point=%s\n" "$mount_point"
  [[ -n "$log_file" ]] && printf "log_file=%s\n" "$log_file"
}
