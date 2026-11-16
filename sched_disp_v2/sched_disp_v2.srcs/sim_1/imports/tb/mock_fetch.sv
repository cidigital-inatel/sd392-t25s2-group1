`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// mock_fetch.sv  -  MODELO DE TESTE do fetch/decoder (somente simulacao)
//
// Guarda um "programa" (prog[]) e entrega uma instrucao por vez pelo
// handshake valid/ready:
//   - instr_valid = 1 quando tem instrucao disponivel;
//   - a instrucao e transferida no ciclo em que instr_valid e instr_ready
//     estao em 1 juntos; ai passa para a proxima;
//   - enquanto nao for aceita, a instrucao fica parada (regra do handshake).
// restart  : volta para a instrucao 0 (o testbench liga junto com o start)
// cfg_gap  : ciclos de pausa (instr_valid = 0) apos cada instrucao aceita
// cfg_stall: 1 = nunca entrega nada (para testar o timeout de instrucao)
// O testbench escreve o programa diretamente em fetch0.prog[i].
// -----------------------------------------------------------------------------
module mock_fetch (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        restart,
    input  wire        instr_ready,
    output wire        instr_valid,
    output wire [15:0] instr_data,
    input  wire [7:0]  cfg_gap,
    input  wire        cfg_stall
);
    reg [15:0] prog [0:255];
    reg [7:0]  ptr;       // proxima instrucao a entregar
    reg [7:0]  gap_cnt;   // pausa restante
    reg        active;
    integer    accepted;  // quantas instrucoes foram aceitas desde o restart

    assign instr_valid = active && !cfg_stall && (gap_cnt == 8'd0);
    assign instr_data  = prog[ptr];

    always @(posedge clk) begin
        if (!rst_n) begin
            ptr      <= 8'd0;
            gap_cnt  <= 8'd0;
            active   <= 1'b0;
            accepted <= 0;
        end else if (restart) begin
            ptr      <= 8'd0;
            gap_cnt  <= 8'd0;
            active   <= 1'b1;
            accepted <= 0;
        end else begin
            if (gap_cnt != 8'd0) gap_cnt <= gap_cnt - 1'b1;
            if (instr_valid && instr_ready) begin
                ptr      <= ptr + 1'b1;
                gap_cnt  <= cfg_gap;
                accepted <= accepted + 1;
            end
        end
    end
endmodule
