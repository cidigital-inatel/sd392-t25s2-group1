#!/usr/bin/env bash
# Cria o projeto PetaLinux em $PROJECTS_DIR/$PROJECT_NAME.
#
# Uso: create-project.sh [--template] [--force]
#   --template  cria a partir do template zynqMP em vez do BSP da ZCU102 (exige um XSA no config)
#   --force     apaga o projeto existente e cria de novo

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

template=0
force=0
for arg in "$@"; do
    case "$arg" in
        --template) template=1 ;;
        --force) force=1 ;;
        *) die "opção desconhecida: $arg" ;;
    esac
done

require_linux_fs "$PROJECTS_DIR"
load_petalinux

if [ -e "$PROJECT_DIR" ]; then
    [ "$force" -eq 1 ] || die "$PROJECT_DIR já existe (use --force para apagar e recriar)."
    log "removendo $PROJECT_DIR"
    rm -rf "$PROJECT_DIR"
fi

mkdir -p "$PROJECTS_DIR"
cd "$PROJECTS_DIR"

if [ "$template" -eq 1 ]; then
    log "criando $PROJECT_NAME a partir do template zynqMP"
    petalinux-create project --template zynqMP --name "$PROJECT_NAME"
else
    [ -n "$BSP" ] || BSP="$(find_extern "xilinx-zcu102-v${PETALINUX_VERSION}-*.bsp")"
    [ -n "$BSP" ] && [ -f "$BSP" ] ||
        die "BSP não encontrado. Coloque o xilinx-zcu102-v${PETALINUX_VERSION}-*.bsp em $EXTERN_DIR ou use --template."
    log "criando $PROJECT_NAME a partir de $(basename "$BSP")"
    petalinux-create project --source "$BSP" --name "$PROJECT_NAME"
fi

log "projeto criado em $PROJECT_DIR. Próximo: ./plx.sh config"
