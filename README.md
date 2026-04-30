# ubuntu-config

My personal Ubuntu (GNOME) setup: bash config, GNOME terminal profile,
keybindings and desktop tweaks, plus a single `install.sh` that restores
the whole thing on a fresh machine.

Desktop is **GNOME on Wayland/X11** (Ubuntu default), terminal is
**GNOME Terminal**. No window manager swap, no display manager change —
this repo just layers personal preferences on top of stock Ubuntu GNOME.

## What it installs

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
export OPENAI_API_KEY="sk-..."
export GITHUB_TOKEN="ghp_..."
alias rdp-work='xfreerdp /v:10.0.0.5 /u:me /p:"$RDP_PASS"'
export RDP_PASS='...'
```

### Sanity check before pushing

```sh
grep -nE 'sk-|ghp_|AKIA|password=|token=|/p:|/u:' bash/.bashrc
```

Expected output: nothing.

## Repository layout

```
ubuntu-config/
├── install.sh                      # restores bash + GNOME settings via dconf
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
