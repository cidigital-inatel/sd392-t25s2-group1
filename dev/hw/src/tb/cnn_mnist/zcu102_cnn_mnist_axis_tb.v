`timescale 1ns / 1ps

module zcu102_cnn_mnist_axis_tb;
    reg aclk = 0;
    always #5 aclk = ~aclk;
    reg aresetn = 0;
    reg [7:0] s_axis_tdata = 0;
    reg [0:0] s_axis_tkeep = 1;
    reg s_axis_tlast = 0, s_axis_tvalid = 0;
    wire s_axis_tready;
    wire [7:0] m_axis_tdata;
    wire m_axis_tlast, m_axis_tvalid;
    reg m_axis_tready = 0;
    reg [7:0] image1 [0:783];
    reg [7:0] image3 [0:783];
    integer i;

    zcu102_cnn_mnist_axis dut (
        .aclk(aclk), .aresetn(aresetn),
        .s_axis_tdata(s_axis_tdata), .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tlast(s_axis_tlast), .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata), .m_axis_tlast(m_axis_tlast),
        .m_axis_tvalid(m_axis_tvalid), .m_axis_tready(m_axis_tready)
    );

    task send_image;
        input integer which;
        begin
            for (i=0; i<784; i=i+1) begin
                // Pausas no fluxo exercitam o buffer de quadro.
                if (i % 11 == 0) begin
                    @(negedge aclk);
                    s_axis_tvalid = 0;
                    repeat (2) @(negedge aclk);
                end
                s_axis_tdata = which == 1 ? image1[i] : image3[i];
                s_axis_tlast = (i == 783);
                s_axis_tvalid = 1;
                @(posedge aclk);
                while (!s_axis_tready) @(posedge aclk);
                @(negedge aclk);
                s_axis_tvalid = 0;
            end
            s_axis_tlast = 0;
        end
    endtask

    task expect_result;
        input [7:0] expected;
        reg [7:0] held_data;
        begin
            wait (m_axis_tvalid);
            held_data = m_axis_tdata;
            repeat (6) begin
                @(negedge aclk);
                if (m_axis_tvalid !== 1'b1 || m_axis_tlast !== 1'b1 ||
                    m_axis_tdata !== held_data || s_axis_tready !== 1'b0)
                    $fatal(1, "Resultado nao ficou estavel sob backpressure");
            end
            $display("CNN: esperado=%0d obtido=%0d", expected, held_data);
            if (held_data !== expected)
                $fatal(1, "Classificacao diferente da imagem de teste");
            m_axis_tready = 1;
            @(negedge aclk);
            m_axis_tready = 0;
            if (m_axis_tvalid !== 1'b0) $fatal(1, "Resultado duplicado");
        end
    endtask

    initial begin
        #300000;
        $fatal(1, "Timeout: nenhum resultado da CNN");
    end

    initial begin
        $readmemh("1_0.mem", image1);
        $readmemh("3_0.mem", image3);
        repeat (5) @(negedge aclk);
        aresetn = 1;
        send_image(1);
        expect_result(1); // 1_0.mem veio de train_3.bmp
        send_image(3);
        expect_result(3); // 3_0.mem veio de train_7.bmp
        $display("PASS: duas imagens MNIST, pausas na entrada, backpressure na saida");
        $finish;
    end
endmodule
