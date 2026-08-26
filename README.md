![LogoCIDigital](./doc/img/Logo_CIDigital.png)

# Programa CI DIGITAL - Polo INATEL

[EN] The CI Digital Program is an initiative of the Ministry of Science, Technology and Innovation (MCTI), in partnership with Softex, aimed at training professionals for the Brazilian semiconductor industry. The program is designed to train up to 350 professionals in the field of microelectronics, with the goal of positioning Brazil as a competent hub for the development of high-complexity, high-value digital integrated circuit projects.

[PT-BR] O Programa CI Digital é uma iniciativa do Ministério de Ciência, Tecnologia e Inovação (MCTI) junto à Softex para capacitação de profissionais para a indústria brasileira de semicondutores. O programa destina-se à capacitação de até 350 profissionais para a área de microeletrônica com intuito de posicionar o país como um centro competente de desenvolvimento de projetos de circuitos integrados digitais de alta complexidade e valor agregado.

## [T25S2] - SD392: Grupo 1

### Descrição

Este repositório reúne o desenvolvimento de uma plataforma Edge-AI baseada na FPGA SoC ZCU102, integrando uma aplicação de referência em inteligência artificial, uma futura NPU parametrizável em RTL e software Linux embarcado. Como demonstração inicial, foi desenvolvida uma CNN em PyTorch para classificação do dataset MNIST, com 796 parâmetros treináveis e exportação dos pesos e vieses para 16 arquivos .mem em representação inteira de 8 bits.

Atualmente, o modelo em ponto flutuante, o treinamento e a exportação dos parâmetros estão disponíveis. A implementação da NPU em RTL, a referência integral em ponto fixo, o software embarcado, a síntese, o bitstream e a validação na placa FPGA permanecem em desenvolvimento.

Documentação: [Aplicação de IA](/dev/application/README.md) | [Hardware e RTL](/dev/hw/README.md)

## Componentes / Colaboradores

| | ESTUDANTE | FUNÇÃO |
| :---: | :--- | :--- |
| 1 | Elivander | Orientador |
| 2 | Hyago Vieira | Líder técnico |
| 3 | Emmanuel Titus | Aplicação IA |
| 4 | Ronan Cassemiro | Aplicação IA |
| 5 | Gabriel Alves | Aplicação IA |
| 6 | André Luis da Silva | Design RTL HW |
| 7 | Érica  Rodrigues | Design RTL HW |
| 8 | Jones Nambundo | Design RTL HW |
| 9 | Gustavo Faustino | Design RTL HW |
| 10 | Breno Luís | Design RTL HW |
| 11 | Douglas Brandão | Software Embarcado |
| 12 | Daniel Nunes | Software Embarcado |
| 13 | Matheus Brandani | Software Embarcado |
| 14 | Carlos Miguel | Software Embarcado |
| 15 | André Bezerra | Referencial técnico |
| 16 | Bárbara Rocha | Referencial técnico |

## Referências

As referências a seguir fundamentam as frentes de aplicação, software embarcado e hardware. As referências anteriormente inseridas foram mantidas; as fontes adicionais abrangem Edge Computing, CNNs, MNIST, PyTorch, quantização, aceleradores em FPGA e interfaces AMBA AXI.

### Aplicação

