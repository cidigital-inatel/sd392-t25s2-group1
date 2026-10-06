#!/usr/bin/env bash
# Sobe a imagem compilada no QEMU ou na placa via JTAG.
#
# Uso: boot.sh qemu|jtag
#   qemu  emula a ZCU102 (a PL/NPU não é emulada); sair com Ctrl+A, X
#   jtag  carrega bitstream + kernel na placa (chaves de boot SW6 em JTAG)

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

mode="${1:-}"
load_petalinux
require_project
cd "$PROJECT_DIR"

case "$mode" in
    qemu) petalinux-boot qemu --kernel ;;
    jtag) petalinux-boot jtag --kernel --fpga ;;
    *) die "uso: boot.sh qemu|jtag" ;;
esac
