#!/usr/bin/env bash
# Ponto de entrada do fluxo PetaLinux. Veja README.md.

source "$(dirname "${BASH_SOURCE[0]}")/scripts/common.sh"

usage() {
    cat <<EOF
Uso: ./plx.sh <comando> [opções]

  host-setup            instala as dependências do host (sudo)
  install               instala o PetaLinux      [--accept-license] [--force]
  create                cria o projeto           [--template] [--force]
  config                configura o projeto      [--xsa <arquivo>] [--menu] [-c <componente>]
  build                 compila                  [args do petalinux-build]
  package               gera o BOOT.BIN          [--no-fpga] [--wic]
  boot qemu|jtag        sobe a imagem no QEMU ou na placa
  all                   create + config + build + package
  shell                 abre um shell com o PetaLinux carregado, dentro do projeto
  status                mostra a configuração e o estado atual
EOF
}

status() {
    echo "Versão:     $PETALINUX_VERSION"
    echo "PetaLinux:  $PETALINUX_DIR $(is_installed && echo '[instalado]' || echo '[não instalado]')"
    echo "Projeto:    $PROJECT_DIR $([ -d "$PROJECT_DIR/project-spec" ] && echo '[criado]' || echo '[não criado]')"
    echo "Cache:      $SHARED_DIR"
    echo "Instalador: ${INSTALLER:-$(find_extern "petalinux-v${PETALINUX_VERSION}-*-installer.run")}"
    echo "BSP:        ${BSP:-$(find_extern "xilinx-zcu102-v${PETALINUX_VERSION}-*.bsp")}"
    echo "XSA:        ${XSA:-(nenhum; hardware do BSP)}"
    echo "BOOT.BIN:   $([ -f "$IMAGES_DIR/BOOT.BIN" ] && echo "$IMAGES_DIR/BOOT.BIN" || echo '(não gerado)')"
}

cmd="${1:-}"
[ $# -gt 0 ] && shift

case "$cmd" in
    host-setup) exec "$SCRIPTS_DIR/host-setup.sh" "$@" ;;
    install)    exec "$SCRIPTS_DIR/install.sh" "$@" ;;
    create)     exec "$SCRIPTS_DIR/create-project.sh" "$@" ;;
    config)     exec "$SCRIPTS_DIR/config.sh" "$@" ;;
    build)      exec "$SCRIPTS_DIR/build.sh" "$@" ;;
    package)    exec "$SCRIPTS_DIR/package.sh" "$@" ;;
    boot)       exec "$SCRIPTS_DIR/boot.sh" "$@" ;;
    all)
        [ -d "$PROJECT_DIR/project-spec" ] || "$SCRIPTS_DIR/create-project.sh"
        "$SCRIPTS_DIR/config.sh"
        "$SCRIPTS_DIR/build.sh"
        "$SCRIPTS_DIR/package.sh"
        ;;
    shell)
        load_petalinux
        require_project
        cd "$PROJECT_DIR"
        exec bash --rcfile <(echo "source ~/.bashrc; source '$PETALINUX_DIR/settings.sh' >/dev/null; PS1='(plx) '\$PS1")
        ;;
    status) status ;;
    ""|-h|--help|help) usage ;;
    *) usage; die "comando desconhecido: $cmd" ;;
esac
