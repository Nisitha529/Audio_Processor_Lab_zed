`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2025 09:13:00 AM
// Design Name: 
// Module Name: debouncer
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

module debouncer # (
    parameter SWITCH_COUNT              = 8,
    parameter BUTTON_COUNT              = 5,
    parameter DEBOUNCE_COUNTER_WIDTH    = 16
) (
    // Clock
    input  i_clock,
    // Debounce counter values
    input  [DEBOUNCE_COUNTER_WIDTH-1 : 0] i_switch_debounce_counter,
    input  [DEBOUNCE_COUNTER_WIDTH-1 : 0] i_button_debounce_counter,
    // Input switches
    input  i_sw0,
    input  i_sw1,
    input  i_sw2,
    input  i_sw3,
    input  i_sw4,
    input  i_sw5,
    input  i_sw6,
    input  i_sw7,
    // Input buttons
    input  i_btnu,
    input  i_btnd,
    input  i_btnl,
    input  i_btnr,
    input  i_btnc,
    // Debounced switch outputs
    output o_sw0,
    output o_sw1,
    output o_sw2,
    output o_sw3,
    output o_sw4,
    output o_sw5,
    output o_sw6,
    output o_sw7,
    // Debounced button outputs
    output o_btnu,
    output o_btnd,
    output o_btnl,
    output o_btnr,
    output o_btnc
);

wire [SWITCH_COUNT-1 : 0] bouncing_switch_array;
wire [SWITCH_COUNT-1 : 0] debounced_switch_array;
wire [BUTTON_COUNT-1 : 0] bouncing_button_array;
wire [BUTTON_COUNT-1 : 0] debounced_button_array;

assign bouncing_switch_array    = {i_sw7, i_sw6, i_sw5, i_sw4, i_sw3, i_sw2, i_sw1, i_sw0};
assign debounced_switch_array   = {o_sw7, o_sw6, o_sw5, o_sw4, o_sw3, o_sw2, o_sw1, o_sw0};
assign bouncing_button_array    = {i_btnu, i_btnd, i_btnl, i_btnr, i_btnc};
assign debounced_button_array   = {o_btnu, o_btnd, o_btnl, o_btnr, o_btnc};

    genvar i;
    generate
        for (i = 0; i < SWITCH_COUNT; i = i + 1) begin : switch_debounce_fsm_gen
            debounce_fsm 
            # (
                .DEBOUNCE_COUNTER_WIDTH (DEBOUNCE_COUNTER_WIDTH)
            )
            switch_debounce_fsm_inst (
                .i_clock            (i_clock),
                .i_debounce_counter (i_switch_debounce_counter),
                .i_bouncing_signal  (bouncing_switch_array[i]),
                .o_debounced_signal (debounced_switch_array[i])
            );
        end 
    endgenerate

    genvar j;
    generate
        for (j = 0; j < BUTTON_COUNT; j = j + 1) begin : button_debounce_fsm_gen
            debounce_fsm 
            # (
                .DEBOUNCE_COUNTER_WIDTH (DEBOUNCE_COUNTER_WIDTH)
            )
            button_debounce_fsm_inst (
                .i_clock            (i_clock),
                .i_debounce_counter (i_button_debounce_counter),
                .i_bouncing_signal  (bouncing_button_array[j]),
                .o_debounced_signal (debounced_button_array[j])
            );
        end 
    endgenerate

endmodule