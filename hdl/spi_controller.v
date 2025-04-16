`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/01/2025 12:29:05 AM
// Design Name: 
// Module Name: spi_controller
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


module spi_controller #(
  parameter SPI_CLOCK_DIVIDER_WIDTH = 8,
  parameter SPI_DATA_WIDTH          = 8
)(
  input    i_clock,
  input    i_reset,
  
  input    i_enable,
  input    i_spi_miso,
  
  output   o_spi_clock,
  output   o_spi_cs_n,
  output   o_spi_mosi
);

wire [SPI_DATA_WIDTH - 1 : 0] i_driver_data;
wire                          i_driver_done;
wire                          i_driver_busy;

wire [SPI_DATA_WIDTH - 1 : 0] o_driver_data;
wire                          o_driver_enable;

spi_driver
#(
  .SPI_DATA_WIDTH (SPI_DATA_WIDTH)
) 
spi_driver_01(
  .i_clock     (i_clock),
  .i_reset     (i_reset),
  
  .i_enable    (i_enable),
  
  .i_data      (i_driver_data),
  .i_done      (i_driver_done),
  .i_busy      (i_driver_busy),
  .o_enable    (o_driver_enable),
  .o_data      (o_driver_data)   
);

spi_master #(
  .SPI_CLOCK_DIVIDER_WIDTH (SPI_CLOCK_DIVIDER_WIDTH),
  .SPI_DATA_WIDTH          (SPI_DATA_WIDTH)
)spi_master_01(
  .i_clock                 (i_clock),
  .i_reset                 (i_reset),
   
  .i_enable                (o_driver_enable),
  .i_clock_polarity        (1'b0),
  .i_clock_phase           (1'b0),
  .i_spi_clock_divider     (5'b10000),
  .i_data_in               (o_driver_data),
  .o_data_out              (i_driver_data),
  .o_done                  (i_driver_done),
  .o_busy                  (i_driver_busy),
  
  .i_spi_miso              (i_spi_miso),
  .o_spi_cs_n              (o_spi_cs_n),
  .o_spi_clock             (o_spi_clock),
  .o_spi_mosi              (o_spi_mosi)
);

endmodule