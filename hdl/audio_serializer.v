`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/01/2025 09:49:52 AM
// Design Name: 
// Module Name: audio_serializer
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


module audio_serializer(
  input            i_clock,
  
  input            i_codec_bit_clock,
  input            i_codec_lr_clock,
  output reg       o_codec_dac_data,
  
  input     [23:0] i_data_left,
  input     [23:0] i_data_right,
  input            i_data_valid
);

  reg                 codec_bit_clock_meta;
  reg                 codec_bit_clock_stable;
  reg                 codec_bit_clock_delay;
  reg                 codec_bit_clock_rising;
  reg                 codec_bit_clock_falling;
  reg                 codec_lr_clock_meta;
  reg                 codec_lr_clock_stable;
  reg                 codec_lr_clock_delay;
  reg                 codec_lr_clock_rising;
  reg                 codec_lr_clock_falling;
  reg        [4  : 0] bit_counter;
  reg signed [23 : 0] shift_register_left;
  reg signed [23 : 0] shift_register_right;  
  
  localparam IDLE                  = 3'd0;
  localparam WAIT_LR_CLOCK_FALLING = 3'd1;
  localparam LR_CLOCK_FALLING      = 3'd2;
  localparam LEFT_DATA_SHIFT       = 3'd3;
  localparam WAIT_LR_CLOCK_RISING  = 3'd4;
  localparam LR_CLOCK_RISING       = 3'd5;
  localparam RIGHT_DATA_SHIFT      = 3'd6;
  
  reg [2:0] fsm_state = IDLE;
    
  always @(posedge i_clock) begin
    codec_bit_clock_meta      <= i_codec_bit_clock;
    codec_bit_clock_stable    <= codec_bit_clock_meta;
    codec_bit_clock_delay     <= codec_bit_clock_stable;
    codec_lr_clock_meta       <= i_codec_lr_clock;
    codec_lr_clock_stable     <= codec_lr_clock_meta;
    codec_lr_clock_delay      <= codec_lr_clock_stable;
    
    if ((codec_bit_clock_stable == 1'b1) && (codec_bit_clock_delay == 1'b0)) begin
      codec_bit_clock_rising  <= 1'b1;
    end else begin
      codec_bit_clock_rising  <= 1'b0;
    end
    
    if ((codec_bit_clock_stable == 1'b0) && (codec_bit_clock_delay == 1'b1)) begin
      codec_bit_clock_falling <= 1'b1;
    end else begin
      codec_bit_clock_falling <= 1'b0;
    end
    
    if ((codec_lr_clock_stable == 1'b1) && (codec_lr_clock_delay == 1'b0)) begin
      codec_lr_clock_rising   <= 1'b1;
    end else begin
      codec_lr_clock_rising   <= 1'b0;
    end
    
    if ((codec_lr_clock_stable == 1'b0) && (codec_lr_clock_delay == 1'b1)) begin
      codec_lr_clock_falling  <= 1'b1;
    end else begin
      codec_lr_clock_falling  <= 1'b0;
    end
    
  end
  
  always @(posedge i_clock) begin
    case (fsm_state)
      IDLE : begin
        bit_counter             <= 5'd0;
        shift_register_left     <= 24'd0;
        shift_register_right    <= 24'd0;
        o_codec_dac_data        <= 1'd0;
        if (i_data_valid == 1'b1) begin
          fsm_state             <= WAIT_LR_CLOCK_FALLING;
          shift_register_left   <= i_data_left;
          shift_register_right  <= i_data_right;
        end
      end
      
      WAIT_LR_CLOCK_FALLING : begin
        if (codec_lr_clock_falling == 1'b1) begin
          fsm_state             <= LR_CLOCK_FALLING;
        end 
      end
      
      LR_CLOCK_FALLING :  begin
        if (codec_bit_clock_rising == 1'b1) begin
          fsm_state             <= LEFT_DATA_SHIFT;
        end
      end
      
      LEFT_DATA_SHIFT : begin
        o_codec_dac_data <= shift_register_left[23];
        if (codec_bit_clock_rising == 1'b1) begin
          bit_counter           <= bit_counter + 5'd1;
          if (bit_counter != 5'd0) begin
            shift_register_left <= {shift_register_left[22:0], 1'b0};
          end
        end
        if (bit_counter == 5'd24) begin
          bit_counter           <= 5'd0;
          fsm_state             <= WAIT_LR_CLOCK_RISING;
        end
      end
      
      WAIT_LR_CLOCK_RISING : begin
        if (codec_bit_clock_rising == 1'b1) begin
          fsm_state             <= LR_CLOCK_RISING;
        end
      end
      
      LR_CLOCK_RISING : begin
        if (codec_bit_clock_rising == 1'b1) begin
          fsm_state             <= RIGHT_DATA_SHIFT;
        end
      end
      
      RIGHT_DATA_SHIFT : begin
        o_codec_dac_data        <= shift_register_right[23];
        if (codec_bit_clock_rising == 1'b1) begin
          bit_counter           <= bit_counter + 1;
          if (bit_counter != 0) begin
            shift_register_right <= {shift_register_right[22:0], 1'b0};
          end
        end  
        if (bit_counter == 5'd24) begin
          bit_counter           <= 5'd0;
          fsm_state             <= IDLE;
        end
      end
      
      default : begin
        fsm_state               <= IDLE;
        o_codec_dac_data        <= 1'b0;
      end
    
    endcase
  end

endmodule