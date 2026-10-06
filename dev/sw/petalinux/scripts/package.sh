#!/usr/bin/env bash
# Gera o BOOT.BIN (FSBL + PMUFW + bitstream + TF-A + U-Boot) e, opcionalmente, a imagem de SD.
#
# Uso: package.sh [--no-fpga] [--wic]
#   --no-fpga  não embute o bitstream no BOOT.BIN
#   --wic      gera também images/linux/petalinux-sdimage.wic para gravar no cartão SD

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

fpga=1
wic=0
for arg in "$@"; do
    case "$arg" in
        --no-fpga) fpga=0 ;;
        --wic) wic=1 ;;
        *) die "opção desconhecida: $arg" ;;
    esac
done

load_petalinux
require_project
[ -f "$IMAGES_DIR/u-boot.elf" ] || die "imagens não encontradas em $IMAGES_DIR. Rode: ./plx.sh build"
cd "$PROJECT_DIR"

opts=(--u-boot --force)
if [ "$fpga" -eq 1 ]; then
    [ -f "$IMAGES_DIR/system.bit" ] || die "$IMAGES_DIR/system.bit não existe; use --no-fpga ou importe um XSA com bitstream."
    opts+=(--fpga "$IMAGES_DIR/system.bit")
fi

log "gerando BOOT.BIN"
petalinux-package boot "${opts[@]}"

if [ "$wic" -eq 1 ]; then
    log "gerando imagem WIC"
    petalinux-package wic
fi

log "pronto: $IMAGES_DIR/BOOT.BIN"
