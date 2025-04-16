`timescale 1ns / 1ps

module monitor_controller ( 
    input                 i_clock,
    // Audio Data Input
    input       [23 : 0]  i_data_left,
    input       [23 : 0]  i_data_right,
    input                 i_data_valid,
    // Buttons
    input                 i_btnu,
    input                 i_btnd,
    input                 i_btnl,
    input                 i_btnr,
    // Audio Data Output
    output  reg [23 : 0]  o_data_left,
    output  reg [23 : 0]  o_data_right,
    output  reg           o_data_valid
);

    reg btnu_delay;
    reg btnd_delay;
    reg btnl_delay;
    reg btnr_delay;
    reg toggle_up     = 1'b0;
    reg toggle_down   = 1'b0;
    reg toggle_left   = 1'b0;
    reg toggle_right  = 1'b0;
    
    always @(posedge i_clock) begin
        btnu_delay <= i_btnu;
        btnd_delay <= i_btnd;
        btnl_delay <= i_btnl;
        btnr_delay <= i_btnr;
        if ((i_btnu == 1'b1) & (btnu_delay == 1'b0)) begin
            toggle_up = ~ toggle_up;
        end
        if ((i_btnd == 1'b1) & (btnd_delay == 1'b0)) begin
            toggle_down = ~ toggle_down;
        end
        if ((i_btnl == 1'b1) & (btnl_delay == 1'b0)) begin
            toggle_left = ~ toggle_left;
        end
        if ((i_btnr == 1'b1) & (btnr_delay == 1'b0)) begin
            toggle_right = ~ toggle_right;
        end
        o_data_valid <= i_data_valid;
        o_data_left <= i_data_left;
        o_data_right <= i_data_right;
        // Dim
        if (toggle_up == 1'b1) begin
            o_data_left <= $signed(i_data_left) >>> 2;
            o_data_right <= $signed(i_data_right) >>> 2;
        end
        // Cut
        if (toggle_down == 1'b1) begin
            o_data_left <= 1'b0;
            o_data_right <= 1'b0;
        end
        // Mid
        if (toggle_left == 1'b1) begin
            o_data_left <= ($signed(i_data_left) + $signed(i_data_right)) >>> 1;
            o_data_right <= ($signed(i_data_left) + $signed(i_data_right)) >>> 1;
        end
        // Sides
        if (toggle_right == 1'b1) begin
            o_data_left <= ($signed(i_data_left) - $signed(i_data_right));
            o_data_right <= ($signed(i_data_left) - $signed(i_data_right));
        end
    end

endmodule