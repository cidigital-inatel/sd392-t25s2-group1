
`timescale 1ns / 1ps

module tb_npu_ctrl;

    reg clk;
    reg rst_n;

    reg wr_en;
    reg [7:0] wr_addr;
    reg [31:0] wr_data;

    reg [7:0] rd_addr;
    wire [31:0] rd_data;

    wire start;
    reg npu_busy;
    reg npu_done;

    // Instancia o modulo principal
    npu_ctrl dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .start(start),
        .npu_busy(npu_busy),
        .npu_done(npu_done)
    );

    // Clock de 10 ns
    always #5 clk = ~clk;

    initial begin
        // Valores iniciais
        clk      = 0;
        rst_n    = 0;
        wr_en    = 0;
        wr_addr  = 0;
        wr_data  = 0;
        rd_addr  = 0;
        npu_busy = 0;
        npu_done = 0;

        // Aplicar reset
        repeat (2) @(negedge clk);
        rst_n = 1;

        // TESTE 1: gerar start
        @(negedge clk);
        wr_en   = 1;
        wr_addr = 8'h00;
        wr_data = 32'h00000001;

        @(posedge clk);
        #1;
        if (start !== 1'b1)
            $fatal(1, "ERRO: start nao foi gerado");
        $display("OK: start foi gerado");

        // TESTE 2: start volta para zero
        @(negedge clk);
        wr_en = 0;

        @(posedge clk);
        #1;
        if (start !== 1'b0)
            $fatal(1, "ERRO: start nao voltou para zero");
        $display("OK: start voltou para zero");

        // TESTE 3: leitura do busy
        @(negedge clk);
        npu_busy = 1;
        rd_addr  = 8'h04;

        #1;
        if (rd_data[0] !== 1'b1)
            $fatal(1, "ERRO: busy nao aparece no STATUS");
        $display("OK: STATUS.busy = 1");

        // TESTE 4: registrar done
        @(negedge clk);
        npu_busy = 0;
        npu_done = 1;

        @(posedge clk);
        #1;
        npu_done = 0;

        if (rd_data[1] !== 1'b1)
            $fatal(1, "ERRO: done nao foi registrado");
        $display("OK: STATUS.done = 1");

        // TESTE 5: limpar done
        @(negedge clk);
        wr_en   = 1;
        wr_addr = 8'h00;
        wr_data = 32'h00000002;

        @(posedge clk);
        #1;
        wr_en = 0;

        if (rd_data[1] !== 1'b0)
            $fatal(1, "ERRO: done nao foi limpo");
        $display("OK: STATUS.done foi limpo");

        $display("TODOS OS TESTES PASSARAM!");
        $finish;
    end

endmodule
