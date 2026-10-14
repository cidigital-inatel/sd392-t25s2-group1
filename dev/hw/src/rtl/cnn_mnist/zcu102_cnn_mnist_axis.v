`timescale 1ns / 1ps

// Top AXI4-Stream para o Block Design da ZCU102.
// Autor do projeto e da integracao: Hyago Vieira Lemes Barbosa Silva (G1-CIDigital).
// Adaptador AXI4-Stream da CNN MNIST para o Block Design da ZCU102.
// Recebe exatamente 784 pixels de 8 bits por imagem e produz 1 classe por imagem.
// Uma imagem e processada por vez; o buffer permite pausas no stream de entrada.
module zcu102_cnn_mnist_axis (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS:M_AXIS, ASSOCIATED_RESET aresetn" *)
    input  wire       aclk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire       aresetn,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *)
    input  wire [7:0] s_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TKEEP" *)
    input  wire [0:0] s_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TLAST" *)
    input  wire       s_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *)
    input  wire       s_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TREADY" *)
    output wire       s_axis_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *)
    output reg  [7:0] m_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TLAST" *)
    output wire       m_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *)
    output wire       m_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TREADY" *)
    input  wire       m_axis_tready
);
    localparam [2:0] RECEIVE = 3'd0, RUN = 3'd1, RESULT = 3'd2, DROP = 3'd3;
    // O pipeline original espera 784 pixels e mais 57 clocks de preenchimento.
    localparam [10:0] IMAGE_PIXELS = 11'd784, FEED_CYCLES = 11'd841;

    reg [2:0] state;
    reg [9:0] rx_count;
    reg [10:0] feed_count;
    reg [7:0] image [0:783];

    wire [7:0] core_pixel;
    wire core_valid, core_resetn;
    wire signed [11:0] conv_out_1, conv_out_2, conv_out_3;
    wire signed [11:0] conv2_out_1, conv2_out_2, conv2_out_3;
    wire signed [11:0] max_value_1, max_value_2, max_value_3;
    wire signed [11:0] max2_value_1, max2_value_2, max2_value_3;
    wire signed [11:0] fc_out_data;
    wire valid_1, valid_2, valid_3, valid_4, valid_5, valid_6;
    wire [3:0] decision;

    assign s_axis_tready = aresetn && ((state == RECEIVE) || (state == DROP));
    assign m_axis_tvalid = aresetn && (state == RESULT);
    assign m_axis_tlast = m_axis_tvalid;
    assign core_pixel = (feed_count < IMAGE_PIXELS) ? image[feed_count] : 8'd0;
    assign core_valid = (state == RUN) && (feed_count < FEED_CYCLES);
    assign core_resetn = aresetn && (state == RUN);

    // Recepcao aceita bolhas (TVALID=0). TLAST deve marcar o pixel 784.
    // Um quadro curto e descartado; um quadro longo e drenado ate TLAST.
    always @(posedge aclk) begin
        if (!aresetn) begin
            state <= RECEIVE;
            rx_count <= 0;
            feed_count <= 0;
            m_axis_tdata <= 0;
        end else begin
            case (state)
                RECEIVE: if (s_axis_tvalid && s_axis_tready) begin
                    if (!s_axis_tkeep[0]) begin
                        rx_count <= 0;
                        state <= s_axis_tlast ? RECEIVE : DROP;
                    end else if (rx_count == 10'd783) begin
                        rx_count <= 0;
                        feed_count <= 0;
                        state <= s_axis_tlast ? RUN : DROP;
                        image[rx_count] <= s_axis_tdata;
                    end else if (s_axis_tlast) begin
                        rx_count <= 0;
                    end else begin
                        image[rx_count] <= s_axis_tdata;
                        rx_count <= rx_count + 1'b1;
                    end
                end
                DROP: if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
                    rx_count <= 0;
                    state <= RECEIVE;
                end
                RUN: begin
                    if (core_valid)
                        feed_count <= feed_count + 1'b1;
                    if (valid_6) begin
                        m_axis_tdata <= {4'b0000, decision};
                        state <= RESULT;
                    end
                end
                RESULT: if (m_axis_tvalid && m_axis_tready) begin
                    rx_count <= 0;
                    state <= RECEIVE;
                end
                default: state <= RECEIVE;
            endcase
        end
    end

    conv1_layer conv1 (
        .clk(aclk), .rst_n(core_resetn), .valid_in(core_valid), .data_in(core_pixel),
        .conv_out_1(conv_out_1), .conv_out_2(conv_out_2), .conv_out_3(conv_out_3),
        .valid_out_conv(valid_1)
    );
    maxpool_relu #(.CONV_BIT(12), .HALF_WIDTH(12), .HALF_HEIGHT(12), .HALF_WIDTH_BIT(4)) pool1 (
        .clk(aclk), .rst_n(core_resetn), .valid_in(valid_1),
        .conv_out_1(conv_out_1), .conv_out_2(conv_out_2), .conv_out_3(conv_out_3),
        .max_value_1(max_value_1), .max_value_2(max_value_2), .max_value_3(max_value_3),
        .valid_out_relu(valid_2)
    );
    conv2_layer conv2 (
        .clk(aclk), .rst_n(core_resetn), .valid_in(valid_2),
        .max_value_1(max_value_1), .max_value_2(max_value_2), .max_value_3(max_value_3),
        .conv2_out_1(conv2_out_1), .conv2_out_2(conv2_out_2), .conv2_out_3(conv2_out_3),
        .valid_out_conv2(valid_3)
    );
    maxpool_relu #(.CONV_BIT(12), .HALF_WIDTH(4), .HALF_HEIGHT(4), .HALF_WIDTH_BIT(3)) pool2 (
        .clk(aclk), .rst_n(core_resetn), .valid_in(valid_3),
        .conv_out_1(conv2_out_1), .conv_out_2(conv2_out_2), .conv_out_3(conv2_out_3),
        .max_value_1(max2_value_1), .max_value_2(max2_value_2), .max_value_3(max2_value_3),
        .valid_out_relu(valid_4)
    );
    fully_connected #(.INPUT_NUM(48), .OUTPUT_NUM(10), .DATA_BITS(8)) fc (
        .clk(aclk), .rst_n(core_resetn), .valid_in(valid_4),
        .data_in_1(max2_value_1), .data_in_2(max2_value_2), .data_in_3(max2_value_3),
        .data_out(fc_out_data), .valid_out_fc(valid_5)
    );
    comparator cmp (
        .clk(aclk), .rst_n(core_resetn), .valid_in(valid_5),
        .data_in(fc_out_data), .decision(decision), .valid_out(valid_6)
    );
endmodule
