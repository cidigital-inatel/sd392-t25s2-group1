#!/usr/bin/env bash
# Compila o projeto. Argumentos extras vão direto para o petalinux-build.
#
# Uso: build.sh [args do petalinux-build]
#   build.sh                  build completo
#   build.sh -c kernel        apenas o kernel
#   build.sh -c device-tree   apenas o device tree
#   build.sh --sdk            gera o SDK para compilar aplicações fora da placa
#   build.sh -x mrproper      limpa tudo (build, images e tmp)

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

load_petalinux
require_project
check_resources "$PROJECT_DIR"
cd "$PROJECT_DIR"

log "petalinux-build $*"
petalinux-build "$@"

if [ $# -eq 0 ]; then
    log "imagens em $IMAGES_DIR. Próximo: ./plx.sh package"
fi
