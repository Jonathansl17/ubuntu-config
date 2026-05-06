#!/usr/bin/env bash
# disable-telemetry.sh — Desactiva la telemetría de Ubuntu y las apps instaladas.
# Se puede ejecutar de forma independiente o a través de install.sh.

set -euo pipefail

green()  { printf '\033[1;32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$1"; }

# ──────────────────────────────────────────────
# Ubuntu / Canonical
# ──────────────────────────────────────────────

disable_whoopsie() {
    green ">>> Desactivando whoopsie (crash reporter de Canonical)"
    if systemctl list-unit-files whoopsie.service &>/dev/null; then
        sudo systemctl stop whoopsie    2>/dev/null || true
        sudo systemctl disable whoopsie 2>/dev/null || true
    else
        yellow "    whoopsie no está instalado — nada que hacer"
    fi
}

disable_apport() {
    green ">>> Desactivando apport (recolector de crashes)"
    if systemctl list-unit-files apport.service &>/dev/null; then
        sudo systemctl stop apport    2>/dev/null || true
        sudo systemctl disable apport 2>/dev/null || true
    fi

    # Deshabilita también a nivel de configuración para que no se reactive
    local apport_conf="/etc/default/apport"
    if [ -f "$apport_conf" ]; then
        sudo sed -i 's/^enabled=.*/enabled=0/' "$apport_conf"
        green "    apport desactivado en $apport_conf"
    fi
}

disable_ubuntu_report() {
    green ">>> Enviando respuesta negativa a ubuntu-report"
    if command -v ubuntu-report &>/dev/null; then
        ubuntu-report send no 2>/dev/null || true
    else
        yellow "    ubuntu-report no está instalado — nada que hacer"
    fi
}

disable_popularity_contest() {
    green ">>> Desactivando popularity-contest (popcon)"
    if [ -f /etc/popularity-contest.conf ]; then
        sudo sed -i 's/^PARTICIPATE=.*/PARTICIPATE=no/' /etc/popularity-contest.conf
        green "    popularity-contest desactivado"
    else
        # Escribe la configuración aunque el archivo no exista todavía
        printf 'PARTICIPATE=no\n' | sudo tee /etc/popularity-contest.conf >/dev/null
        green "    /etc/popularity-contest.conf creado con PARTICIPATE=no"
    fi
}

# ──────────────────────────────────────────────
# VS Code
# ──────────────────────────────────────────────

disable_vscode_telemetry() {
    green ">>> Desactivando telemetría de VS Code"
    local vscode_settings_dir="$HOME/.config/Code/User"
    local vscode_settings="$vscode_settings_dir/settings.json"

    mkdir -p "$vscode_settings_dir"

    if [ ! -f "$vscode_settings" ]; then
        printf '{\n    "telemetry.telemetryLevel": "off"\n}\n' > "$vscode_settings"
        green "    settings.json creado con telemetría desactivada"
        return
    fi

    # Si ya existe el archivo, agrega/actualiza la clave usando Python
    # (evita depender de jq que puede no estar instalado)
    if python3 - "$vscode_settings" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
if data.get("telemetry.telemetryLevel") == "off":
    sys.exit(0)   # ya está correcto
data["telemetry.telemetryLevel"] = "off"
with open(path, "w") as f:
    json.dump(data, f, indent=4)
    f.write("\n")
PY
    then
        green "    telemetry.telemetryLevel = off aplicado en settings.json"
    else
        yellow "    No se pudo editar settings.json automáticamente — edítalo manualmente"
    fi
}

# ──────────────────────────────────────────────
# npm
# ──────────────────────────────────────────────

disable_npm_telemetry() {
    if ! command -v npm &>/dev/null; then
        yellow ">>> npm no está instalado — saltando"
        return
    fi

    green ">>> Desactivando telemetría de npm"
    # Desactiva el banner de financiación y el update-notifier
    npm config set fund false    --location=user
    npm config set update-notifier false --location=user 2>/dev/null || true
    green "    npm: fund=false, update-notifier=false"
}

# ──────────────────────────────────────────────

main() {
    disable_whoopsie
    disable_apport
    disable_ubuntu_report
    disable_popularity_contest
    disable_vscode_telemetry
    disable_npm_telemetry
    green ""
    green "Telemetría desactivada."
}

main "$@"
