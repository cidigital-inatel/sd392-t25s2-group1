
`timescale 1ns / 1ps

module instruction_decoder_tb;

    // Sinal que envia instrucoes ao Decoder
    reg [7:0] instruction;

    // Sinais de saida do Decoder
    wire load_en;
    wire compute_en;
    wire store_en;
    wire [3:0] parameter_out;

    // Instancia do modulo que vamos testar
    instruction_decoder dut (
        .instruction(instruction),
        .load_en(load_en),
        .compute_en(compute_en),
        .store_en(store_en),
        .parameter_out(parameter_out)
    );

    // Sequencia de testes
    initial begin

        // Teste 1: NOP
        instruction = 8'h00;
        #10;

        // Teste 2: LOAD com parametro 5
        instruction = 8'h15;
        #10;

        // Teste 3: COMPUTE com parametro 10
        instruction = 8'h2A;
        #10;

        // Teste 4: STORE com parametro 7
        instruction = 8'h37;
        #10;

        // Teste 5: opcode desconhecido
        instruction = 8'hF0;
        #10;

        // Encerra a simulacao
        $finish;

    end

endmodule
