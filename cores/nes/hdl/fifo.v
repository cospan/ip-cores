/**
 * Generic FIFO.
 * Author: Carlos Diaz (2017)
 *
 * Parameters:
 *  WIDTH: Width of the data on the FIFO, default to 4.
 *  DEPTH: Depth of the FIFO, default to 4. (MUST BE A POWER OF 2!)
 *
 * Input signals:
 *  clk: Clock input.
 *  i_w_fifo_data: Data input, width controlled with WIDTH parameter.
 *  i_w_fifo_stb: Enable writing into the FIFO.
 *  i_r_fifo_stb: Enable reading from the FIFO.
 *
 * Output signals:
 *  o_r_fifo_data: Data output, witdh controlled with WIDTH parameter.
 *  o_w_fifo_full: 1bit signal, indicate when the FIFO is full.
 *  o_r_fifo_empty: 1bit signal, indicate when the FIFO is empty.
 *
 * Changed:
 *    2021.08.09: Changed names to be inline with my workflow
 *    2021.08.10: Added checks to determine if the next read/write
 *                will be out of bound
 *    2021.08.10: Fixed write_ptr so that it correctly points to
 *                last position, previously this incorrectly pointed
 *                to the last and not the read_ptr last
 *    2021.08.10: Added a note that the DEPTH must be a power of 2
**/

`timescale 1ns / 1ps
`default_nettype none


module fifo #(
  parameter WIDTH = 4,
  parameter DEPTH = 4
)(
  input  wire                 i_w_clk,
  input  wire                 i_w_rst,

  input  wire                 i_w_fifo_stb,
  input  wire     [WIDTH-1:0] i_w_fifo_data,
  output wire                 o_w_fifo_full,

  input  wire                 i_r_clk,
  input  wire                 i_r_rst,

  input  wire                 i_r_fifo_stb,
  output wire    [WIDTH-1:0]  o_r_fifo_data,
  output wire                 o_r_fifo_empty
);

//local parameters
//registes/wires

// memory will contain the FIFO data.
reg [WIDTH-1:0]         memory [0:DEPTH-1];
// $clog2(DEPTH+1)-2 to count from 0 to DEPTH
reg [$clog2(DEPTH)-1:0] write_ptr   = 0;
reg [$clog2(DEPTH)-1:0] r_write_ptr  = 0;
reg [$clog2(DEPTH)-1:0] read_ptr    = 0;
reg [$clog2(DEPTH)-1:0] r_read_ptr  = 0;

//submodules
//asynchronous logic
assign o_r_fifo_empty     = ( r_write_ptr == read_ptr);
assign o_w_fifo_full      = ( r_write_ptr == r_read_ptr);

//synchronous logic
assign o_r_fifo_data = memory[read_ptr];

always @ (posedge i_w_clk) begin
  if (i_w_rst) begin
    write_ptr           <=  0;
    r_write_ptr         <=  0;
  end
  else begin
    if ( i_w_fifo_stb && !o_w_fifo_full) begin
      r_write_ptr       <= write_ptr;
      write_ptr         <= write_ptr + 1;
      memory[write_ptr] <= i_w_fifo_data;
    end
  end
end

always @ ( posedge i_r_clk ) begin
  if (i_r_rst) begin
    read_ptr            <=  0;
    r_read_ptr          <=  (DEPTH - 1);
  end
  else begin
    if ( i_r_fifo_stb && !o_r_fifo_empty ) begin
      r_read_ptr        <= read_ptr;
      read_ptr          <= read_ptr + 1;
    end
  end
end

endmodule
