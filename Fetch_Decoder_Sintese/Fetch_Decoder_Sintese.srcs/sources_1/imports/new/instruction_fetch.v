module instruction_fetch (
    input wire clk,
    input wire reset,
    input wire enable,

    output reg [7:0] instruction,
    output reg [2:0] pc,
    output reg valid
);

// Memoria com 5 instrucoes de 8 bits
reg [7:0] memory [0:4];

initial begin
    memory[0] = 8'h00; // NOP
    memory[1] = 8'h15; // LOAD
    memory[2] = 8'h2A; // COMPUTE
    memory[3] = 8'h37; // STORE
    memory[4] = 8'hF0; // Operacao desconhecida
end

// Controle da busca de instrucoes
always @(posedge clk or posedge reset) begin

    if (reset) begin
        pc          <= 3'd0;
        instruction <= 8'h00;
        valid       <= 1'b0;
    end

    else if (enable) begin

        if (pc < 3'd5) begin
            instruction <= memory[pc];
            pc          <= pc + 1'b1;
            valid       <= 1'b1;
        end

        else begin
            valid <= 1'b0;
        end
    end
end
endmodule