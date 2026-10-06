#!/usr/bin/env bash
# Instala o PetaLinux em $PETALINUX_DIR a partir do instalador em extern/.
#
# Uso: install.sh [--accept-license] [--force]
#   --accept-license  aceita as licenças da AMD/Xilinx sem exibi-las (instalação sem interação)
#   --force           apaga $PETALINUX_DIR e reinstala

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

accept=0
force=0
for arg in "$@"; do
    case "$arg" in
        --accept-license) accept=1 ;;
        --force) force=1 ;;
        *) die "opção desconhecida: $arg" ;;
    esac
done

require_not_root
require_linux_fs "$PETALINUX_DIR"

if is_installed && [ "$force" -eq 0 ]; then
    log "PetaLinux já instalado em $PETALINUX_DIR (use --force para reinstalar)."
    exit 0
fi

[ -n "$INSTALLER" ] || INSTALLER="$(find_extern "petalinux-v${PETALINUX_VERSION}-*-installer.run")"
[ -n "$INSTALLER" ] && [ -f "$INSTALLER" ] ||
    die "instalador não encontrado. Coloque o petalinux-v${PETALINUX_VERSION}-*-installer.run em $EXTERN_DIR"

if [ -d "$PETALINUX_DIR" ] && [ -n "$(ls -A "$PETALINUX_DIR")" ]; then
    [ "$force" -eq 1 ] ||
        die "$PETALINUX_DIR existe, mas não contém uma instalação completa. Use --force para apagar e reinstalar."
    log "removendo $PETALINUX_DIR"
    rm -rf "$PETALINUX_DIR"
fi
mkdir -p "$PETALINUX_DIR"

opts=(--dir "$PETALINUX_DIR" --platform "aarch64")
[ "$accept" -eq 1 ] && opts+=(-y)

# O instalador lê o próprio .run várias vezes e em /mnt/c (WSL) isso é muito lento.
case "$INSTALLER" in
    /mnt/*)
        tmp_installer="$HOME/.cache/plx/$(basename "$INSTALLER")"
        mkdir -p "$(dirname "$tmp_installer")"
        trap 'rm -f "$tmp_installer"' EXIT
        log "copiando o instalador para o filesystem Linux"
        cp "$INSTALLER" "$tmp_installer"
        INSTALLER="$tmp_installer"
        ;;
esac

log "instalando $(basename "$INSTALLER") em $PETALINUX_DIR (pode levar 20 minutos sem mostrar progresso)"
# O instalador grava o log no diretório atual.
cd "$HOME"
bash "$INSTALLER" "${opts[@]}" || die "o instalador falhou. Veja $HOME/petalinux_installation.log"

is_installed || die "instalação incompleta em $PETALINUX_DIR. Veja $HOME/petalinux_installation.log"
log "instalado. Para usar manualmente: source $PETALINUX_DIR/settings.sh"
