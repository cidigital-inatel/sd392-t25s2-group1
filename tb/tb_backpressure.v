
`timescale 1ns / 1ps

module tb_dpu_data_mover;

    reg clk = 0;
    reg resetn = 0;

    reg [31:0] s_data = 0;
    reg s_valid = 0;
    reg s_last = 0;
    wire s_ready;

    wire [31:0] m_data;
    wire m_valid;
    wire m_last;
    reg m_ready = 0;

    integer sent = 0;
    integer received = 0;
    integer errors = 0;
    integer cycles = 0;
    integer blocked_cycles = 0;

    reg [31:0] expected_data [0:19];

    // Monitor de estabilidade durante bloqueio
    reg was_stalled = 0;
    reg [31:0] held_data = 0;
    reg held_last = 0;

    // Clock de 100 MHz
    always #5 clk = ~clk;

    // Instancia do Data Mover
    dpu_data_mover dut (
        .aclk(clk),
        .aresetn(resetn),
        .s_axis_tdata(s_data),
        .s_axis_tvalid(s_valid),
        .s_axis_tready(s_ready),
        .s_axis_tlast(s_last),
        .m_axis_tdata(m_data),
        .m_axis_tvalid(m_valid),
        .m_axis_tready(m_ready),
        .m_axis_tlast(m_last)
    );

    // Verificador automatico
    always @(posedge clk) begin
        if (!resetn) begin
            was_stalled = 0;
        end
        else begin

            // Verificar se dado bloqueado permaneceu estavel
            if (was_stalled) begin
                if (!m_valid ||
                    m_data !== held_data ||
                    m_last !== held_last) begin
                    $display("ERRO: dado mudou durante bloqueio");
                    errors = errors + 1;
                end
            end

            was_stalled = m_valid && !m_ready;

            if (was_stalled) begin
                held_data = m_data;
                held_last = m_last;
                blocked_cycles = blocked_cycles + 1;
            end

            // Conferir cada transferencia recebida
            if (m_valid && m_ready) begin

                if (received >= 20) begin
                    $display("ERRO: dado extra recebido");
                    errors = errors + 1;
                end
                else begin

                    if (m_data !== expected_data[received]) begin
                        $display(
                            "ERRO: dado %0d esperado=%h recebido=%h",
                            received,
                            expected_data[received],
                            m_data
                        );
                        errors = errors + 1;
                    end

                    if (m_last !== (received == 19)) begin
                        $display(
                            "ERRO: TLAST incorreto no dado %0d",
                            received
                        );
                        errors = errors + 1;
                    end

                    $display(
                        "Recebido %0d: %h TLAST=%b",
                        received, m_data, m_last
                    );
                end

                received = received + 1;
            end
        end
    end

    // Geracao de estimulos
    initial begin

        for (integer i = 0; i < 20; i = i + 1)
            expected_data[i] = 32'hA0000000 + i;

        // Reset
        repeat (4) @(negedge clk);
        resetn = 1;

        $display("INICIANDO TESTE BACKPRESSURE");

        @(negedge clk);
        s_valid = 1;
        s_data = expected_data[0];
        s_last = 0;

        // Executar ciclos com bloqueios periodicos
        while (received < 20 && cycles < 200) begin

            // Mudar TREADY somente na borda negativa
            // Bloqueia 3 ciclos a cada grupo de 8
            m_ready = ((cycles % 8) >= 3);

            @(posedge clk);

            if (s_valid && s_ready)
                sent = sent + 1;

            @(negedge clk);
            cycles = cycles + 1;

            if (sent < 20) begin
                s_data = expected_data[sent];
                s_last = (sent == 19);
                s_valid = 1;
            end
            else begin
                s_valid = 0;
                s_last = 0;
            end
        end

        m_ready = 1;
        repeat (5) @(negedge clk);

        $display("----------------------------");
        $display("Enviados: %0d", sent);
        $display("Recebidos: %0d", received);
        $display("Ciclos bloqueados: %0d", blocked_cycles);
        $display("Erros: %0d", errors);

        if (sent == 20 &&
            received == 20 &&
            errors == 0 &&
            blocked_cycles > 0)
            $display("TESTE BACKPRESSURE PASSOU!");
        else
            $display("TESTE BACKPRESSURE FALHOU!");

        $finish;
    end

    // Timeout de seguranca
    initial begin
        #5000;
        $display("ERRO: timeout");
        $finish;
    end

endmodule
