`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2025 08:18:43 PM
// Design Name: 
// Module Name: spi_master
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


module spi_master #(
  parameter SPI_CLOCK_DIVIDER_WIDTH = 8,
  parameter SPI_DATA_WIDTH          = 8
)(
  input                                        i_clock,
  input                                        i_reset,
  
  //Data, control and status interface
  input                                        i_enable,
  input                                        i_clock_polarity,
  input                                        i_clock_phase,
  input      [SPI_CLOCK_DIVIDER_WIDTH - 1 : 0] i_spi_clock_divider,
  input      [SPI_DATA_WIDTH - 1 : 0]          i_data_in,
  output reg [SPI_DATA_WIDTH - 1 : 0]          o_data_out,
  output                                       o_done,
  output reg                                   o_busy,
  
  //SPI Interface
  input                                        i_spi_miso,
  output                                       o_spi_cs_n,
  output                                       o_spi_clock,
  output                                       o_spi_mosi
);

localparam IDLE         = 3'd0;
localparam PRE_DELAY    = 3'd1;
localparam SETUP        = 3'd2;
localparam TRANSMISSION = 3'd3;
localparam POST_DELAY   = 3'd4;
localparam DONE         = 3'd5;

reg [2:0] fsm_state;

reg [SPI_DATA_WIDTH - 1 : 0]          spi_data_counter;

reg [SPI_CLOCK_DIVIDER_WIDTH - 1 : 0] clock_counter;
reg                                   spi_clock;

reg                                   spi_clock_falling;
reg                                   spi_clock_rising;
reg                                   spi_clock_ff;

reg                                   enable_delay1;
reg                                   enable_delay2;
reg                                   enable_rising;
reg                                   spi_cs_n;
reg [SPI_DATA_WIDTH - 1 : 0]          data_out_shift;
reg [SPI_DATA_WIDTH - 1 : 0]          data_in_shift;
reg                                   spi_mosi;
reg                                   done;

// FSM for clock generation
always @(posedge i_clock) begin
  if (i_reset) begin
    spi_clock     <= 1'b0;
    clock_counter <= 8'd0;
  end else begin
    if ((fsm_state == TRANSMISSION) || (fsm_state == PRE_DELAY) || (fsm_state == POST_DELAY)) begin
      clock_counter   <= clock_counter + 8'd1;
      if (clock_counter == i_spi_clock_divider) begin
        if (fsm_state == TRANSMISSION) begin
          spi_clock   <= ~ spi_clock;
        end
        clock_counter <= 8'd0;
      end
    end else begin
      if (i_clock_polarity) begin
        spi_clock     <= 1'b1;
      end else begin
        spi_clock     <= 1'b0;
      end
      clock_counter   <= 8'd0;
    end
  end
end

// SPI clock edge detection
always @(posedge i_clock) begin
  spi_clock_ff       <= spi_clock;
  spi_clock_falling  <= 1'b0;
  spi_clock_rising   <= 1'b0;
  if ((spi_clock == 1'b1) && (spi_clock_ff == 1'b0)) begin
    spi_clock_rising <= 1'b1;
  end
  if ((spi_clock == 1'b0) && (spi_clock_ff == 1'b1)) begin
    spi_clock_rising <= 1'b0;
  end
end

always @(posedge i_clock) begin
  if (i_reset) begin
    fsm_state              <= IDLE;
    spi_data_counter       <= 8'd0;
    spi_cs_n               <= 1'b1;
    data_out_shift         <= 8'd0;
    done                   <= 1'b0;
    spi_mosi               <= 1'b0;
    data_in_shift          <= 8'd0;
    o_data_out             <= 8'd0;
    o_busy                 <= 1'b0;
  end else begin
    // Detecting the rising edge of the i_enable signal
    enable_delay1          <= i_enable;
    enable_delay2          <= enable_delay1;
    enable_rising          <= 1'b0;
    if ((enable_delay2 == 1'b0) && (enable_delay1 == 1'b1)) begin
      enable_rising        <= 1'b1;
    end
    
    case (fsm_state)
      IDLE : begin
        spi_cs_n           <= 1'b1;
        o_busy             <= 1'b0;
        if (enable_rising) begin
          fsm_state        <= PRE_DELAY;
          data_out_shift   <= i_data_in;
          data_in_shift    <= 1'b0;
          o_busy           <= 1'b1;
        end
      end
      
      PRE_DELAY : begin
        spi_cs_n           <= 1'b0;
        if (clock_counter == (i_spi_clock_divider - 1)) begin
          fsm_state        <= SETUP;
        end
      end
      
      SETUP : begin
        if (~i_clock_phase) begin
          spi_data_counter <= spi_data_counter + 8'd1;
          spi_mosi         <= data_out_shift[SPI_DATA_WIDTH - 1];
          data_out_shift   <= data_out_shift << 1;
        end
        fsm_state          <= TRANSMISSION;
      end
      
      TRANSMISSION : begin
        if (i_clock_phase && i_clock_polarity) begin
          if (spi_clock_rising == 1'b1) begin
            data_in_shift    <= {data_in_shift[SPI_DATA_WIDTH - 2 : 0], i_spi_miso};
          end
          if (spi_clock_falling == 1'b1) begin
            spi_data_counter <= spi_data_counter + 8'd1;
            spi_mosi         <= data_out_shift[SPI_DATA_WIDTH - 1];
            data_out_shift   <= data_out_shift << 1;
          end
          if ((spi_data_counter == SPI_DATA_WIDTH) && (clock_counter == (i_spi_clock_divider - 1)) && (spi_clock)) begin
            spi_data_counter <= 8'd0;
            fsm_state        <= POST_DELAY;
          end
        end
        
        if (i_clock_phase && (~i_clock_polarity)) begin
          if (spi_clock_falling == 1'b1) begin
            data_in_shift    <= {data_in_shift[SPI_DATA_WIDTH - 1 : 0], i_spi_miso};
          end
          if (spi_clock_rising == 1'b1) begin
            spi_data_counter <= spi_data_counter + 8'd1;
            spi_mosi         <= data_out_shift[SPI_DATA_WIDTH - 1];
            data_out_shift   <= data_out_shift << 1;
          end
          if ((spi_data_counter == SPI_DATA_WIDTH) && (clock_counter == (i_spi_clock_divider - 1)) && (~spi_clock)) begin
            spi_data_counter <= 8'd0;
            fsm_state        <= POST_DELAY;
          end
        end
        
        if ((~i_clock_phase) && i_clock_polarity) begin
          if (spi_clock_falling == 1'b1) begin
            data_in_shift    <= {data_in_shift[SPI_DATA_WIDTH - 1 : 0], i_spi_miso};
          end
          if (spi_clock_rising == 1'b1) begin
            spi_data_counter <= spi_data_counter + 8'd1;
            spi_mosi         <= data_out_shift[SPI_DATA_WIDTH - 1];
            data_out_shift   <= data_out_shift << 1;
          end
          if ((spi_data_counter == SPI_DATA_WIDTH) && (spi_clock_rising)) begin
            spi_data_counter <= 8'd0;
            fsm_state        <= POST_DELAY;
          end
        end
        
        if ((~i_clock_phase) && (~i_clock_polarity)) begin
          if (spi_clock_rising == 1'b1) begin
            data_in_shift    <= {data_in_shift[SPI_DATA_WIDTH - 1 : 0], i_spi_miso};
          end
          if (spi_clock_falling == 1'b1) begin
            spi_data_counter <= spi_data_counter + 8'd1;
            spi_mosi         <= data_out_shift[SPI_DATA_WIDTH - 1];
            data_out_shift   <= data_out_shift << 1;
          end
          if ((spi_data_counter == SPI_DATA_WIDTH) && (spi_clock_falling)) begin
            spi_data_counter <= 8'd0;
            fsm_state        <= POST_DELAY;
          end
        end
      end
      
      POST_DELAY : begin
        if (clock_counter == (i_spi_clock_divider - 1)) begin
          spi_cs_n           <= 1'b1;
          fsm_state          <= DONE;
        end
      end
      
      DONE : begin
        done                 <= 1'b1;
        o_data_out           <= data_in_shift;
        if (done) begin
          done               <= 1'b0;
          fsm_state          <= IDLE;
        end
      end
      
      default : begin
        fsm_state            <= IDLE;
      end
    endcase
  end
end

assign o_spi_clock = spi_clock;
assign o_done      = done;
assign o_spi_cs_n  = spi_cs_n;
assign o_spi_mosi  = spi_mosi;

endmodule