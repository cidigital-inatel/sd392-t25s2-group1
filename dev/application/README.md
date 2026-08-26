# CNN para MNIST com exportação de parâmetros para FPGA

> feito por: Hyago Vieira Lemes Barbosa Sílva
> Líder técnico do G1-CIDigital

Este projeto treina uma rede neural convolucional (CNN) para reconhecer dígitos manuscritos do conjunto MNIST e converte seus pesos e vieses para uma representação de 8 bits adequada à inicialização de memórias em uma futura implementação em FPGA.

O objetivo principal é criar uma ponte didática entre dois mundos:

- **inteligência artificial em software**, usando Python e PyTorch;
- **circuitos digitais reconfiguráveis**, usando ponto fixo e memórias internas de FPGA.

> **Status atual:** o treinamento, o teste e a exportação dos parâmetros estão implementados. O repositório ainda precisa do circuito RTL, do testbench, da síntese e do teste em placa para se tornar uma implementação FPGA completa.

## Resumo rápido

| Item | Descrição |
| --- | --- |
| Aplicação | Classificação de dígitos manuscritos de `0` a `9` |
| Base de dados | MNIST: 60.000 imagens de treino e 10.000 de teste |
| Entrada | Imagem em tons de cinza de `28 × 28` pixels |
| Modelo | CNN com duas convoluções, dois max poolings e uma camada final |
| Parâmetros | 796 pesos e vieses treináveis |
| Precisão de software registrada originalmente | 9.614/10.000 imagens, ou 96.14% |
| Treinamento | PyTorch em `float32` |
| Formato de exportação | Ponto fixo assinado Q1.7, 8 bits |
| Arquivos para memória | `.mem` em texto hexadecimal |
| Implementação RTL/FPGA | Ainda não incluída |

A acurácia de 96.14% veio da execução preservada no notebook original. Ela serve como referência, mas deve ser medida novamente após cada treinamento. Também não deve ser apresentada como resultado da FPGA enquanto o hardware não reproduzir e validar toda a inferência.

O ponto principal é usar como referência este documento, e este modelo como teste para outros casos de aplicação de classificação de imagens para nossa NPU.

## Entendendo o projeto sem conhecimento prévio

### O que é classificação?

Classificar significa escolher uma categoria para uma entrada. Neste projeto, a entrada é uma imagem e as categorias possíveis são os dez dígitos. Para cada imagem, o modelo produz dez pontuações e escolhe a maior.

### O que é uma CNN?

Uma CNN é uma rede neural criada para processar dados organizados espacialmente, como imagens. Ela aplica pequenos filtros sobre diferentes regiões da imagem. Durante o treinamento, os valores desses filtros são aprendidos automaticamente.

As primeiras camadas tendem a responder a padrões simples. As camadas seguintes combinam essas respostas para distinguir formas mais completas.

### O que é uma FPGA?

Uma FPGA é um circuito integrado cuja lógica pode ser configurada pelo projetista. Em vez de executar uma lista de instruções como um processador comum, ela pode implementar diretamente multiplicadores, somadores, comparadores, memórias e máquinas de estados trabalhando em paralelo.

Isso pode oferecer baixa latência e bom uso de energia, mas exige que o cálculo seja descrito com precisão: largura de cada sinal, sinal, escala, arredondamento, ordem da memória e sincronismo.

## Fluxo da aplicação

1. o `torchvision` baixa e normaliza o MNIST;
2. o PyTorch treina a CNN em ponto flutuante;
3. o modelo é avaliado nas 10.000 imagens de teste;
4. o checkpoint é salvo em `model/cnn_mnist.pt`;
5. pesos e vieses são quantizados para Q1.7;
6. os valores assinados são codificados em complemento de dois;
7. cada conjunto de parâmetros é salvo em `.mem`;
8. em uma etapa futura, esses dados alimentarão memórias e blocos aritméticos descritos em Verilog ou VHDL.

## Arquitetura do modelo

| Etapa | Dimensão da saída | Parâmetros | Operação aproximada |
| --- | ---: | ---: | ---: |
| Entrada | `1 × 28 × 28` | 0 | — |
| Conv1: 3 filtros `5 × 5` | `3 × 24 × 24` | 78 | 43.200 MACs |
| MaxPool `2 × 2` + ReLU | `3 × 12 × 12` | 0 | Comparações |
| Conv2: 3 filtros `5 × 5 × 3` | `3 × 8 × 8` | 228 | 14.400 MACs |
| MaxPool `2 × 2` + ReLU | `3 × 4 × 4` | 0 | Comparações |
| Flatten | `48` | 0 | Reorganização |
| Fully connected | `10` | 490 | 480 MACs |
| **Total** | `10 classes` | **796** | **58.080 MACs** |

`MAC` significa multiplicação seguida de acumulação. A contagem ajuda a estimar o trabalho aritmético, mas não determina sozinha a latência: o resultado depende do número de multiplicadores paralelos e de como os dados são reutilizados no hardware.

### O cálculo aproximado dos MAC's

Basicamente é considerado cada camada convolucional, olhando como exemplo a primeira camada:

1. Primeira convolução
Entrada: 1 x 28 x 28
Filtros: 3 filtros de 5 x 5
Stride: 1
Padding: 0

Tamanho da saída: 28 - 5 + 1 = 24

Portanto a saída possui 3 x 24 x 24. Cada posição utiliza 1 x 5 x 5 = 25 MACs:

MACconv1 = 3 x 24 x 24 x 25 = MACconv1 = 43200

O `log_softmax` usado no treinamento não precisa ser implementado na FPGA se o objetivo for apenas escolher a classe. O índice da maior pontuação dos dez *logits* já produz a mesma decisão.

## Como executar

### 1. Criar um ambiente virtual

Linux/macOS:

```bash
python -m venv .venv
source .venv/bin/activate
```

Windows PowerShell:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

Ou utilize o conda. Crie o ambiente conda, com o seguinte comando:

```Powershell
conda create -n cidigital-g1 python=3.10
conda activate cidigital-g1
```

### 2. Instalar as dependências

```bash
pip install torch torchvision numpy matplotlib pillow jupyter
```

### 3. Abrir o notebook

Abra o arquivo em `.\application\training-cnn.ipynb`

## O que significa Q1.7?

O PyTorch normalmente representa cada peso com 32 bits em ponto flutuante. No hardware, este projeto aproxima os parâmetros por números assinados de 8 bits em ponto fixo.

Na convenção usada aqui, Q1.7 possui:

- um bit de sinal;
- sete bits fracionários;
- escala igual a `2⁷ = 128`;

Fazemos o truncamento usando essencialmente int(valor x 128)

## Diferença entre `.pt`, `.mem`

| Formato | O que contém | Uso |
| --- | --- | --- |
| `.pt` | Estruturas e tensores do checkpoint PyTorch | Recarregar o modelo em Python |
| `.mem` | Texto hexadecimal, um byte Q1.7 por token | Inicializar memória em simulação/síntese HDL |

## Arquivos de parâmetros gerados

| Camada | Arquivos | Valores |
| --- | ---: | ---: |
| Conv1 | `conv1_weight_1.mem` a `conv1_weight_3.mem` | 75 pesos |
| Conv1 | `conv1_bias.mem` | 3 vieses |
| Conv2 | `conv2_weight_11.mem` a `conv2_weight_33.mem` | 225 pesos |
| Conv2 | `conv2_bias.mem` | 3 vieses |
| Camada final | `fc_weight.mem` | 480 pesos |
| Camada final | `fc_bias.mem` | 10 vieses |
| **Total** | **16 arquivos `.mem`** | **796 valores** |
