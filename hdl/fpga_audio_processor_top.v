`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/27/2025 09:53:51 PM
// Design Name: 
// Module Name: fpga_audio_processor_top
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


module fpga_audio_processor_top #(
  parameter SPI_CLOCK_DIVIDER_WIDTH = 5,
  parameter SPI_DATA_WIDTH          = 32
)(
  input  i_clock,
  
  input  i_sw0,
  input  i_sw1,
  input  i_sw2,
  input  i_sw3,
  input  i_sw4,
  input  i_sw5,
  input  i_sw6,
  input  i_sw7,
  
  input  i_btnu,
  input  i_btnd,
  input  i_btnl,
  input  i_btnr,
  input  i_btnc,
  
  output o_ld0,
  output o_ld1,
  output o_ld2,
  output o_ld3,
  output o_ld4,
  output o_ld5,
  output o_ld6,
  output o_ld7,
  
  input  i_spi_miso,
  output o_spi_cs_n,
  output o_spi_clock,
  output o_spi_mosi,
  
  input  i_codec_bit_clock,
  input  i_codec_lr_clock,
  input  i_codec_adc_data,
  output o_codec_mclock,
  output o_codec_dac_data
);

  wire sw0;
  wire sw1;
  wire sw2;
  wire sw3;
  wire sw4;
  wire sw5;
  wire sw6;
  wire sw7;
  wire btnu;
  wire btnd;
  wire btnl;
  wire btnr;
  wire btnc;
  
  debouncer #(
    .SWITCH_COUNT              (8),
    .BUTTON_COUNT              (5),
    .DEBOUNCE_COUNTER_WIDTH    (16)
  ) debouncer_01(
    .i_clock                   (i_clock),
    
    .i_switch_debounce_counter (16'd10000),
    .i_button_debounce_counter (16'd10000),
    
    .i_sw0                     (i_sw0),
    .i_sw1                     (i_sw1),
    .i_sw2                     (i_sw2),
    .i_sw3                     (i_sw3),
    .i_sw4                     (i_sw4),
    .i_sw5                     (i_sw5),
    .i_sw6                     (i_sw6),
    .i_sw7                     (i_sw7),
    
    .i_btnu                    (i_btnu),
    .i_btnd                    (i_btnd),
    .i_btnl                    (i_btnl),
    .i_btnr                    (i_btnr),
    .i_btnc                    (i_btnc),
    
    .o_sw0                     (sw0),
    .o_sw1                     (sw1),
    .o_sw2                     (sw2),
    .o_sw3                     (sw3),
    .o_sw4                     (sw4),
    .o_sw5                     (sw5),
    .o_sw6                     (sw6),
    .o_sw7                     (sw7), 
    
    .o_btnu                    (btnu),
    .o_btnd                    (btnd),
    .o_btnl                    (btnl),
    .o_btnr                    (btnr),
    .o_btnc                    (btnc)
  );
  
  
  //Control Signals for the codec
  spi_controller #(
    .SPI_CLOCK_DIVIDER_WIDTH   (SPI_CLOCK_DIVIDER_WIDTH),
    .SPI_DATA_WIDTH            (SPI_DATA_WIDTH)
  ) spi_controller_01 (
    .i_clock                   (i_clock),
    .i_reset                   (1'b0),
    .i_enable                  (btnc),
    
    .i_spi_miso                (i_spi_miso),
    .o_spi_cs_n                (o_spi_cs_n),
    .o_spi_clock               (o_spi_clock),
    .o_spi_mosi                (o_spi_mosi)       
  );
  
  clock_generator clock_generator_01 (
    .i_clock                   (i_clock),
    .o_clock_45MHz             (o_codec_mclock)
  );
  
  //Data transmission for the codec
  audio_processor audio_processor_01 (
    .i_clock                   (i_clock),
    
    .i_codec_bit_clock         (i_codec_bit_clock),
    .i_codec_lr_clock          (i_codec_lr_clock),
    .i_codec_adc_data          (i_codec_adc_data),
    .o_codec_dac_data          (o_codec_dac_data),
    
    .i_btnu                    (btnu),
    .i_btnd                    (btnd),
    .i_btnl                    (btnl),
    .i_btnr                    (btnr),
    
    .o_led              ({o_ld7, o_ld6, o_ld5, o_ld4, o_ld3, o_ld2, o_ld1, o_ld0})       
  );

endmodule