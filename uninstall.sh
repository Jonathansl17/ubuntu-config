#!/usr/bin/env bash
# uninstall.sh — Elimina todas las apps gestionadas por install.sh.
# Uso: ./uninstall.sh

set -euo pipefail

yellow() { printf '\033[1;33m%s\033[0m\n' "$1"; }
green()  { printf '\033[1;32m%s\033[0m\n' "$1"; }

sudo apt-get remove -y --purge \
    postgresql postgresql-client \
    vlc \
    copyq \
    xournalpp \
    obs-studio \
    gh \
    fastfetch \
    code \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    pgadmin4-desktop \
    brave-browser \
    dbeaver-ce \
    nodejs \
    discord \
    zoom \
    2>/dev/null || true

if [ -d /opt/Postman ]; then
    yellow ">>> Eliminando Postman"
    sudo rm -rf /opt/Postman
    sudo rm -f /usr/local/bin/postman
    sudo rm -f /usr/local/share/applications/postman.desktop
fi

sudo apt-get autoremove -y
sudo apt-get autoclean

green "Listo. Corre ./install.sh para reinstalar todo."