1. PYTORCH. MNIST - Torchvision main documentation. Disponível em: [https://docs.pytorch.org/vision/main/generated/torchvision.datasets.MNIST.html]. Acesso em: 25 ago. 2026.

2. PYTORCH. ToTensor - Torchvision main documentation. Disponível em: [https://docs.pytorch.org/vision/main/generated/torchvision.transforms.ToTensor].htmlAcesso em: 25 ago. 2026.

3. LECUN, Yann; BOTTOU, Léon; BENGIO, Yoshua; HAFFNER, Patrick. Gradient-based learning applied to document recognition. Proceedings of the IEEE, v. 86, n. 11, p. 2278–2324, 1998. DOI: 10.1109/5.726791. Disponível em: [https://ieeexplore.ieee.org/document/726791]. Acesso em: 25 ago. 2026.

4. PYTORCH. Conv2d - PyTorch documentation. Disponível em: [https://docs.pytorch.org/docs/2.13/generated/torch.nn.Conv2d.html]. Acesso em: 25 ago. 2026.
PYTORCH.

5. MaxPool2d - PyTorch documentation. Disponível em:[https://docs.pytorch.org/docs/2.13/generated/torch.nn.MaxPool2d.html]. Acesso em: 25 ago. 2026.

6. PYTORCH. Linear - PyTorch documentation. Disponível em: [https://docs.pytorch.org/docs/2.13/generated/torch.nn.modules.linear.Linear.html]. Acesso em: 25 ago. 2026.

7. PYTORCH. SGD - PyTorch documentation. Disponível em: [https://docs.pytorch.org/docs/2.13/generated/torch.optim.SGD.html]. Acesso em: 25 ago. 2026.

8. PYTORCH. NLLLoss - PyTorch documentation. Disponível em: [https://docs.pytorch.org/docs/2.13/generated/torch.nn.NLLLoss.html]. Acesso em: 25 ago. 2026.

9. PYTORCH. Saving and Loading Models. PyTorch Tutorials. Disponível em: [https://docs.pytorch.org/tutorials/beginner/saving_loading_models.html]. Acesso em: 25 ago. 2026.

10. NUMPY. numpy.savetxt - NumPy reference. Disponível em: [https://numpy.org/doc/stable/reference/generated/numpy.savetxt.html]. Acesso em: 25 ago. 2026.
AMD.

11. Loading Memory Contents With File I/O Tasks. In: Vivado Design Suite User Guide: Synthesis - UG901. Disponível em: [https://docs.amd.com/r/en-US/ug901-vivado-synthesis/Loading-Memory-Contents-With-File-I/O-Tasks] . Acesso em: 25 ago. 2026.

### Software Embarcado

1. HUONG, Dang Mai. Development of Linux Distribution Using Yocto Project. 2022. 43 p. Bachelor’s Thesis — Vaasan University of Applied Sciences, Vaasa, 2022. Disponível em: [https://www.theseus.fi/handle/10024/746135]. Acesso em: 24 ago. 2026.

2. HERMAN, Yurii; KRULIKOVSKYI, Oleh; HALIUK, Serhii; SUBBOTIN, Sergey. Development of an embedded operating system based on the Linux kernel for SoC FPGA. CEUR Workshop Proceedings, v. 3702, p. 376–388, 2024. Disponível em: [http://ceurspt.wikidata.dbis.rwth-aachen.de/Vol-3702/paper31.pdf]. Acesso em: 24 ago. 2026.

3. LIKELY, Grant; BOYER, Josh. A Symphony of Flavours: Using the Device Tree to Describe Embedded Hardware. In: Ottawa Linux Symposium, v. 2, p. 27–38, 2008. Disponível em: [https://www.landley.net/kdocs/ols/2008/ols2008v2-pages-27-38.pdf]. Acesso em: 24 ago. 2026.

4. GONZÁLEZ, Alex. Embedded Linux Projects Using Yocto Project Cookbook. Birmingham: Packt Publishing, 2015. ISBN 978-1-78439-518-6. Disponível em: [https://digi.eccee.com/_media/digi/arm-embedded/linux/dey/embedded_linux_projects_using_yocto_project_cookbook.pdf]. Acesso em: 24 ago. 2026.

5. FLAMINIO, Alessandro. Embedded Linux distro development with the Yocto Project. 2018. 101 p. Dissertação — Politecnico di Torino, Corso di Laurea Magistrale in Ingegneria Informatica, Torino, 2018. Disponível em: [https://webthesis.biblio.polito.it/9085/]. Acesso em: 24 ago. 2026.

6. BELLARD, Fabrice. QEMU, a Fast and Portable Dynamic Translator. In: USENIX ANNUAL TECHNICAL CONFERENCE, 2005, Anaheim. Proceedings of the FREENIX Track: 2005 USENIX Annual Technical Conference. Berkeley: USENIX Association, 2005. p. 41–46. Disponível em: [https://www.usenix.org/legacy/event/usenix05/tech/freenix/full_papers/bellard/bellard.pdf]. Acesso em: 24 ago. 2026.

### Hardware

1. ZHANG, Chen et al. Optimizing FPGA-based Accelerator Design for Deep Convolutional Neural Networks. In: ACM/SIGDA INTERNATIONAL SYMPOSIUM ON FIELD-PROGRAMMABLE GATE ARRAYS, 2015. p. 161-170. DOI: 10.1145/2684746.2689060. Disponível em: [https://dl.acm.org/doi/10.1145/2684746.2689060]. Acesso em: 24 ago. 2026.

2. ARM LIMITED. AMBA AXI and ACE Protocol Specification. Documento IHI 0022. Disponível em: [https://developer.arm.com/documentation/ihi0022/d/]. Acesso em: 24 ago. 2026.

3. AMD. Zynq-7000 SoC Technical Reference Manual: UG585. Versão 1.15, 2026. Disponível em: [https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM]. Acesso em: 24 ago. 2026.

4. SHI, Weisong; CAO, Jie; ZHANG, Quan; LI, Youhuizi; XU, Lanyu. Edge Computing: Vision and Challenges. IEEE Internet of Things Journal, v. 3, n. 5, p. 637-646, 2016. DOI: 10.1109/JIOT.2016.2579198. Disponível em: [https://ieeexplore.ieee.org/document/7488250]. Acesso em: 24 ago. 2026.

5. LECUN, Yann; BOTTOU, Léon; BENGIO, Yoshua; HAFFNER, Patrick. Gradient-Based Learning Applied to Document Recognition. Proceedings of the IEEE, v. 86, n. 11, p. 2278-2324, 1998. DOI: 10.1109/5.726791. Disponível em: [https://ieeexplore.ieee.org/document/726791]. Acesso em: 24 ago. 2026.

6. JACOB, Benoit et al. Quantization and Training of Neural Networks for Efficient Integer-Arithmetic-Only Inference. In: IEEE/CVF CONFERENCE ON COMPUTER VISION AND PATTERN RECOGNITION, 2018. p. 2704-2713. Disponível em: [https://openaccess.thecvf.com/content_cvpr_2018/html/Jacob_Quantization_and_Training_CVPR_2018_paper.html]. Acesso em: 24 ago. 2026.

7. UMUROGLU, Yaman et al. FINN: A Framework for Fast, Scalable Binarized Neural Network Inference. In: ACM/SIGDA INTERNATIONAL SYMPOSIUM ON FIELD-PROGRAMMABLE GATE ARRAYS, 2017. p. 65-74. DOI: 10.1145/3020078.3021744. Disponível em: [https://dl.acm.org/doi/10.1145/3020078.3021744]. Acesso em: 24 ago. 2026.

8. AMD. ZCU102 Evaluation Board User Guide: UG1182. Versão 1.7, 2023. Disponível em: [https://docs.amd.com/v/u/en-US/ug1182-zcu102-eval-bd]. Acesso em: 25 ago. 2026.

9. AMD. Zynq UltraScale+ MPSoC Accelerated Image Classification via Binary Neural Network TechTip. AMD Adaptive Computing Wiki, 2019. Disponível em: [https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841949/Zynq%2BUltraScale%2BMPSoC%2BAccelerated%2BImage%2BClassification%2Bvia%2BBinary%2BNeural%2BNetwork%2BTechTip]. Acesso em: 25 ago. 2026.

10. AMD. MIPI CSI-2 Receiver Subsystem: PG232 – Introduction. Versão 6.0. Disponível em: [https://docs.amd.com/r/en-US/pg232-mipi-csi2-rx/Introduction]. Acesso em: 25 ago. 2026.

11. AMD. Zynq UltraScale+ MPSoC Accelerated Image Classification via Binary Neural Network TechTip. AMD Adaptive Computing Wiki, 2019. Disponível em: [https://xilinx-wiki.atlassian.net/wiki/x/XYEfAQ]. Acesso em: 25 ago. 2026.
