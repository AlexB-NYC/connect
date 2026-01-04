````markdown
# connect

`connect` is a small CLI tool for quickly connecting to frequently-used servers via **SSH** and optionally mounting remote paths via **SSHFS**. It uses a plain INI-style config file (`servers.conf`) and includes an interactive manager for adding/editing/removing entries.

The user-facing entry point is always `connect`. Internally it delegates management tasks to `engine`.

---

## What it does

- `connect <name>`: mount via SSHFS (if enabled) then open SSH
- `connect <name> --ssh`: SSH only
- `connect <name> --fs`: SSHFS mount only
- `connect --list`: show a numbered table and allow quick actions via single keypress
- `connect --add|--edit|--del|--engine`: manage entries (delegates to `engine`)

---

## Installation

```bash
./install.sh
````

This project expects an `install.sh` that places `connect` on your PATH (commonly `/usr/local/bin/connect`). See that script for exact behavior.

---

## Configuration

Server definitions live in an INI-style file. `connect` searches for it in this order:

1. `$CONNECT_CONFIG` (if set)
2. `$XDG_CONFIG_HOME/connect/servers.conf` (if set)
3. `$HOME/.config/connect/servers.conf`
4. `/etc/connect/servers.conf` (fallback if the above is missing)

To force a specific config:

```bash
export CONNECT_CONFIG="$HOME/.config/connect/servers.conf"
```

---

## Example `servers.conf`

```ini
[my-server]
remote_user=ubuntu
remote_host=203.0.113.10
remote_path=/var/www
mount_label=MyServer
ssh_key=my-key.pem
```

---

## Config keys

Required:

* `remote_user`
* `remote_host`
* `remote_path`
* `mount_label`

Optional:

* `ssh_key` (filename or absolute path)
* `mount_point`
* `log_file`

Notes:

* If `ssh_key` is **not** absolute, it is treated as `~/.ssh/<ssh_key>`.
* If `ssh_key` is blank/missing, SSH can still work via password prompts or your SSH agent.

---

## Usage

### Connect by name

```bash
connect my-server
```

Default behavior: mount via SSHFS, then open SSH.

### SSH only

```bash
connect my-server --ssh
```

### SSHFS only

```bash
connect my-server --fs
```

### List and pick interactively

```bash
connect --list
```

This prints a table like:

* `#` (index)
* `name` (section name)
* `host` (remote_host)
* `user` (remote_user)
* `key` (ssh_key)

Then it waits for a **single keypress**:

```text
Actions: [C]onnect  [A]dd  [E]dit  [D]el  [Q]uit
Selection:
```

* Pressing **Enter** exits.
* **Ctrl+C** exits.

If you choose connect (or press a digit), it will ask for a server number, then prompt for connection mode:

```text
[S]sh-only, [F]s-only, [B]oth (default)
Mode:
```

* Enter defaults to **Both**
* `S` uses `--ssh`
* `F` uses `--fs`

---

## Management commands

These are all user-facing entry points and delegate to `engine`:

### Interactive manager

```bash
connect --engine
```

### Add entry

```bash
connect --add
```

### Edit entry

```bash
connect --edit
```

### Delete entry

```bash
connect --del
```

---

## Logging

If `log_file` is not set in config, logs default to:

```text
$XDG_CACHE_HOME/connect/connect.log
```

or:

```text
$HOME/.cache/connect/connect.log
```

---

## Mount behavior

If `mount_point` is not specified:

* macOS: `~/mnt/<mount_label>`
* Linux: `/media/<user>/<mount_label>`

Before mounting, `connect` attempts to unmount any existing mount at the mount point.

Linux note: SSHFS with `allow_other` requires `user_allow_other` enabled in `/etc/fuse.conf`.

---

## Flags

```text
--ssh        SSH only
--fs         SSHFS only
--list       show table and prompt
--add        add entry (engine)
--edit       edit entry (engine)
--del        delete entry (engine)
--engine     interactive manager (engine)
-v, --verbose  verbose SSH/SSHFS output
--insecure   disable host key checking (SSH and SSHFS)
```

---

## Repo layout

```text
bin/connect        main entry point
bin/engine         interactive manager (invoked by connect)
lib/common.sh      shared helpers (prompt, trim, die, os detection)
lib/config.sh      config parsing helpers (list_servers, config_get, etc)
lib/validate.sh    validation helpers used by engine
```

---

## License

MIT

```
```
