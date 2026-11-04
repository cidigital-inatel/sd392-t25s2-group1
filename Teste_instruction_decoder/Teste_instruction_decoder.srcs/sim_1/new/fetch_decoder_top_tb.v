
`timescale 1ns / 1ps

module fetch_decoder_top_tb;

    // ==========================================
    // 1. ENTRADAS CONTROLADAS PELO TESTBENCH
    // ==========================================

    reg clk;
    reg reset;
    reg enable;

    // ==========================================
    // 2. SAIDAS DO FETCH
    // ==========================================

    wire [7:0] instruction;
    wire [2:0] pc;
    wire valid;

    // ==========================================
    // 3. SAIDAS DO DECODER
    // ==========================================

    wire load_en;
    wire compute_en;
    wire store_en;
    wire [3:0] parameter_out;

    // ==========================================
    // 4. INSTANCIA DO MODULO INTEGRADO
    // ==========================================

    fetch_decoder_top dut (
        .clk           (clk),
        .reset         (reset),
        .enable        (enable),
        .instruction   (instruction),
        .pc            (pc),
        .valid         (valid),
        .load_en       (load_en),
        .compute_en    (compute_en),
        .store_en      (store_en),
        .parameter_out (parameter_out)
    );

    // ==========================================
    // 5. GERACAO DO CLOCK
    // ==========================================

    initial begin
        clk = 1'b0;
    end

    // Periodo de 10 ns = 100 MHz
    always #5 clk = ~clk;

    // ==========================================
    // 6. ESTIMULOS DA SIMULACAO
    // ==========================================

    initial begin

        // Inicia com reset ativado
        reset  = 1'b1;
        enable = 1'b0;

        // Libera o reset e habilita o Fetch
        #12;
        reset  = 1'b0;
        enable = 1'b1;

        // Aguarda a busca das 5 instrucoes
        // e a desativacao do valid
        #60;

        // Desabilita o Fetch
        enable = 1'b0;

        // Finaliza a simulacao
        #10;
        $finish;

    end

endmodule
