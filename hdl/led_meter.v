`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/02/2025 09:37:30 AM
// Design Name: 
// Module Name: led_meter
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


module led_meter(
  input                      i_clock,
  input                      i_data_valid,
  input      signed [23 : 0] i_data_left,
  input      signed [23 : 0] i_data_right,
  output reg        [7 : 0]  o_led
);
  
  reg                  dbfs_converter_start;
  wire                 dbfs_converter_done;
  wire                 dbfs_converter_idle;
  wire                 dbfs_converter_ready;
  wire signed [23 : 0] dbfs_value_integer;
  wire signed [23 : 0] dbfs_value_fraction;
  reg  signed [24 : 0] absolute_mono_sum;

  dbfs_converter_0 dbfs_converter_0_inst (
    .ap_clk       (i_clock),                                  // input wire ap_clk
    .ap_rst       (1'b0),                                     // input wire ap_rst
    .ap_start     (dbfs_converter_start),                     // input wire ap_start
    .ap_done      (dbfs_converter_done),                      // output wire ap_done
    .ap_idle      (dbfs_converter_idle),                      // output wire ap_idle
    .ap_ready     (dbfs_converter_ready),                     // output wire ap_ready
    .ap_return    ({dbfs_value_integer,dbfs_value_fraction}), // output wire [47 : 0] ap_return
    .linear_value ({absolute_mono_sum,24'h000})               // input wire [47 : 0] linear_value
  );

  localparam IDLE                  = 3'd0;
  localparam GET_MONO_SUM          = 3'd1;
  localparam START_DBFS_CONVERSION = 3'd2;
  localparam GET_DBFS_VALUE        = 3'd3;
  localparam UPDATE_LED            = 3'd4;
  
  reg        [2  : 0] main_fsm_state = IDLE;
  
  always @(posedge i_clock) begin
    case (main_fsm_state) 
      IDLE : begin
        absolute_mono_sum    <= 25'd0;
        main_fsm_state       <= GET_MONO_SUM;
        dbfs_converter_start <= 1'b0;
      end
      
      GET_MONO_SUM : begin
        if (i_data_valid == 1'b1) begin
          absolute_mono_sum <= (i_data_left + i_data_right) / 2;
          main_fsm_state    <= START_DBFS_CONVERSION;
        end
      end
      
      START_DBFS_CONVERSION : begin
        if (absolute_mono_sum == 0) begin
          main_fsm_state       <= UPDATE_LED;
        end else begin
          main_fsm_state       <= GET_DBFS_VALUE;
          dbfs_converter_start <= 1'b1;
        end
      end 
      
      GET_DBFS_VALUE : begin
        dbfs_converter_start   <= 1'b0;
        if (dbfs_converter_done == 1'b1) begin
          main_fsm_state       <= UPDATE_LED;
        end
      end
      
      UPDATE_LED : begin
        if (absolute_mono_sum == 0)
          o_led <= 8'b0000000;
        else if (dbfs_value_integer > -3)
          o_led <= 8'b11111111;
        else if (dbfs_value_integer > -6)
          o_led <= 8'b01111111;
        else if (dbfs_value_integer > -9)
          o_led <= 8'b00111111;
        else if (dbfs_value_integer > -12)
          o_led <= 8'b00011111;
        else if (dbfs_value_integer > -18)
          o_led <= 8'b00001111;
        else if (dbfs_value_integer > -24)
          o_led <= 8'b00000111;
        else if (dbfs_value_integer > -36)
          o_led <= 8'b00000011;
        else if (dbfs_value_integer > -48)
          o_led <= 8'b0000001;
        else begin
          o_led <= 8'b0000000;
        end
        main_fsm_state <= IDLE;  
      end
      
    endcase
  end

endmodule