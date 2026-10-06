#!/usr/bin/env bash
# Prepara o host Ubuntu (20.04/22.04, nativo ou WSL2) para o PetaLinux.
# Instala dependências, garante /bin/sh -> bash e o locale en_US.UTF-8. Usa sudo.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_not_root
command -v apt-get >/dev/null || die "este script suporta apenas Ubuntu/Debian (apt)."

PACKAGES=(
    iproute2 gawk python3 python3-pexpect python3-pip python3-git python3-jinja2
    build-essential gcc-multilib make net-tools libncurses5-dev zlib1g-dev
    libssl-dev flex bison libselinux1 gnupg wget git diffstat chrpath socat
    xterm autoconf libtool tar unzip texinfo xz-utils debianutils iputils-ping
    libegl1-mesa libsdl1.2-dev pylint cpio lz4 zstd rsync bc file locales
    libtinfo5 screen pax gzip tftpd-hpa zlib1g:i386
)

log "habilitando arquitetura i386 e instalando dependências"
sudo dpkg --add-architecture i386
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${PACKAGES[@]}"

if [ "$(readlink -f /bin/sh)" != "$(readlink -f /bin/bash)" ]; then
    log "apontando /bin/sh para bash (o PetaLinux não funciona com dash)"
    echo "dash dash/sh boolean false" | sudo debconf-set-selections
    sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
fi

if ! locale -a | grep -qi '^en_US\.utf-\?8$'; then
    log "gerando locale en_US.UTF-8"
    sudo locale-gen en_US.UTF-8
fi

mkdir -p "$PROJECTS_DIR" "$SHARED_DIR/downloads" "$SHARED_DIR/sstate-cache"
check_resources "$HOME"
log "host pronto."
