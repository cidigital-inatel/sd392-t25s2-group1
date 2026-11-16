`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// mock_unit.sv  -  MODELO DE TESTE (somente simulacao, NAO e hardware do projeto)
//
// Finge ser uma unidade de execucao (PE, data mover...) com o contrato:
//   - ready = 1 quando livre
//   - recebe start (pulso), trabalha cfg_latency+1 ciclos, devolve done (pulso)
// cfg_mode:
//   0 = normal
//   1 = nunca responde done (para testar timeout)
//   2 = responde done duas vezes seguidas (para testar done duplicado)
// -----------------------------------------------------------------------------
module mock_unit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire [3:0] op,
    input  wire [7:0] arg,
    output wire       ready,
    output reg        done,
    input  wire [7:0] cfg_latency,
    input  wire [1:0] cfg_mode
);
    localparam MODE_NORMAL = 2'd0, MODE_NEVER_DONE = 2'd1, MODE_DOUBLE_DONE = 2'd2;

    reg       working;
    reg [7:0] cnt;
    reg       second_done;
    integer   violations;   // start recebido com a unidade ocupada

    assign ready = !working;

    always @(posedge clk) begin
        if (!rst_n) begin
            working     <= 1'b0;
            cnt         <= 8'd0;
            done        <= 1'b0;
            second_done <= 1'b0;
            violations  <= 0;
        end else begin
            done <= 1'b0;
            if (second_done) begin
                done        <= 1'b1;
                second_done <= 1'b0;
            end
            if (start) begin
                if (working) begin
                    violations <= violations + 1;
                    $display("[%0t] MOCK: ERRO - start recebido com unidade ocupada", $time);
                end
                working <= 1'b1;
                cnt     <= cfg_latency;
            end else if (working && cfg_mode != MODE_NEVER_DONE) begin
                if (cnt == 8'd0) begin
                    done    <= 1'b1;
                    working <= 1'b0;
                    if (cfg_mode == MODE_DOUBLE_DONE) second_done <= 1'b1;
                end else begin
                    cnt <= cnt - 1'b1;
                end
            end
        end
    end
endmodule
