#!/usr/bin/env bash
# Funções e variáveis compartilhadas pelos scripts. Use com `source`.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLX_ROOT="$(dirname "$SCRIPTS_DIR")"
INSTALLER_DIR="$PLX_ROOT/installer"
BSP_DIR="$PLX_ROOT/bsp"

# shellcheck disable=SC1091
[ -f "$PLX_ROOT/config.local.env" ] && source "$PLX_ROOT/config.local.env"

source "$PLX_ROOT/config.env"

PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"
IMAGES_DIR="$PROJECT_DIR/images/linux"

log()  { printf '\033[1;32m[plx]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[plx] AVISO:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[plx] ERRO:\033[0m %s\n' "$*" >&2; exit 1; }

require_not_root() {
    [ "$(id -u)" -ne 0 ] || die "não rode como root; o PetaLinux recusa root."
}

# PetaLinux/Yocto não funcionam em NTFS (/mnt/c no WSL): sem symlinks/permissões reais.
require_linux_fs() {
    case "$1" in
        /mnt/[a-z]/*|/mnt/[a-z])
            die "$1 está em um drive do Windows. Use um caminho dentro do Linux (ex.: \$HOME)." ;;
    esac
}

# Último arquivo (em ordem alfabética) de um diretório que casa com o padrão, ou vazio.
find_file() {
    find "$1" -maxdepth 1 -type f -name "$2" 2>/dev/null | sort | tail -n 1
}

find_installer() { find_file "$INSTALLER_DIR" "petalinux-v${PETALINUX_VERSION}-*-installer.run"; }
find_bsp()       { find_file "$BSP_DIR" "*.bsp"; }


is_installed() {
    # O segundo arquivo só aparece no fim da instalação; sem ele, ela foi interrompida.
    [ -f "$PETALINUX_DIR/settings.sh" ] &&
        [ -f "$PETALINUX_DIR/.environment-setup-x86_64-petalinux-linux" ]
}

# Carrega o ambiente do PetaLinux no shell atual.
load_petalinux() {
    require_not_root
    is_installed || die "PetaLinux não encontrado em $PETALINUX_DIR. Rode: ./plx.sh install"
    # No WSL, pastas do Windows no PATH (/mnt/c/...) tornam cada busca de comando lenta
    # cheganado a fazer o bitbake estourar o timeout. Também evita pegar ferramentas diretas do Windows.
    PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v '^/mnt/' | paste -sd ':')"
    # settings.sh usa variáveis não definidas e comandos que retornam != 0.
    set +eu

    source "$PETALINUX_DIR/settings.sh" >/dev/null
    set -eu
    command -v petalinux-build >/dev/null || die "settings.sh carregado, mas petalinux-build não está no PATH."
}

require_project() {
    [ -d "$PROJECT_DIR/project-spec" ] || die "projeto não encontrado em $PROJECT_DIR. Rode: ./plx.sh create"
}

check_resources() {
    local mem_gb disk_gb
    mem_gb=$(awk '/MemTotal/ {printf "%d", $2/1024/1024 + 0.5}' /proc/meminfo)
    disk_gb=$(df -BG --output=avail "$1" | tail -n 1 | tr -dc '0-9')
    if [ "$mem_gb" -lt 8 ]; then
        warn "apenas ${mem_gb} GB de RAM. O build precisa de 8 GB ou mais (16 GB recomendado)."
        grep -qi microsoft /proc/version 2>/dev/null &&
            warn "no WSL, aumente em %UserProfile%\\.wslconfig: [wsl2] memory=16GB e rode 'wsl --shutdown'."
    fi
    [ "$disk_gb" -ge 100 ] || warn "apenas ${disk_gb} GB livres em $1 (recomendado: 100 GB)."
}
