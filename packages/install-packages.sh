#!/usr/bin/env bash
# Installs desktop/dev apps using APT, vendor .deb packages, or vendor tarballs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

green()  { printf '\033[1;32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$1"; }

require_sudo() {
    if ! sudo -v; then
        yellow "    sudo es necesario para instalar paquetes"
        exit 1
    fi
}

ubuntu_codename() {
    . /etc/os-release
    printf '%s\n' "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
}

arch() {
    dpkg --print-architecture
}

install_prerequisites() {
    green ">>> Instalando prerequisitos de instalacion"
    sudo apt-get update

    # Force-remove packages stuck in failed-config or half-installed state
    local broken
    broken=$(dpkg -l | awk '/^.[FH]/{print $2}')
    if [ -n "$broken" ]; then
        yellow "    Removiendo paquetes con estado roto: $broken"
        echo "$broken" | xargs sudo dpkg --remove --force-depends
    fi

    sudo apt-get install -f -y
    sudo apt-get install -y ca-certificates curl gpg tar unzip wget
}

dearmor_key() {
    local url="$1"
    local output="$2"

    if [ -s "$output" ]; then
        return
    fi

    sudo install -d -m 0755 "$(dirname "$output")"
    curl -fsSL "$url" | sudo gpg --dearmor -o "$output"
    sudo chmod 0644 "$output"
}

fetch_key() {
    local url="$1"
    local output="$2"

    if [ -s "$output" ]; then
        return
    fi

    sudo install -d -m 0755 "$(dirname "$output")"
    sudo curl -fsSL "$url" -o "$output"
    sudo chmod a+r "$output"
}

write_root_file() {
    local path="$1"
    local content="$2"

    if [ -f "$path" ] && [ "$(cat "$path")" = "$content" ]; then
        return
    fi

    printf '%s\n' "$content" | sudo tee "$path" >/dev/null
}

remove_snap_replacements() {
    if ! command -v snap >/dev/null 2>&1; then
        yellow ">>> snap no esta instalado; no hay paquetes snap que reemplazar"
        return
    fi

    green ">>> Quitando versiones Snap de las apps objetivo si existen"
    while IFS=$'\t' read -r snap_name _replacement; do
        case "$snap_name" in
            ''|'#'*) continue ;;
        esac

        if snap list "$snap_name" >/dev/null 2>&1; then
            yellow "    Removiendo snap: $snap_name"
            sudo snap remove "$snap_name"
        fi
    done < "$SCRIPT_DIR/snap-replacements.tsv"
}

configure_apt_repositories() {
    local codename
    local machine_arch

    codename="$(ubuntu_codename)"
    machine_arch="$(arch)"

    if [ -z "$codename" ]; then
        yellow "    No pude detectar el codename de Ubuntu; usando noble"
        codename="noble"
    fi

    green ">>> Configurando repositorios APT oficiales/de proveedor"

    # VS Code — https://code.visualstudio.com/docs/setup/linux
    dearmor_key "https://packages.microsoft.com/keys/microsoft.asc" "/usr/share/keyrings/microsoft.gpg"
    write_root_file "/etc/apt/sources.list.d/vscode.sources" \
"Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: $machine_arch
Signed-By: /usr/share/keyrings/microsoft.gpg"

    # Docker — https://docs.docker.com/engine/install/ubuntu/
    sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list
    fetch_key "https://download.docker.com/linux/ubuntu/gpg" "/etc/apt/keyrings/docker.asc"
    write_root_file "/etc/apt/sources.list.d/docker.sources" \
"Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $codename
Components: stable
Architectures: $machine_arch
Signed-By: /etc/apt/keyrings/docker.asc"

    # pgAdmin 4 — https://www.pgadmin.org/download/pgadmin-4-apt/
    dearmor_key "https://www.pgadmin.org/static/packages_pgadmin_org.pub" "/usr/share/keyrings/packages-pgadmin-org.gpg"
    write_root_file "/etc/apt/sources.list.d/pgadmin4.list" \
"deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$codename pgadmin4 main"

    # GitHub CLI — https://github.com/cli/cli/blob/trunk/docs/install_linux.md
    fetch_key "https://cli.github.com/packages/githubcli-archive-keyring.gpg" "/etc/apt/keyrings/githubcli-archive-keyring.gpg"
    write_root_file "/etc/apt/sources.list.d/github-cli.list" \
"deb [arch=$machine_arch signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"

    # Node.js 22 — https://github.com/nodesource/distributions
    if [ ! -f /etc/apt/sources.list.d/nodesource.list ]; then
        green ">>> Configurando repositorio NodeSource (Node.js 22)"
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    fi
}

