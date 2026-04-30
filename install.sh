#!/usr/bin/env bash
# install.sh — Restaura la configuración personal en una máquina Ubuntu limpia.
# Uso: git clone <repo> ~/config && cd ~/config && ./install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

green()  { printf '\033[1;32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$1"; }
red()    { printf '\033[1;31m%s\033[0m\n' "$1"; }

# ──────────────────────────────────────────────
# 1. Bash
# ──────────────────────────────────────────────
green ">>> Instalando .bashrc"
if [ -f "$HOME/.bashrc" ]; then
    cp "$HOME/.bashrc" "$HOME/.bashrc.bak"
    yellow "    Backup guardado en ~/.bashrc.bak"
fi
cp "$SCRIPT_DIR/bash/.bashrc" "$HOME/.bashrc"
green "    .bashrc instalado"

# ──────────────────────────────────────────────
# 2. Terminal (GNOME Terminal)
# ──────────────────────────────────────────────
if command -v dconf &>/dev/null; then
    green ">>> Cargando configuración de GNOME Terminal"
    dconf load /org/gnome/terminal/ < "$SCRIPT_DIR/terminal/gnome-terminal.dconf"
    green "    Terminal configurada"
else
    yellow ">>> dconf no encontrado, saltando configuración de terminal"
fi

# ──────────────────────────────────────────────
# 3. Atajos de teclado (GNOME)
# ──────────────────────────────────────────────
if command -v dconf &>/dev/null; then
    green ">>> Cargando atajos de teclado"
    dconf load /org/gnome/desktop/wm/keybindings/ < "$SCRIPT_DIR/keybindings/wm-keybindings.dconf"
    dconf load /org/gnome/settings-daemon/plugins/media-keys/ < "$SCRIPT_DIR/keybindings/media-keys.dconf"
    green "    Atajos configurados"
else
    yellow ">>> dconf no encontrado, saltando atajos de teclado"
fi

# ──────────────────────────────────────────────
# 4. Entorno GNOME (interfaz, input, periféricos, shell, mutter)
# ──────────────────────────────────────────────
if command -v dconf &>/dev/null; then
    green ">>> Cargando configuración de entorno GNOME"
    dconf load /org/gnome/desktop/interface/ < "$SCRIPT_DIR/gnome/desktop-interface.dconf"
    dconf load /org/gnome/desktop/input-sources/ < "$SCRIPT_DIR/gnome/desktop-input-sources.dconf"
    dconf load /org/gnome/desktop/peripherals/ < "$SCRIPT_DIR/gnome/desktop-peripherals.dconf"
    dconf load /org/gnome/shell/ < "$SCRIPT_DIR/gnome/shell.dconf"
    dconf load /org/gnome/mutter/ < "$SCRIPT_DIR/gnome/mutter.dconf"
    green "    Entorno GNOME configurado"
else
    yellow ">>> dconf no encontrado, saltando configuración de entorno GNOME"
fi

# ──────────────────────────────────────────────
green ""
green "Configuración restaurada. Abre una nueva terminal para aplicar los cambios de bash."
