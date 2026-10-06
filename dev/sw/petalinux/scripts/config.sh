#!/usr/bin/env bash
# Configura o projeto: cache compartilhado, importação do XSA e menuconfig opcional.
#
# Uso: config.sh [--xsa <arquivo.xsa>] [--menu] [-c <componente>]
#   --xsa   hardware exportado pelo Vivado (padrão: $XSA; vazio mantém o hardware atual do projeto)
#   --menu  abre o menuconfig em vez de configurar em modo silencioso
#   -c      configura um componente: kernel, rootfs, u-boot...

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

menu=0
component=""
while [ $# -gt 0 ]; do
    case "$1" in
        --xsa) XSA="${2:?--xsa exige um arquivo}"; shift ;;
        --menu) menu=1 ;;
        -c) component="${2:?-c exige um componente}"; shift ;;
        *) die "opção desconhecida: $1" ;;
    esac
    shift
done

load_petalinux
require_project
cd "$PROJECT_DIR"

if [ -n "$component" ]; then
    petalinux-config -c "$component"
    exit 0
fi

# Bloco gerenciado pelo plx, reescrito a cada execução:
# cache compartilhado (evita baixar e recompilar tudo a cada projeto) e limite de paralelismo.
bspconf="project-spec/meta-user/conf/petalinuxbsp.conf"
begin="# plx: inicio"
end="# plx: fim"
mkdir -p "$SHARED_DIR/downloads" "$SHARED_DIR/sstate-cache"
sed -i "/^$begin\$/,/^$end\$/d" "$bspconf"
log "cache em $SHARED_DIR, $PARALLEL_JOBS tarefas em paralelo"
cat >> "$bspconf" <<EOF
$begin
DL_DIR = "$SHARED_DIR/downloads"
SSTATE_DIR = "$SHARED_DIR/sstate-cache"
BB_NUMBER_THREADS = "$PARALLEL_JOBS"
PARALLEL_MAKE = "-j $PARALLEL_JOBS"
$end
EOF

if [ ! -d /tftpboot ]; then
    sed -i 's/^CONFIG_SUBSYSTEM_COPY_TO_TFTPBOOT=y$/# CONFIG_SUBSYSTEM_COPY_TO_TFTPBOOT is not set/' \
        project-spec/configs/config
fi

[ -z "$XSA" ] || [ -f "$XSA" ] || die "XSA não encontrado: $XSA"
opts=()
if [ -n "$XSA" ]; then
    log "importando hardware: $XSA"
    opts+=("--get-hw-description=$XSA")
else
    warn "nenhum XSA informado; mantendo o hardware de referência do projeto (sem a NPU)."
fi
[ "$menu" -eq 1 ] || opts+=(--silentconfig)

petalinux-config "${opts[@]}"
log "configurado. Próximo: ./plx.sh build"