install_apt_packages() {
    local packages=()
    local package

    green ">>> Instalando paquetes APT"
    sudo apt-get update

    while IFS= read -r package; do
        case "$package" in
            ''|'#'*) continue ;;
        esac
        packages+=("$package")
    done < "$SCRIPT_DIR/apt-packages.txt"

    sudo apt-get install -y "${packages[@]}"
}

install_pnpm() {
    if command -v pnpm >/dev/null 2>&1; then
        green "    pnpm ya esta instalado"
        return
    fi

    green ">>> Instalando pnpm"
    curl -fsSL https://get.pnpm.io/install.sh | sh -
}

install_brave() {
    if command -v brave-browser >/dev/null 2>&1; then
        green "    Brave ya esta instalado"
        return
    fi

    green ">>> Instalando Brave Browser"
    curl -fsSL https://dl.brave.com/install.sh | sh
}

install_dbeaver() {
    if dpkg-query -W -f='${Status}' dbeaver-ce 2>/dev/null | grep -q "install ok installed"; then
        green "    DBeaver CE ya esta instalado"
        return
    fi

    green ">>> Instalando DBeaver CE desde .deb oficial"
    curl -fL "https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb" -o /tmp/dbeaver-ce.deb
    sudo apt-get install -y /tmp/dbeaver-ce.deb
    rm -f /tmp/dbeaver-ce.deb
}

install_deb_from_url() {
    local package="$1"
    local url="$2"
    local output="$3"

    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
        green "    $package ya esta instalado"
        return
    fi

    green "    Instalando $package desde .deb"
    curl -fL --http1.1 "$url" -o "$output"
    sudo apt-get install -y "$output"
    rm -f "$output"
}

install_direct_debs() {
    if [ "$(arch)" != "amd64" ]; then
        yellow ">>> Discord y Zoom se omiten: estos .deb estan definidos para amd64"
        return
    fi

    green ">>> Instalando .deb directos de proveedor"
    install_deb_from_url "discord" "https://discord.com/api/download?platform=linux&format=deb" "/tmp/discord.deb"
    install_deb_from_url "zoom" "https://zoom.us/client/latest/zoom_amd64.deb" "/tmp/zoom_amd64.deb"
}

install_postman() {
    if [ -x /opt/Postman/Postman ]; then
        green "    Postman ya esta instalado en /opt/Postman"
        return
    fi

    green ">>> Instalando Postman desde tarball oficial"
    curl -fL "https://dl.pstmn.io/download/latest/linux64" -o /tmp/postman.tar.gz
    sudo tar -xzf /tmp/postman.tar.gz -C /opt
    sudo ln -sf /opt/Postman/Postman /usr/local/bin/postman
    sudo install -d -m 0755 /usr/local/share/applications
    sudo tee /usr/local/share/applications/postman.desktop >/dev/null <<'DESKTOP'
[Desktop Entry]
Encoding=UTF-8
Name=Postman
Exec=/opt/Postman/Postman %U
Icon=/opt/Postman/app/resources/app/assets/icon.png
Terminal=false
Type=Application
Categories=Development;
DESKTOP
    rm -f /tmp/postman.tar.gz
}

main() {
    require_sudo
    install_prerequisites
    remove_snap_replacements
    configure_apt_repositories
    install_apt_packages
    install_brave
    install_dbeaver
    install_pnpm
    install_direct_debs
    install_postman
}

main "$@"
