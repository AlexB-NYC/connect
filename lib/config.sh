# /lib/config.sh
#!/usr/bin/env bash
set -euo pipefail

# expects: lib/common.sh sourced by caller

resolve_config_file() {
  echo "${CONNECT_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/connect/servers.conf}"
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

  mkdir -p "$(dirname "$cfg")" || die "Cannot create config dir: $(dirname "$cfg")"

  if [[ ! -e "$cfg" ]]; then
    : > "$cfg" || die "Cannot create config file: $cfg"
  fi

  [[ -r "$cfg" ]] || die "Config file not readable: $cfg"
  [[ -w "$cfg" ]] || die "Config file not writable: $cfg"

  local before after
  before="$(wc -c < "$cfg" || echo 0)"

  if [[ -s "$cfg" ]]; then
    printf "\n%s\n" "$block" >> "$cfg" || die "Failed writing to config file: $cfg"
  else
    printf "%s\n" "$block" >> "$cfg" || die "Failed writing to config file: $cfg"
  fi

  after="$(wc -c < "$cfg" || echo 0)"
  (( after > before )) || die "Write did not change config file size: $cfg"
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

  if [[ -n "$ssh_key" ]]; then
    printf "ssh_key=%s\n" "$ssh_key"
  fi

  printf "mount_label=%s\n" "$mount_label"

  if [[ -n "$mount_point" ]]; then
    printf "mount_point=%s\n" "$mount_point"
  fi

  if [[ -n "$log_file" ]]; then
    printf "log_file=%s\n" "$log_file"
  fi

  return 0
}
