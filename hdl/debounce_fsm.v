`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2025 08:45:44 AM
// Design Name: 
// Module Name: debounce_fsm
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


module debounce_fsm #(
  parameter integer DEBOUNCE_COUNTER_WIDTH = 16
)(
  input                                   i_clock,
  
  input  [DEBOUNCE_COUNTER_WIDTH - 1 : 0] i_debounce_counter,
  input                                   i_bouncing_signal,
  
  output reg                              o_debounced_signal
);

reg                                  bouncing_signal_meta;
reg                                  bouncing_signal_stable;
reg [DEBOUNCE_COUNTER_WIDTH - 1 : 0] debounce_counter;
reg [1:0]                            fsm_state;

localparam IDLE           = 2'd0;
localparam EDGE_DETECTED  = 2'd1;
localparam DEBOUNCED_HIGH = 2'd2;
localparam DEBOUNCED_LOW  = 2'd3;

always @(posedge i_clock) begin
  bouncing_signal_meta    <= i_bouncing_signal;
  bouncing_signal_stable  <= bouncing_signal_meta;
  case (fsm_state)
    IDLE : begin
      o_debounced_signal  <= 1'b0;
      debounce_counter    <= 1'b0;
      fsm_state           <= EDGE_DETECTED;
    end
    
    EDGE_DETECTED : begin
      debounce_counter    <= debounce_counter + 1;
      if (debounce_counter == i_debounce_counter) begin
        debounce_counter  <= 1'b0;
        if ( bouncing_signal_stable == 1'b1) begin
          fsm_state       <= DEBOUNCED_HIGH;
        end else begin
          fsm_state       <= DEBOUNCED_LOW;
        end
      end
    end
    
    DEBOUNCED_HIGH : begin
      o_debounced_signal <= 1'b1;
      if (bouncing_signal_stable == 1'b0) begin
        fsm_state         <= EDGE_DETECTED;
      end
    end
    
    DEBOUNCED_LOW : begin
      o_debounced_signal <= 1'b0;
      if (bouncing_signal_stable == 1'b1) begin
        fsm_state        <= EDGE_DETECTED;
      end
    end
    
    default : begin
      fsm_state          <= IDLE;
    end
    
  endcase
end     

endmodule