/*
Distributed under the MIT license.
Copyright (c) 2022 Dave McCoy (dave.mccoy@cospandesign.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/*
 * Author:
 * Description:
 *
 * Changes:     Who?    What?
 *  XX/XX/XXXX  XXX     XXXX
 */

`timescale 1ps / 1ps

module audio_axi_stream_transmitter(
  input                         audio_clk,
  input                         audio_reset,
  input         [15: 0]         audio_sample,

  //Audio Enable
  input                         ctrl_audio_en,

  //Audio Channel
  input                         axis_audio_clk,
  input                         axis_audio_rst,
  output reg    [3:0]           axis_audio_tid,
  output                        axis_audio_tvalid,
  input                         axis_audio_tready,
  output reg    [31: 0]         axis_audio_tdata,
  output reg                    axis_audio_tlast
);

//local parameters
localparam     IDLE         = 4'h0;
localparam     SEND_LEFT    = 4'h1;
localparam     SEND_RIGHT   = 4'h2;
//registes/wires
//(* ASYNC_REG="true" *) reg [2:0]     r_prev_audio_sr;
wire            axis_audio_stb;


wire  [15: 0]   audio_l_sample;
wire  [15: 0]   audio_r_sample;



wire  [31: 0]   axis_audio_l_sample;
wire  [31: 0]   axis_audio_r_sample;

wire            parity_l_bit;
wire            parity_r_bit;
reg             user_bit;
wire            valid_bit;
wire            channel_status_bit;

reg   [3:0]     state;

reg             r_audio_fifo_wren;
wire            w_audio_fifo_wren;
wire            w_audio_fifo_full;
wire            w_axis_read_en;
wire            w_axis_read_empty;

wire  [15:0]    w_audio_sample_out;
wire            w_read_new_data;

reg             r_axis_read_en;

(* ASYNC_REG="true" *) reg  [2:0]     r_prev_audio_sr;

//submodules
fifo #(
  .WIDTH          (16                 ),
  .DEPTH          (64                 )
)f(
  .i_w_clk        (audio_clk          ),
  .i_w_rst        (audio_reset        ),


  .i_w_fifo_stb   (w_audio_fifo_wren  ),
  .i_w_fifo_data  (audio_sample       ),
  .o_w_fifo_full  (w_audio_fifo_full  ),


  .i_r_clk        (axis_audio_clk     ),
  .i_r_rst        (axis_audio_rst     ),

  .i_r_fifo_stb   (r_axis_read_en     ),
  .o_r_fifo_data  (w_audio_sample_out ),
  .o_r_fifo_empty (w_axis_read_empty  )
);

assign  w_audio_fifo_wren = (r_prev_audio_sr == 3'b111);

always @ (posedge audio_clk) begin
  if (audio_reset) begin
    r_prev_audio_sr     <=  0;
  end
  else begin
    r_prev_audio_sr     <=  {r_prev_audio_sr[1:0], ctrl_audio_en};
  end
end

//asynchronous logic
assign  valid_bit           = 1'b0;
assign  user_bit            = 1'b0;
assign  channel_status_bit  = 1'b0;
assign  audio_l_sample      = w_audio_sample_out;
assign  audio_r_sample      = w_audio_sample_out;

assign  parity_l_bit        = ((^audio_l_sample)^valid_bit^user_bit^channel_status_bit); 
assign  parity_r_bit        = ((^audio_r_sample)^valid_bit^user_bit^channel_status_bit); 

assign  axis_audio_l_sample = {parity_l_bit, channel_status_bit, user_bit, valid_bit, audio_l_sample, 4'b0001};
assign  axis_audio_r_sample = {parity_r_bit, channel_status_bit, user_bit, valid_bit, audio_r_sample, 4'b0011};


assign  w_axis_read_en      = (axis_audio_tready && axis_audio_tvalid);
assign  w_read_new_data       = (!w_axis_read_empty && w_audio_fifo_wren &&
                                 ((state == IDLE) ||
                                  ((state == SEND_RIGHT) && w_axis_read_en)
                                 )
                                );


assign  axis_audio_tvalid   = (state != IDLE);

always @ (posedge axis_audio_clk) begin
  r_axis_read_en          <=  0;
  if (w_read_new_data) begin
    r_axis_read_en        <=  1;
  end
end


always @ (posedge axis_audio_clk) begin
  if (axis_audio_rst) begin
    state                     <=  IDLE;
    axis_audio_tid            <=  4'b0000;
    axis_audio_tdata          <=  1'b0;
    axis_audio_tlast          <=  1'b0;
  end
  else begin
    case (state)
      IDLE: begin
        if (w_read_new_data) begin
          axis_audio_tid      <=  4'b0000;
          axis_audio_tdata    <=  axis_audio_l_sample;
          state               <=  SEND_LEFT;
        end
      end
      SEND_LEFT: begin
        if (w_axis_read_en) begin
          axis_audio_tid      <=  4'b0001;
          axis_audio_tdata    <=  axis_audio_r_sample;
          state               <=  SEND_RIGHT;
        end
      end
      SEND_RIGHT: begin
        if (w_axis_read_en) begin
          if (w_audio_fifo_wren) begin
            axis_audio_tid      <=  4'b0000;
            axis_audio_tdata    <=  axis_audio_l_sample;
            state               <=  SEND_LEFT;
          end
          else begin
            state               <=  IDLE;
          end

        end
      end
      default: begin
        state                 <=  IDLE;
      end
    endcase
  end
end


endmodule
