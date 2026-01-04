# install.sh
#!/usr/bin/env bash
set -euo pipefail

# Installs the full connect package into /etc/connect (or --dest),
# preserving directory structure, and places a wrapper script in
# /usr/local/bin (or --bindir) named "connect" that executes
# /etc/connect/bin/entry.

usage() {
  cat <<'EOF' >&2
Usage:
  install.sh [options]

Options:
  --dest <dir>       Install destination root (default: /etc/connect)
  --bindir <dir>     Where to place the wrapper (default: /usr/local/bin)
  --name <name>      Wrapper name (default: connect)
  --uninstall        Remove installed files and wrapper
  --force            Overwrite existing install
  -h, --help         Show help

Install layout:
  <dest>/
    bin/entry
    bin/engine
    lib/*.sh
    servers.conf.example (if present)

Wrapper:
  <bindir>/<name> -> executes <dest>/bin/entry
EOF
}

die() { echo "Error: $*" >&2; exit 1; }
info() { echo "$*" >&2; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

maybe_sudo() {
  if [[ $EUID -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
      sudo "$@"
    else
      die "Need root privileges for: $* (sudo not available)"
    fi
  else
    "$@"
  fi
}

dest="/etc/connect"
bindir="/usr/local/bin"
name="connect"
force=0
do_uninstall=0

while (( $# )); do
  case "$1" in
    --dest) shift; [[ $# -gt 0 ]] || die "--dest requires a value"; dest="$1"; shift ;;
    --bindir) shift; [[ $# -gt 0 ]] || die "--bindir requires a value"; bindir="$1"; shift ;;
    --name) shift; [[ $# -gt 0 ]] || die "--name requires a value"; name="$1"; shift ;;
    --force) force=1; shift ;;
    --uninstall) do_uninstall=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

need_cmd mkdir
need_cmd cp
need_cmd rm
need_cmd chmod
need_cmd mktemp

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src_bin="$repo_root/bin"
src_lib="$repo_root/lib"

[[ -d "$src_bin" ]] || die "Missing directory: $src_bin"
[[ -d "$src_lib" ]] || die "Missing directory: $src_lib"
[[ -f "$src_bin/entry" ]] || die "Missing file: $src_bin/entry"
[[ -f "$src_bin/engine" ]] || die "Missing file: $src_bin/engine"

wrapper_path="$bindir/$name"
entry_path="$dest/bin/entry"

# Safety: never allow wrapper to overwrite the installed entrypoint
if [[ "$wrapper_path" == "$entry_path" ]]; then
  die "Refusing to install: wrapper path equals entrypoint: $wrapper_path"
fi

write_wrapper() {
  local tmp
  tmp="$(mktemp)"

  cat >"$tmp" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "${entry_path}" "\$@"
EOF

  maybe_sudo mkdir -p "$bindir"

  # If wrapper exists as a symlink (including dangling), remove it so cp succeeds.
  if [[ -L "$wrapper_path" ]]; then
    maybe_sudo rm -f "$wrapper_path"
  elif [[ -e "$wrapper_path" && $force -eq 0 ]]; then
    rm -f "$tmp"
    die "Wrapper already exists: $wrapper_path (use --force to overwrite)"
  elif [[ -e "$wrapper_path" && $force -eq 1 ]]; then
    maybe_sudo rm -f "$wrapper_path"
  fi

  maybe_sudo cp "$tmp" "$wrapper_path"
  maybe_sudo chmod 0755 "$wrapper_path"
  rm -f "$tmp"
}

install_tree() {
  if [[ -e "$dest" && $force -eq 0 ]]; then
    die "Destination already exists: $dest (use --force to overwrite)"
  fi

  if [[ -e "$dest" && $force -eq 1 ]]; then
    maybe_sudo rm -rf "$dest"
  fi

  maybe_sudo mkdir -p "$dest/bin" "$dest/lib"

  maybe_sudo cp -R "$src_bin/." "$dest/bin/"
  maybe_sudo cp -R "$src_lib/." "$dest/lib/"

  if [[ -f "$repo_root/servers.conf.example" ]]; then
    maybe_sudo cp "$repo_root/servers.conf.example" "$dest/servers.conf.example"
  fi

  maybe_sudo chmod 0755 "$dest/bin/entry" "$dest/bin/engine"
  maybe_sudo chmod 0644 "$dest/lib/"*.sh 2>/dev/null || true
}

uninstall_all() {
  if [[ -e "$wrapper_path" ]]; then
    maybe_sudo rm -f "$wrapper_path"
    info "Removed wrapper: $wrapper_path"
  else
    info "Wrapper not found: $wrapper_path"
  fi

  if [[ -d "$dest" ]]; then
    maybe_sudo rm -rf "$dest"
    info "Removed install dir: $dest"
  else
    info "Install dir not found: $dest"
  fi
}

main() {
  if (( do_uninstall )); then
    uninstall_all
    info "Uninstall complete."
    exit 0
  fi

  install_tree
  write_wrapper

  info "Installed package to: $dest"
  info "Installed wrapper: $wrapper_path"
  info "Try: $name --list"
}

main
