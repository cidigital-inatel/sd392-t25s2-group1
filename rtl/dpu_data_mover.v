
`timescale 1ns / 1ps

module dpu_data_mover (
    input  wire        aclk,
    input  wire        aresetn,

    // AXI4-Stream Slave
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire        s_axis_tlast,

    // AXI4-Stream Master
    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg         m_axis_tlast
);

    // Pode receber quando vazio ou quando
    // o dado atual sera consumido.
    assign s_axis_tready =
        !m_axis_tvalid || m_axis_tready;

    always @(posedge aclk) begin
        if (!aresetn) begin
            m_axis_tdata  <= 32'd0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end
        else if (s_axis_tready) begin
            m_axis_tvalid <= s_axis_tvalid;

            if (s_axis_tvalid) begin
                m_axis_tdata <= s_axis_tdata;
                m_axis_tlast <= s_axis_tlast;
            end
        end
    end

endmodule