# PetaLinux para a ZCU102

Scripts para instalar o PetaLinux 2024.2 e gerar o Linux da ZCU102.

O QEMU não precisa ser instalado: o PetaLinux já inclui a versão da AMD (qemu-xilinx), que emula a ZCU102.

Atualmente, a imagem usa o hardware de referência do BSP, com o XSA padrão embutido, que não contém a NPU. A NPU será integrada mais à frente, quando o time de hardware exportar o `.xsa` do design com ela.

## Pré-requisitos

- Ubuntu 22.04 (nativo ou WSL2: `wsl --install -d Ubuntu-22.04`), 8 GB de RAM ou mais e 100 GB livres. Os scripts foram testados nessa versão, sendo assim se for executar em outra, pode ser necessário adequar alguns pontos.
- No WSL2, ajuste a memória em `%UserProfile%\.wslconfig` e rode `wsl --shutdown`:

  ```ini
  [wsl2]
  memory=7GB
  swap=16GB
  ```

- Arquivos da AMD (não versionados, o download exige login):

  | Arquivo | Pasta | Download |
  | :--- | :--- | :--- |
  | `petalinux-v2024.2-*-installer.run` | `installer/` | [AMD Downloads 2024.2: PetaLinux Tools](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools/2024-2.html) (*PetaLinux Tools - Installer*) |
  | `xilinx-zcu102-v2024.2-*.bsp` | `bsp/` | Mesma página, seção *PetaLinux Board Support Packages* (*ZCU102 BSP*) |
  | `.xsa` base da ZCU102 | — | Já vem dentro do BSP; após o `create`, fica em `~/projetos/zcu102-npu/hardware/xilinx-zcu102-2024.2/outputs/project_1.xsa` |

O PetaLinux e o projeto ficam em `$HOME` no Linux; não funcionam em `/mnt/c`.

## Estrutura

| Pasta | Conteúdo |
| :--- | :--- |
| `scripts/` | Scripts chamados pelo `plx.sh` |
| `installer/` | Instalador do PetaLinux (não versionado) |
| `bsp/` | BSP usado para criar o projeto |
| `xsa/` | `.xsa` do design com a NPU (futuro) |
| `src/` | Receitas BitBake de softwares e drivers incluídos na imagem (futuro) |

## Uso

```bash
cd dev/sw/petalinux
./plx.sh host-setup                 # dependências (sudo), uma vez
./plx.sh install --accept-license   # PetaLinux, uma vez
./plx.sh all                        # create + config + build + package
```

O primeiro build leva horas; os seguintes, minutos (cache em `~/petalinux-shared`).

| Comando | O que faz |
| :--- | :--- |
| `status` | Mostra caminhos e o estado atual |
| `create [--template] [--force]` | Cria o projeto a partir do BSP (ou do template `zynqMP`) |
| `config [--xsa <arq>] [--menu] [-c <comp>]` | Importa o XSA e configura (`-c kernel`, `-c rootfs`) |
| `build [args]` | Compila; argumentos vão para o `petalinux-build` (ex.: `--sdk`) |
| `package [--no-fpga] [--wic]` | Gera o `BOOT.BIN` |
| `boot qemu\|jtag` | Sobe a imagem no QEMU (sair: `Ctrl+A`, `X`) ou via JTAG |
| `shell` | Shell no projeto com os comandos `petalinux-*` |

## Hardware da NPU

A NPU ainda não está no projeto: será implementada em RTL pelo time de hardware e integrada nesta etapa, mais à frente. Até lá, o projeto usa o `.xsa` base do BSP, que serve para validar o fluxo e a placa.

Quando o `.xsa` com a NPU estiver pronto (exportado no Vivado com bitstream), salve em `xsa/` e rode:

```bash
./plx.sh config --xsa xsa/<design>.xsa
./plx.sh build && ./plx.sh package
```

## Configuração

Padrões em [config.env](config.env). Para ajustes locais, crie `config.local.env` ou passe a variável no comando (`PROJECT_NAME=teste ./plx.sh create`).

## Problemas comuns

- **`$'\r': command not found`**: arquivo com CRLF. Rode `git add --renormalize dev/sw`.
- **`Killed` no build**: falta de RAM. Aumente a memória do WSL ou reduza `PARALLEL_JOBS`.
- **Timeout do bitbake**: rode o comando de novo.

## Referências

1. AMD. PetaLinux Tools Documentation: Reference Guide - UG1144. Versão 2024.2. Disponível em: <https://docs.amd.com/r/2024.2-English/ug1144-petalinux-tools-reference-guide>. Acesso em: 5 out. 2026.
2. AMD. ZCU102 Evaluation Board User Guide - UG1182. Versão 1.7, 2023. Disponível em: <https://docs.amd.com/v/u/en-US/ug1182-zcu102-eval-bd>. Acesso em: 5 out. 2026.
3. YOCTO PROJECT. Yocto Project Reference Manual. Disponível em: <https://docs.yoctoproject.org/ref-manual/index.html>. Acesso em: 5 out. 2026.
