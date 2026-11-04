
`timescale 1ns / 1ps

module instruction_fetch_tb;

    // ==========================================
    // 1. ENTRADAS CONTROLADAS PELO TESTBENCH
    // ==========================================

    reg clk;
    reg reset;
    reg enable;


    // ==========================================
    // 2. SAIDAS DO INSTRUCTION FETCH
    // ==========================================

    wire [7:0] instruction;
    wire [2:0] pc;
    wire valid;


    // ==========================================
    // 3. INSTANCIA DO INSTRUCTION FETCH
    // ==========================================

    instruction_fetch dut (
        .clk         (clk),
        .reset       (reset),
        .enable      (enable),
        .instruction (instruction),
        .pc          (pc),
        .valid       (valid)
    );


    // ==========================================
    // 4. GERACAO DO CLOCK
    // ==========================================

    // Inicializa o clock em zero
    initial begin
        clk = 1'b0;
    end

    // Inverte o clock a cada 5 ns
    // Periodo total = 10 ns (100 MHz)
    always #5 clk = ~clk;


    // ==========================================
    // 5. ESTIMULOS DA SIMULACAO
    // ==========================================

    initial begin

        // Inicia com reset ativado
        // e busca desabilitada
        reset  = 1'b1;
        enable = 1'b0;

        // Aguarda 12 ns
        #12;

        // Libera o reset
        reset = 1'b0;

        // Habilita a busca das instrucoes
        enable = 1'b1;

        // Aguarda 60 ns para realizar as buscas
        #60;

        // Desabilita a busca
        enable = 1'b0;

        // Aguarda mais 10 ns
        #10;

        // Finaliza a simulacao
        $finish;

    end

endmodule
