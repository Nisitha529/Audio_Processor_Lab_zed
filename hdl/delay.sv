module delay #(
    parameter string DELAY_TYPE = "STEREO",         // "STEREO"
    parameter string FEED_TYPE = "FEEDBACK"         // "FEEDBACK", "FEEDFORWARD"
    )(
    input   logic           i_clock,
    input   logic           i_enable,
    input   logic [31 : 0]  i_data_left,
    input   logic [31 : 0]  i_data_right,
    input   logic           i_data_valid,
    output  logic [31 : 0]  o_data_left,
    output  logic [31 : 0]  o_data_right,
    output  logic           o_data_valid
);

    // Floating-point Multiplier
    logic           fp_mult_valid_out;
    logic [31 : 0]  fp_mult_data_out;
    logic [31 : 0]  fp_multiplier_data_a_in;
    parameter logic [31 : 0]  FEEDBACK_GAIN = 31'b00111111010000000000000000000000;     // 0.75
    logic           fp_multiplier_data_valid;
    fp_multiplier fp_multiplier_inst(
        .aclk                   (i_clock),
        .s_axis_a_tvalid        (fp_multiplier_data_valid),
        .s_axis_a_tdata         (fp_multiplier_data_a_in),
        .s_axis_b_tvalid        (fp_multiplier_data_valid),
        .s_axis_b_tdata         (FEEDBACK_GAIN),
        .m_axis_result_tvalid   (fp_mult_valid_out),
        .m_axis_result_tdata    (fp_mult_data_out)
    );

    // Floating-point Adder
    logic           fp_adder_valid_out;
    logic [31 : 0]  fp_adder_data_out;
    logic [31 : 0]  fp_adder_data_a_in;
    logic [31 : 0]  fp_adder_data_b_in;
    logic           fp_adder_data_valid;
    fp_adder fp_adder_inst(
        .aclk                   (i_clock),
        .s_axis_a_tvalid        (fp_adder_data_valid),
        .s_axis_a_tdata         (fp_adder_data_a_in),
        .s_axis_b_tvalid        (fp_adder_data_valid),
        .s_axis_b_tdata         (fp_adder_data_b_in),
        .m_axis_result_tvalid   (fp_adder_valid_out),
        .m_axis_result_tdata    (fp_adder_data_out)
    );

    // Circular Buffer for the Left Channel
    logic           delay_buffer_left_wr_en;
    logic [13 : 0]  delay_buffer_left_addra = 'b0;
    logic [31 : 0]  delay_buffer_left_dina;
    logic [13 : 0]  delay_buffer_left_addrb = 14'd1;
    logic [31 : 0]  delay_buffer_left_doutb;
    delay_circular_buffer delay_circular_buffer_left_inst(
        .clka   (i_clock),
        .wea    (delay_buffer_left_wr_en),
        .addra  (delay_buffer_left_addra),
        .dina   (delay_buffer_left_dina),
        .clkb   (i_clock),
        .addrb  (delay_buffer_left_addrb),
        .doutb  (delay_buffer_left_doutb)
    );

    // Circular Buffer for the Right Channel
    logic           delay_buffer_right_wr_en;
    logic [13 : 0]  delay_buffer_right_addra = 'b0;
    logic [31 : 0]  delay_buffer_right_dina;
    logic [13 : 0]  delay_buffer_right_addrb = 14'd1;
    logic [31 : 0]  delay_buffer_right_doutb;
    delay_circular_buffer delay_circular_buffer_right_inst(
        .clka   (i_clock),
        .wea    (delay_buffer_right_wr_en),
        .addra  (delay_buffer_right_addra),
        .dina   (delay_buffer_right_dina),
        .clkb   (i_clock),
        .addrb  (delay_buffer_right_addrb),
        .doutb  (delay_buffer_right_doutb)
    );

    // Main FSM
    enum logic [2 : 0]  {IDLE,
                        DELAY_GAIN_LEFT,
                        DELAY_GAIN_RIGHT,
                        ADD_OUTPUT_LEFT,
                        ADD_OUTPUT_RIGHT,
                        GENERATE_OUTPUT} fsm_state = IDLE;
    logic [31 : 0]  current_sample_left;
    logic [31 : 0]  current_sample_right;
    logic [31 : 0]  sample_left_aux;
    logic [31 : 0]  sample_right_aux;
    logic [31 : 0]  data_left;
    logic [31 : 0]  data_right;
    logic           data_valid;

    always_ff @(posedge i_clock) begin
        case (fsm_state)
            IDLE : begin
                fp_adder_data_valid <= 1'b0;
                delay_buffer_left_wr_en <= 1'b0;
                delay_buffer_right_wr_en <= 1'b0;
                data_valid <= 1'b0;
                if (i_data_valid == 1'b1) begin
                    current_sample_left <= i_data_left;
                    current_sample_right <= i_data_right;
                    if (FEED_TYPE == "FEEDFORWARD") begin
                        delay_buffer_left_dina <= i_data_left;
                        delay_buffer_left_wr_en <= 1'b1;
                        delay_buffer_right_dina <= i_data_right;
                        delay_buffer_right_wr_en <= 1'b1;
                    end
                    fp_multiplier_data_a_in <= delay_buffer_left_doutb;     // Start the delay gain on the left channel
                    fp_multiplier_data_valid <= 1'b1;
                    if (delay_buffer_left_addra == 16383) begin              // Wrap the pointers around if they reach the end of the buffer
                        delay_buffer_left_addra <= 0;
                        delay_buffer_left_addrb <= 1;
                    end
                    if (delay_buffer_right_addra == 16383) begin             // Wrap the pointers around if they reach the end of the buffer
                        delay_buffer_right_addra <= 0;
                        delay_buffer_right_addrb <= 1;
                    end
                    fsm_state <= DELAY_GAIN_LEFT;
                end
            end

            DELAY_GAIN_LEFT : begin
                delay_buffer_left_wr_en <= 1'b0;
                delay_buffer_right_wr_en <= 1'b0;
                fp_multiplier_data_valid <= 1'b0;
                if (fp_mult_valid_out == 1'b1) begin
                    sample_left_aux <= fp_mult_data_out;
                    fp_multiplier_data_a_in <= delay_buffer_right_doutb;    // Start the delay gain on the right channel
                    fp_multiplier_data_valid <= 1'b1;
                    fsm_state <= DELAY_GAIN_RIGHT;
                end
            end

            DELAY_GAIN_RIGHT : begin
                fp_multiplier_data_valid <= 1'b0;
                if (fp_mult_valid_out == 1'b1) begin
                    sample_right_aux <= fp_mult_data_out;
                    fp_adder_data_a_in <= current_sample_left;              // Start adding the current left sample with the delayed one
                    fp_adder_data_b_in <= sample_left_aux;
                    fp_adder_data_valid <= 1'b1;
                    fsm_state <= ADD_OUTPUT_LEFT;
                end
            end

            ADD_OUTPUT_LEFT : begin
                fp_adder_data_valid <= 1'b0;
                if (fp_adder_valid_out == 1'b1) begin
                    data_left <= fp_adder_data_out;
                    if (FEED_TYPE == "FEEDBACK") begin
                        delay_buffer_left_dina <= fp_adder_data_out;
                        delay_buffer_left_wr_en <= 1'b1;
                    end;
                    fp_adder_data_a_in <= current_sample_right;             // Start adding the current right sample with the delayed one
                    fp_adder_data_b_in <= sample_right_aux;
                    fp_adder_data_valid <= 1'b1;
                    fsm_state <= ADD_OUTPUT_RIGHT;
                end
            end

            ADD_OUTPUT_RIGHT : begin
                fp_adder_data_valid <= 1'b0;
                delay_buffer_left_wr_en <= 1'b0;
                if (fp_adder_valid_out == 1'b1) begin
                    data_right <= fp_adder_data_out;
                    if (FEED_TYPE == "FEEDBACK") begin
                        delay_buffer_right_dina <= fp_adder_data_out;
                        delay_buffer_right_wr_en <= 1'b1;
                    end;
                    data_valid <= 1'b1;
                    delay_buffer_left_addra <= delay_buffer_left_addra + 1; // Increment the write and read pointers
                    delay_buffer_left_addrb <= delay_buffer_left_addrb + 1;
                    delay_buffer_right_addra <= delay_buffer_right_addra + 1;
                    delay_buffer_right_addrb <= delay_buffer_right_addrb + 1;
                    fsm_state <= IDLE;
                end;
            end

            default : begin
                fsm_state <= IDLE;
            end
        endcase
    end

    // Bypass control
    always_comb begin
        if (i_enable == 1'b1) begin
            o_data_left = data_left;
            o_data_right = data_right;
            o_data_valid = data_valid;
        end else begin
            o_data_left = i_data_left;
            o_data_right = i_data_right;
            o_data_valid = i_data_valid;
        end
    end

endmodule