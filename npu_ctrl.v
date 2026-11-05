
`timescale 1ns / 1ps

module npu_ctrl (
    input  wire        clk,
    input  wire        rst_n,

    // Interface simplificada de escrita
    input  wire        wr_en,
    input  wire [7:0]  wr_addr,
    input  wire [31:0] wr_data,

    // Interface simplificada de leitura
    input  wire [7:0]  rd_addr,
    output reg  [31:0] rd_data,

    // Sinais de controle da NPU
    output reg         start,
    input  wire        npu_busy,
    input  wire        npu_done
);

    // Enderecos dos registradores
    localparam [7:0] ADDR_CMD    = 8'h00;
    localparam [7:0] ADDR_STATUS = 8'h04;

    reg done_status;

    // Controle de escrita
    always @(posedge clk) begin
        if (!rst_n) begin
            start       <= 1'b0;
            done_status <= 1'b0;
        end else begin
            // start fica ativo por um ciclo
            start <= 1'b0;

            // Escrita no registrador CMD
            if (wr_en && wr_addr == ADDR_CMD) begin
                if (wr_data[0])
                    start <= 1'b1;

                // Bit 1 limpa o status de conclusao
                if (wr_data[1])
                    done_status <= 1'b0;
            end

            // A conclusao tem prioridade sobre a limpeza
            if (npu_done)
                done_status <= 1'b1;
        end
    end

    // Leitura dos registradores
    always @(*) begin
        case (rd_addr)
            ADDR_CMD:
                rd_data = 32'h00000000;

            ADDR_STATUS:
                rd_data = {
                    30'b0,
                    done_status,
                    npu_busy
                };

            default:
                rd_data = 32'h00000000;
        endcase
    end

endmodule
