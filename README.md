# ubuntu-config

My personal Ubuntu (GNOME) setup: bash config, GNOME terminal profile,
keybindings, desktop tweaks, and app/package installation, plus a single
`install.sh` that restores the whole thing on a fresh machine.

Desktop is **GNOME on Wayland/X11** (Ubuntu default), terminal is
**GNOME Terminal**. No window manager swap, no display manager change —
this repo just layers personal preferences on top of stock Ubuntu GNOME.

## What it does

### Telemetry (step 1)

`telemetry/disable-telemetry.sh` runs first and turns off:

| Source | Action |
|---|---|
| `whoopsie` | `systemctl stop/disable` (Canonical crash reporter) |
| `apport` | `systemctl stop/disable` + `enabled=0` in `/etc/default/apport` |
| `ubuntu-report` | `ubuntu-report send no` |
| `popularity-contest` | `PARTICIPATE=no` in `/etc/popularity-contest.conf` |
| VS Code | `telemetry.telemetryLevel: "off"` in `~/.config/Code/User/settings.json` |
| npm | `fund=false`, `update-notifier=false` |

All steps are idempotent — if already disabled, the script skips silently. Missing services are reported in yellow and do not abort the install.

## What it installs

- **Apps and packages** from `packages/`:
  - APT/vendor repo installs: VS Code, Docker Engine + plugins,
    PostgreSQL, pgAdmin 4 Desktop, Brave, DBeaver, VLC, CopyQ,
    Xournal++, OBS Studio, GitHub CLI, and Node.js 22.
  - Direct vendor installs: Discord `.deb`, Zoom `.deb`, and Postman
    tarball in `/opt/Postman`.
  - Snap replacements: if `snap` exists and one of these apps is installed
    as a Snap, the script removes the Snap first and installs the normal
    APT/`.deb`/tarball version instead.
  - Intentionally excluded: RStudio, AnyDesk, Android Studio, and Brave
    web apps such as WhatsApp.
- **`bash/.bashrc`** copied to `~/.bashrc` (existing one backed up to
  `~/.bashrc.bak`). Adds custom aliases (`o` shutdown, `u` apt update),
  remaps `Ctrl+Z` to interrupt and disables suspend so `Ctrl+C` stays free
  for copy in terminal, and sources `~/.bashrc.local` for secrets.
- **GNOME Terminal profile** (`terminal/gnome-terminal.dconf`) loaded into
  `/org/gnome/terminal/` via `dconf load`.
- **Keybindings** (`keybindings/`):
  - `wm-keybindings.dconf` — `Ctrl+M` to minimize.
  - `media-keys.dconf` — `Ctrl+E` home, `Ctrl+<` terminal, `Ctrl+B` browser.
- **GNOME environment** (`gnome/`): interface, input sources, peripherals,
  shell extensions and mutter settings — all loaded via `dconf load`.

## Usage

On a fresh Ubuntu install:

```sh
sudo apt install git
git clone https://github.com/Jonathansl17/ubuntu-config.git
cd ubuntu-config
./install.sh
```

Open a new terminal for the bash changes to take effect. GNOME settings
apply immediately; some shell tweaks may require logout/login.

## Local-only overrides (`~/.bashrc.local`)

Anything machine-specific or sensitive — credentials, tokens, API keys,
RDP/SSH aliases with embedded passwords — goes into `~/.bashrc.local`,
which is **not** part of this repo. The versioned `bashrc` ends with:

```sh
[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
```

If `~/.bashrc.local` doesn't exist the block is a no-op.

### Creating it on a fresh machine

```sh
touch ~/.bashrc.local
chmod 600 ~/.bashrc.local
```

### Example contents

```sh
# API keys / tokens
export ANTHROPIC_API_KEY="sk-ant-..."

# Per-machine paths
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk"

# Aliases that embed private hosts/users/passwords
alias vpn-up='sudo openvpn --config ~/work.ovpn'
```

### Sanity check before pushing

```sh
grep -nE 'sk-|ghp_|AKIA|password=|token=|/p:|/u:' bash/.bashrc
```

Expected output: nothing.

## Repository layout

```
ubuntu-config/
├── install.sh                      # restores everything: telemetry → packages → bash → GNOME
├── telemetry/
│   └── disable-telemetry.sh        # disables Ubuntu/app telemetry (runs first)
├── packages/
│   ├── apt-packages.txt            # APT packages installed by the script
│   ├── install-packages.sh         # app/package installer
│   └── snap-replacements.tsv       # Snaps removed before normal installs
├── bash/
│   └── .bashrc                     # custom aliases + sources ~/.bashrc.local
├── terminal/
│   └── gnome-terminal.dconf
├── keybindings/
│   ├── wm-keybindings.dconf        # window manager shortcuts
│   └── media-keys.dconf            # launcher shortcuts
└── gnome/
    ├── desktop-interface.dconf
    ├── desktop-input-sources.dconf
    ├── desktop-peripherals.dconf
    ├── shell.dconf
    └── mutter.dconf
```

## License

Personal configuration — use, fork, copy, adapt freely. No warranty.
