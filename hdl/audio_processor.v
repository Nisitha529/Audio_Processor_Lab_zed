`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/01/2025 08:45:27 AM
// Design Name: 
// Module Name: audio_processor
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


module audio_processor(
  input            i_clock,
  
  input            i_codec_bit_clock,
  input            i_codec_lr_clock,
  input            i_codec_adc_data,
  output           o_codec_dac_data,
  
  input            i_sw0,
  input            i_sw1,
  input            i_sw2,
  input            i_sw3,
  input            i_sw4,
  input            i_sw5,
  input            i_sw6,
  input            i_sw7,
  
  input            i_btnu,
  input            i_btnd,
  input            i_btnl,
  input            i_btnr,  
  
  output     [7:0] o_led
);

  wire [23 : 0] o_data_left_deserializer;
  wire [23 : 0] o_data_right_deserializer;
  wire          o_data_valid_deserializer;
  
  wire [23 : 0] o_data_left_monitor;
  wire [23 : 0] o_data_right_monitor;
  wire          o_data_valid_monitor;
  
  audio_deserializer audio_deserializer_01(
    .i_clock           (i_clock),
    .i_codec_adc_data  (i_codec_adc_data),
    .i_codec_bit_clock (i_codec_bit_clock),
    .i_codec_lr_clock  (i_codec_lr_clock),
    
    .o_data_left       (o_data_left_deserializer),
    .o_data_right      (o_data_right_deserializer),
    .o_data_valid      (o_data_valid_deserializer)
  );
  
  led_meter led_meter_01 (
    .i_clock           (i_clock),
    .i_data_left       (o_data_left_deserializer),
    .i_data_right      (o_data_right_deserializer),
    .i_data_valid      (o_data_valid_deserializer),
    
    .o_led             (o_led)
  );
  
  monitor_controller monitor_controller_01(
    .i_clock           (i_clock),
    
    .i_btnd            (i_btnd),
    .i_btnl            (i_btnl),
    .i_btnu            (i_btnu),
    .i_btnr            (i_btnr),
    
    .i_data_left       (o_data_left_deserializer),
    .i_data_right      (o_data_right_deserializer),
    .i_data_valid      (o_data_valid_deserializer),
    
    .o_data_left       (o_data_left_monitor),
    .o_data_right      (o_data_right_monitor),
    .o_data_valid      (o_data_valid_monitor)
  );
  
  audio_serializer audio_serializer_01(
    .i_clock           (i_clock),
    .i_codec_bit_clock (i_codec_bit_clock),
    .i_codec_lr_clock  (i_codec_lr_clock),
    
    .i_data_left       (o_data_left_monitor),
    .i_data_right      (o_data_right_monitor),
    .i_data_valid      (o_data_valid_monitor),
    
    .o_codec_dac_data  (o_codec_dac_data)
  );

endmodule