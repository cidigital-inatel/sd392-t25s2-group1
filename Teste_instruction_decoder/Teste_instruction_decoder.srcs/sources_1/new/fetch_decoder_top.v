
module fetch_decoder_top (

    // ==========================================
    // 1. ENTRADAS DO SISTEMA
    // ==========================================

    input wire clk,
    input wire reset,
    input wire enable,

    // ==========================================
    // 2. SAIDAS DO INSTRUCTION FETCH
    // ==========================================

    output wire [7:0] instruction,
    output wire [2:0] pc,
    output wire valid,

    // ==========================================
    // 3. SAIDAS DO INSTRUCTION DECODER
    // ==========================================

    output wire load_en,
    output wire compute_en,
    output wire store_en,
    output wire [3:0] parameter_out

);

    // ==========================================
    // 4. SINAIS INTERNOS DO DECODER
    // ==========================================

    // Recebem os comandos gerados pelo Decoder
    // antes da verificacao do sinal valid.

    wire load_dec;
    wire compute_dec;
    wire store_dec;


    // ==========================================
    // 5. INSTANCIA DO INSTRUCTION FETCH
    // ==========================================

    // Busca instrucoes na memoria usando o PC.

    instruction_fetch fetch_inst (

        .clk         (clk),
        .reset       (reset),
        .enable      (enable),

        .instruction (instruction),
        .pc          (pc),
        .valid       (valid)

    );


    // ==========================================
    // 6. INSTANCIA DO INSTRUCTION DECODER
    // ==========================================

    // Recebe a instrucao buscada pelo Fetch
    // e identifica a operacao correspondente.

    instruction_decoder decoder_inst (

        .instruction   (instruction),

        .load_en       (load_dec),
        .compute_en    (compute_dec),
        .store_en      (store_dec),

        .parameter_out (parameter_out)

    );


    // ==========================================
    // 7. CONTROLE DE VALIDACAO DAS OPERACOES
    // ==========================================

    // Os sinais de controle so ficam ativos
    // quando o Fetch possui instrucao valida.

    assign load_en    = valid & load_dec;
    assign compute_en = valid & compute_dec;
    assign store_en   = valid & store_dec;


endmodule
