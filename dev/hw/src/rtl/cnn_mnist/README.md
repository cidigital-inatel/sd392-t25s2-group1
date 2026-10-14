# CNN MNIST para o Block Design da ZCU102

Este diretório reúne a implementação RTL de inferência MNIST para a ZCU102
(`xczu9eg-ffvb1156-2-e`). O arquivo `zcu102_cnn_mnist_axis.v` é o **top level**
usado como **Module Reference** no Block Design. Ele adapta o fluxo AXI4-Stream para os dois FIFOs
do projeto. O top, a adaptação AXI4-Stream e a integração para a ZCU102 foram desenvolvidos neste projeto.

Os 16 arquivos `.mem` são os **pesos e vieses do modelo da equipe**, copiados de
`dev/application/model/weights_and_bias`, gerados pelo fluxo de treinamento e
quantização em `dev/application/training-cnn.ipynb`. Eles representam 796 valores
de 8 bits em Q1.7; não são os parâmetros da implementação RTL usada como base.

O pipeline é `conv1 -> ReLU/maxpool -> conv2 -> ReLU/maxpool -> fully_connected ->
comparator`. O top recebe o quadro em 784 bytes, alimenta o pipeline de forma contínua e segura o resultado até o FIFO de saída aceitá-lo. O caminho aritmético permanece o dos módulos de inferência reutilizados; os pesos carregados nesses módulos são os exportados pelo modelo da equipe.

| Interface | Fluxo | Sinais relevantes | Conteúdo |
| --- | --- | --- | --- |
| `S_AXIS` | FIFO de entrada -> CNN | `TDATA[7:0]`, `TKEEP[0]`, `TVALID`, `TREADY`, `TLAST` | 784 pixels de uma imagem 28×28, um byte por beat, em ordem raster |
| `M_AXIS` | CNN -> FIFO de saída | `TDATA[7:0]`, `TVALID`, `TREADY`, `TLAST` | Um byte por imagem: classe 0–9, com `TLAST=1` |

O último pixel deve ter `TLAST=1` e todos os beats devem ter `TKEEP[0]=1`.

Quadros curtos são descartados; quadros com mais de 784 bytes são drenados até `TLAST`. Não há saída de erro para esses casos. 

A CNN aceita apenas uma imagem por vez: `S_AXIS_TREADY` fica baixo durante a inferência e enquanto o resultado aguarda o FIFO de saída. `aresetn` deve ser o reset ativo baixo síncrono ao `aclk`. Depois do reset, é necessário reenviar a imagem inteira.

## Adicionar e conectar no Vivado

O `mpsoc_preset.bd` atual já contém `zcu102_cnn_mnist_axis_0` entre os FIFOs. Para reconstruir a conexão em uma cópia do projeto ainda sem esse bloco, abra `dev/hw/vivado/ai_fpga.xpr` no Vivado e execute no **Tcl Console**:

```tcl
source D:/CI_DIGITAL/Projeto/TCC/sd392-t25s2-group1/dev/hw/src/tcl/connect_zcu102_cnn_mnist_axis.tcl
```

O script adiciona os `.mem` da equipe ao projeto, reutiliza os `.v` já importados quando presentes, seleciona o módulo como Module Reference, conecta os dois FIFOs existentes e executa Validate/Save BD. Verifique em **Sources** que os 16 `.mem` constam como *Memory File* antes de gerar os produtos de saída. Ele foi escrito para `mpsoc_preset.bd` do `ai_fpga.xpr`; interrompe se as saídas dos FIFOs já estiverem conectadas. O Tcl deve ser executado na sessão do Vivado que já está aberta, para preservar as edições ainda não salvas na interface.

As ligações são:

```text
DMA/M_AXIS_MM2S -> axis_data_fifo_0/S_AXIS
axis_data_fifo_0/M_AXIS -> zcu102_cnn_mnist_axis_0/S_AXIS
zcu102_cnn_mnist_axis_0/M_AXIS -> axis_data_fifo_1/S_AXIS
axis_data_fifo_1/M_AXIS -> DMA/S_AXIS_S2MM
PS/pl_clk0 -> aclk; rst_ps8_0_99M/peripheral_aresetn -> aresetn
```

O BD atual já possui DMA de 8 bits, FIFO de entrada de 8 bits com `TKEEP`, FIFO de saída de 8 bits, clocks e resets comuns. Confira as opções de `TLAST` dos FIFOs e do DMA antes de gerar o bitstream. O software deve armar primeiro o canal DMA **S2MM** para receber **1 byte**, e então enviar **784 bytes** no canal **MM2S**. Um novo quadro só deve ser enviado após o resultado anterior.
Se o notebook for treinado novamente, copie seus 16 `.mem` atualizados para este diretório e repita a simulação antes de gerar um novo bitstream/XSA.

Depois do Validate BD, gere o HDL Wrapper, síntese, implementação e bitstream. Exporte o XSA com bitstream para a equipe PetaLinux. A integração de fontes e o teste funcional não substituem a análise de recursos/timing na ZCU102.

## Simulação

No diretório `sd392-t25s2-group1`:

```tcl
source dev/hw/src/tcl/sim_zcu102_cnn_mnist_axis.tcl
```

O testbench usa as imagens `dev/application/test/train_3.bmp` e `train_7.bmp`, convertidas para `1_0.mem` e `3_0.mem` em bytes de 28×28 em ordem raster.

O teste insere pausas de entrada e prende `TREADY` na saída. Os números nos nomes dos BMP identificam os **arquivos**, não as classes. O modelo PyTorch de `dev/application/model/cnn_mnist.pt` prevê, respectivamente, as classes **1** e **3** para essas imagens. Com os pesos da equipe, a simulação RTL no Vivado 2024.2 também retornou 1 e 3 e terminou com `PASS`. O projeto de simulação é criado em `dev/hw/build/cnn_mnist_sim` e não altera `ai_fpga.xpr`. Isso verifica esses casos; não mede a acurácia geral nem o timing na placa.
