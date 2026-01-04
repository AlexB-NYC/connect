#!/usr/bin/env bash
# lib/ui.sh
set -euo pipefail

# expects: common.sh (ok/info/warn/die/prompt/confirm/trim)

ui() {
  # UI text (menus/tables). Keep separate from ok() which is “status”.
  printf "%s\n" "$*" >&2
}

ui_blank_line() { printf "\n" >&2; }

ui_read_key() {
  # reads a single keypress, returns it (may be empty)
  local k=""
  IFS= read -r -n 1 k || true
  printf "%s" "$k"
}

ui_no_servers_menu() {
  # args: config_file
  local cfg="$1"

  ok "No servers found in: $cfg"
  ok "No servers found. Press A to add one, or Q to quit."
  ui_blank_line
  ui "Actions: [A]dd  [Q]uit"
  printf "Selection: " >&2

  local sel
  sel="$(ui_read_key)"
  ui_blank_line

  case "${sel:-}" in
    [Aa]) printf "add" ;;
    [Qq]|'') printf "quit" ;;
    *) printf "invalid" ;;
  esac
}

ui_render_server_table() {
  # args: servers hosts users keys (as positional lists)
  # usage: ui_render_server_table "${servers[@]}" -- "${hosts[@]}" -- "${users[@]}" -- "${keys[@]}"
  local -a servers=() hosts=() users=() keys=()
  local mode="servers"

  while (( $# )); do
    case "$1" in
      --)
        if [[ "$mode" == "servers" ]]; then mode="hosts"
        elif [[ "$mode" == "hosts" ]]; then mode="users"
        elif [[ "$mode" == "users" ]]; then mode="keys"
        else die "ui_render_server_table: too many separators"
        fi
        shift
        ;;
      *)
        case "$mode" in
          servers) servers+=("$1") ;;
          hosts)   hosts+=("$1") ;;
          users)   users+=("$1") ;;
          keys)    keys+=("$1") ;;
        esac
        shift
        ;;
    esac
  done

  local count="${#servers[@]}"
  (( count > 0 )) || return 0

  local max_idx=1 max_name=4 max_host=4 max_user=4 max_key=3
  local i n idx_len name_len host_len user_len key_len

  for ((i=0; i<count; i++)); do
    n=$((i+1))
    idx_len="${#n}"
    name_len="${#servers[i]}"
    host_len="${#hosts[i]}"
    user_len="${#users[i]}"
    key_len="${#keys[i]}"
    (( idx_len > max_idx )) && max_idx="$idx_len"
    (( name_len > max_name )) && max_name="$name_len"
    (( host_len > max_host )) && max_host="$host_len"
    (( user_len > max_user )) && max_user="$user_len"
    (( key_len > max_key )) && max_key="$key_len"
  done

  line() {
    local a="$1" b="$2" c="$3" d="$4" e="$5"
    printf "+-%-*s-+-%-*s-+-%-*s-+-%-*s-+-%-*s-+\n" \
      "$a" "" "$b" "" "$c" "" "$d" "" "$e" ""
  }

  line "$max_idx" "$max_name" "$max_host" "$max_user" "$max_key"
  printf "| %*s | %-*s | %-*s | %-*s | %-*s |\n" \
    "$max_idx" "#" \
    "$max_name" "name" \
    "$max_host" "host" \
    "$max_user" "user" \
    "$max_key" "key"
  line "$max_idx" "$max_name" "$max_host" "$max_user" "$max_key"

  for ((i=0; i<count; i++)); do
    n=$((i+1))
    printf "| %*d | %-*s | %-*s | %-*s | %-*s |\n" \
      "$max_idx" "$n" \
      "$max_name" "${servers[i]}" \
      "$max_host" "${hosts[i]}" \
      "$max_user" "${users[i]}" \
      "$max_key" "${keys[i]}"
  done

  line "$max_idx" "$max_name" "$max_host" "$max_user" "$max_key"
  ui_blank_line
}

ui_prompt_list_action() {
  ui "Actions: [C]onnect  [A]dd  [E]dit  [D]el  [Q]uit"
  printf "Selection: " >&2
  local sel
  sel="$(ui_read_key)"
  ui_blank_line

  case "${sel:-}" in
    [Cc]) printf "connect" ;;
    [Aa]) printf "add" ;;
    [Ee]) printf "edit" ;;
    [Dd]) printf "del" ;;
    [Qq]|'') printf "quit" ;;
    *)
      printf "invalid:%s" "$sel"
      ;;
  esac
}

ui_prompt_server_number() {
  # args: prompt_text default_value
  local prompt_text="$1"
  local def="${2:-}"
  prompt "$prompt_text" "$def"
}

ui_prompt_connect_mode() {
  ui "[S]sh-only, [F]s-only, [B]oth (default)"
  printf "Mode: " >&2
  local k
  k="$(ui_read_key)"
  ui_blank_line

  case "${k:-}" in
    [Ss]) printf "ssh" ;;
    [Ff]) printf "fs" ;;
    ''|[Bb]) printf "both" ;;
    *) printf "invalid:%s" "$k" ;;
  esac
}

# Engine "menu" UI (simple numbered list)
ui_engine_menu_header() {
  # args: config_file
  local cfg="$1"
  ui_blank_line
  ui "Config: $cfg"
  ui "Servers:"
}

ui_engine_menu_footer() {
  ui_blank_line
  ui "[A]dd  [E]dit  [D]el  [Q]uit"
  ui "Enter a number to connect."
}
