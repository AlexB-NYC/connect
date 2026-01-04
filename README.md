# connect

`connect` is a small CLI tool for quickly connecting to frequently used servers via SSH, with optional SSHFS mounting.  
It uses a simple INI-style config file and includes an interactive manager for adding, editing, and removing entries.

The **only user-facing entry point is `connect`**.  
Management actions are internally delegated to `engine`.

---

## What it does

```text
connect <name>           # SSHFS mount (if enabled) + SSH
connect <name> --ssh     # SSH only
connect <name> --fs      # SSHFS mount only

connect --list           # show table and interactively select actions
connect --add            # add a server entry
connect --edit           # edit a server entry
connect --del            # delete a server entry
```

Installation
`./install.sh`
Or run from source by adding the project directory to your PATH.

Configuration
Server definitions live in an INI-style file.
connect searches for it in this order:

$CONNECT_CONFIG (if set)

$XDG_CONFIG_HOME/connect/servers.conf

$HOME/.config/connect/servers.conf

To force a specific config file:

export CONNECT_CONFIG="$HOME/.config/connect/servers.conf"
Example servers.conf
[my-server]
remote_user=ubuntu
remote_host=203.0.113.10
remote_path=/var/www
mount_label=MyServer
ssh_key=my-key.pem
Config keys
Required
remote_user

remote_host

remote_path

mount_label

Optional
ssh_key (filename or absolute path)

mount_point

log_file

Notes

Non-absolute ssh_key values are resolved as ~/.ssh/<key>.

If ssh_key is omitted, SSH can still work via agent or password.

Usage
Connect by name
connect my-server
Default behavior: SSHFS mount, then SSH.

SSH only
connect my-server --ssh
SSHFS only
connect my-server --fs
Interactive list
connect --list
Displays a table with:

index

name

host

user

key

Then waits for a single keypress:

Actions: [C]onnect  [A]dd  [E]dit  [D]el  [Q]uit
Selection:
Digits select a server (Enter confirms)

Enter exits

Ctrl+C exits

If connecting, you’ll be prompted for mode:

[S]sh-only, [F]s-only, [B]oth (default)
Management commands
All are user-facing and delegate to engine:

connect --add
connect --edit
connect --del
Logging
If log_file is not set, logs default to:

$XDG_CACHE_HOME/connect/connect.log
or:

$HOME/.cache/connect/connect.log
Mount behavior
If mount_point is not specified:

macOS: ~/mnt/<mount_label>

Linux: /media/<user>/<mount_label>

Before mounting, any existing mount at that path is unmounted.

Linux note: SSHFS with allow_other requires user_allow_other enabled in /etc/fuse.conf.

Flags
--ssh           SSH only
--fs            SSHFS only
--list          show table and prompt
--add           add entry
--edit          edit entry
--del           delete entry
-v, --verbose   verbose SSH / SSHFS output
--insecure      disable host key checking
--debug         debug output for scripts
Repo layout
bin/entry        main user-facing command (connect)
bin/engine       config management (add/edit/del)
lib/common.sh    shared helpers
lib/config.sh    config parsing helpers
lib/validate.sh  validation helpers
lib/ui.sh        interactive UI helpers
License
MIT
