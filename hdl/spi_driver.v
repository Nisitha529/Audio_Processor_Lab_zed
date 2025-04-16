`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2025 10:54:41 PM
// Design Name: 
// Module Name: spi_driver
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


module spi_driver #(
  parameter SPI_DATA_WIDTH = 8
)(
  input                               i_clock,
  input                               i_reset,
  
  input                               i_enable,
  
  input      [SPI_DATA_WIDTH - 1 : 0] i_data,
  input                               i_done,
  input                               i_busy,
  output reg                          o_enable,
  output reg [SPI_DATA_WIDTH - 1 : 0] o_data
);

  reg enable_delay1;
  reg enable_delay2;
  reg enable_rising;
  
  // Enable edge detection
  always @(posedge i_clock) begin
    enable_delay1   <= i_enable;
    enable_delay2   <= enable_delay1;
    enable_rising   <= 1'b0;
    if ((enable_delay2 == 1'b0) && (enable_delay1 == 1'b1)) begin
      enable_rising <= 1'b1;
    end 
  end
  
  localparam IDLE                                        = 5'd0;
  localparam DUMMY_WRITE_1                               = 5'd1;
  localparam DUMMY_WRITE_2                               = 5'd2;
  localparam DUMMY_WRITE_3                               = 5'd3;
  localparam WRITE_CLOCK_CONTROL_REG                     = 5'd4;
  localparam WRITE_I2S_MASTER_MODE                       = 5'd5;
  localparam LEFT_MIXER_ENABLE                           = 5'd6;
  localparam LEFT_0_DB                                   = 5'd7;
  localparam RIGHT_MIXER_ENABLE                          = 5'd8;
  localparam RIGHT_0_DB                                  = 5'd9;
  localparam PLAYBACK_LEFT_MIXER_UNMUTE_ENABLE           = 5'd10;
  localparam PLAYBACK_RIGHT_MIXER_UNMUTE_ENABLE          = 5'd11;
  localparam HEADPHONE_OUTPUT_LEFT_ENABLE                = 5'd12;
  localparam HEADPHONE_OUTPUT_RIGHT_ENABLE               = 5'd13;
  localparam PLAYBACK_RIGHT_MIXER_LINE_OUT_ENABLE        = 5'd14;
  localparam PLAYBACK_LEFT_MIXER_LINE_OUT_ENABLE         = 5'd15;
  localparam LINE_OUT_LEFT_ENABLE                        = 5'd16;
  localparam LINE_OUT_RIGHT_ENABLE                       = 5'd17;
  localparam ADCS_ENABLE                                 = 5'd18;
  localparam CHANNELS_PLAYBACK_ENABLE                    = 5'd19;
  localparam DACS_ENABLE                                 = 5'd20;
  localparam SERIAL_INPUT_L0_R0_TO_DAC_LR                = 5'd21;
  localparam SERIAL_OUTPUT_ADC_LR_TO_SERIAL_OUTPUT_L0_R0 = 5'd22;
  localparam CLOCK_ALL_ENGINES_ENABLE                    = 5'd23;
  localparam CLOCK_GENERATORS_ENABLE                     = 5'd24;
  
  reg [4:0] fsm_state = IDLE;
  
  always @(posedge i_clock) begin
    case (fsm_state)
      IDLE : begin
        o_enable     <= 1'b0;
        o_data       <= 8'd0;
        if (enable_rising == 1'b1) begin
          fsm_state  <= DUMMY_WRITE_1;
        end
      end
      
      DUMMY_WRITE_1 : begin
        o_enable     <= 1'b1;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= DUMMY_WRITE_2;
        end
      end
      
      DUMMY_WRITE_2 : begin
        o_enable     <= 1'b1;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= DUMMY_WRITE_3;
        end
      end
      
      DUMMY_WRITE_3 : begin
        o_enable     <= 1'b1;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= WRITE_CLOCK_CONTROL_REG;
        end
      end
      
      WRITE_CLOCK_CONTROL_REG : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h00400007;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= WRITE_I2S_MASTER_MODE;
        end
      end
      
      WRITE_I2S_MASTER_MODE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h00401501;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= LEFT_MIXER_ENABLE;
        end
      end
      
      LEFT_MIXER_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h00400A01;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= LEFT_0_DB;
        end
      end
      
      LEFT_0_DB : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h00400B05;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= RIGHT_MIXER_ENABLE;
        end
      end
      
      RIGHT_MIXER_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h00400C01;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= RIGHT_0_DB;
        end
      end
      
      RIGHT_0_DB : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h00400D05;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= PLAYBACK_LEFT_MIXER_UNMUTE_ENABLE;
        end
      end
      
      PLAYBACK_LEFT_MIXER_UNMUTE_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h00401C21;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= PLAYBACK_RIGHT_MIXER_UNMUTE_ENABLE;
        end
      end
      
      PLAYBACK_RIGHT_MIXER_UNMUTE_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h00401E41;
        if (i_done == 1'b1) begin
          o_enable   <= 1'd0;
          fsm_state  <= HEADPHONE_OUTPUT_LEFT_ENABLE;
        end
      end
      
      HEADPHONE_OUTPUT_LEFT_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h004023E6;
        if (i_done == 1'b1) begin
          o_enable   <= 1'd0;
          fsm_state  <= HEADPHONE_OUTPUT_RIGHT_ENABLE;
        end
      end
      
      HEADPHONE_OUTPUT_RIGHT_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h004024E6;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= PLAYBACK_RIGHT_MIXER_LINE_OUT_ENABLE;
        end
      end
      
      PLAYBACK_RIGHT_MIXER_LINE_OUT_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h00402109;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= PLAYBACK_LEFT_MIXER_LINE_OUT_ENABLE;
        end
      end
      
      PLAYBACK_LEFT_MIXER_LINE_OUT_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h00402003;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= LINE_OUT_LEFT_ENABLE;
        end
      end
      
      LINE_OUT_LEFT_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h004025E6;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= LINE_OUT_RIGHT_ENABLE;
        end
      end
      
      LINE_OUT_RIGHT_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h004026E6;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= ADCS_ENABLE;
        end
      end
      
      ADCS_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h00401903;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= CHANNELS_PLAYBACK_ENABLE;
        end
      end
      
      CHANNELS_PLAYBACK_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h00402903;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= DACS_ENABLE;
        end
      end   
      
      DACS_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h00402A03;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= SERIAL_INPUT_L0_R0_TO_DAC_LR;
        end
      end             
      
      SERIAL_INPUT_L0_R0_TO_DAC_LR : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h0040F201;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= SERIAL_OUTPUT_ADC_LR_TO_SERIAL_OUTPUT_L0_R0;
        end
      end
      
      SERIAL_OUTPUT_ADC_LR_TO_SERIAL_OUTPUT_L0_R0 : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h0040F301;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= CLOCK_ALL_ENGINES_ENABLE;
        end
      end  
      
      CLOCK_ALL_ENGINES_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h0040F97F;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= CLOCK_GENERATORS_ENABLE;
        end
      end
      
      CLOCK_GENERATORS_ENABLE : begin
        o_enable     <= 1'b1;
        o_data       <= 32'h0040FA03;
        if (i_done == 1'b1) begin
          o_enable   <= 1'b0;
          fsm_state  <= IDLE;
        end
      end          
      
      default : begin
        fsm_state    <= IDLE;
      end
      
    endcase
  end

endmodule