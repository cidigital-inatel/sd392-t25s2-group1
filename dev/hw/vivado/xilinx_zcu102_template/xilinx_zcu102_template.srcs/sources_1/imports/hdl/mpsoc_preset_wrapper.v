//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
//Date        : Sat Sep 19 16:17:37 2026
//Host        : PREDATOR running 64-bit major release  (build 9200)
//Command     : generate_target mpsoc_preset_wrapper.bd
//Design      : mpsoc_preset_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module mpsoc_preset_wrapper
   (led_8bits_tri_o);
  output [7:0]led_8bits_tri_o;

  wire [7:0]led_8bits_tri_o;

  mpsoc_preset mpsoc_preset_i
       (.led_8bits_tri_o(led_8bits_tri_o));
endmodule
