# connect

**`connect`** is a small CLI tool for quickly connecting to frequently used servers via SSH, with optional SSHFS mounting.  
It uses a simple INI-style config file and includes an interactive manager for adding, editing, and removing entries.

> **Single Entry Point:**  
> The only user-facing command is `connect`.  
> Internal operations like adding/editing entries are delegated to an internal helper script: `engine`.

---

## What It Does

```bash
connect <name>           # SSHFS mount (if enabled) + SSH
connect <name> --ssh     # SSH only
connect <name> --fs      # SSHFS mount only

connect --list           # Show table and interactively select actions
connect --add            # Add a server entry
connect --edit           # Edit a server entry
connect --del            # Delete a server entry
```

---

## Installation

```bash
./install.sh
```

Or run directly from source by adding the project directory to your `PATH`.

---

## Configuration

Server definitions live in an INI-style config file.  
`connect` searches for it in the following order:

1. `$CONNECT_CONFIG` (if set)
2. `$XDG_CONFIG_HOME/connect/servers.conf`
3. `$HOME/.config/connect/servers.conf`

To explicitly set the config path:

```bash
export CONNECT_CONFIG="$HOME/.config/connect/servers.conf"
```

### Example `servers.conf`

```ini
[my-server]
remote_user=ubuntu
remote_host=203.0.113.10
remote_path=/var/www
mount_label=MyServer
ssh_key=my-key.pem
```

### Config Keys

**Required:**
- `remote_user`
- `remote_host`
- `remote_path`
- `mount_label`

**Optional:**
- `ssh_key` (filename or absolute path)
- `mount_point`
- `log_file`

**Notes:**
- If `ssh_key` is not an absolute path, it resolves to `~/.ssh/<key>`.
- SSH will still work without `ssh_key` via agent or password authentication.

---

## Usage

### Connect by Name

```bash
connect my-server
```

Default behavior: SSHFS mount (if configured), then SSH.

### SSH Only

```bash
connect my-server --ssh
```

### SSHFS Only

```bash
connect my-server --fs
```

---

## Interactive Mode

```bash
connect --list
```

Displays a table of configured servers with:

- Index
- Name
- Host
- User
- Key

Then waits for a single keypress:

**Actions:**
- `[C]` Connect
- `[A]` Add
- `[E]` Edit
- `[D]` Delete
- `[Q]` Quit

**Selection:**
- Digits select a server (Enter confirms)
- `Enter` exits
- `Ctrl+C` exits

When connecting, you’ll be prompted for the mode:

```text
[S] SSH-only
[F] SSHFS-only
[B] Both (default)
```

---

## Management Commands

All user-facing management commands internally delegate to `engine`:

```bash
connect --add     # Add a new server
connect --edit    # Edit an existing server
connect --del     # Delete a server
```

---

## Logging

If `log_file` is not set, logs default to:

- `$XDG_CACHE_HOME/connect/connect.log`, or
- `$HOME/.cache/connect/connect.log`

---

## Mount Behavior

If `mount_point` is not specified:

- macOS: `~/mnt/<mount_label>`
- Linux: `/media/<user>/<mount_label>`

Before mounting, any existing mount at that path is unmounted.

**Linux Note:**  
SSHFS with `allow_other` requires `user_allow_other` to be enabled in `/etc/fuse.conf`.

---

## Flags

| Flag           | Description                             |
|----------------|-----------------------------------------|
| `--ssh`        | SSH only                                |
| `--fs`         | SSHFS only                              |
| `--list`       | Show table and interactively select     |
| `--add`        | Add a server entry                      |
| `--edit`       | Edit a server entry                     |
| `--del`        | Delete a server entry                   |
| `-v`, `--verbose` | Verbose SSH / SSHFS output           |
| `--insecure`   | Disable SSH host key checking           |
| `--debug`      | Debug output for internal scripts       |

---

## Repo Layout

```text
bin/entry         # Main user-facing command (connect)
bin/engine        # Config management (add/edit/del)
lib/common.sh     # Shared helpers
lib/config.sh     # Config parsing
lib/validate.sh   # Validation logic
lib/ui.sh         # Interactive UI
```

---

## License

MIT License — see [LICENSE](./LICENSE) for details.

---

Made to simplify your server workflows.
