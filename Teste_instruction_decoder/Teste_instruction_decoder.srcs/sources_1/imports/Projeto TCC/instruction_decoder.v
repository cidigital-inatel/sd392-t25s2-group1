module instruction_decoder (
    input  wire [7:0] instruction,
    output reg        load_en,
    output reg        compute_en,
    output reg        store_en,
    output wire [3:0] parameter_out
);

    // Separa os campos da instrucao
    wire [3:0] opcode;

    assign opcode = instruction[7:4];
    assign parameter_out = instruction[3:0];

    // Decodifica a operacao solicitada
    always @(*) begin

        // Valores padrao: nenhuma operacao ativa
        load_en    = 1'b0;
        compute_en = 1'b0;
        store_en   = 1'b0;

        case (opcode)

            4'b0000: begin
                // NOP: nenhuma operacao
            end

            4'b0001: begin
                load_en = 1'b1;
            end

            4'b0010: begin
                compute_en = 1'b1;
            end

            4'b0011: begin
                store_en = 1'b1;
            end

            default: begin
                // Opcode desconhecido
                // Mantem todas as saidas desativadas
            end

        endcase
    end

endmodule