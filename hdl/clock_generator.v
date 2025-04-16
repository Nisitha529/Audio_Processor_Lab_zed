`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2025 11:01:28 AM
// Design Name: 
// Module Name: clock_generator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clock_generator(
  input  i_clock,
  output o_clock_100MHz,
  output o_clock_45MHz
);

wire clock_45MHZ;

clk_wiz_0 clk_wiz_0_inst(
  .i_clock   (i_clock),
  .clk_out1 (o_clock_100MHz),
  .clk_out2 (clock_45MHZ)
);

oddr_0 oddr_0_inst (
  .clk_in    (clock_45MHZ),
  .clk_out   (o_clock_45MHz)
);

endmodule