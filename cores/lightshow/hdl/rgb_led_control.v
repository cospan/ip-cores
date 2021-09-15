/*
Distributed under the MIT license.
Copyright (c) 2021 Dave McCoy (cospan@gmail.com)

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
`default_nettype none

`define COLOR_RED         24'hFF0000
`define COLOR_ORANGE      24'hFFA500
`define COLOR_YELLOW      24'hFFFF00
`define COLOR_GREEN       24'h00FF00
`define COLOR_BLUE        24'h0000FF
`define COLOR_PURPLE      24'hA020F0
`define COLOR_WHITE       24'hFFFFFF
`define COLOR_BLACK       24'h000000
`define COLOR_TERQOISE    24'h00F5FF
`define COLOR_VIOLET      24'hEE82EE
`define COLOR_STEEL_BL    24'h63B8FF
`define COLOR_SPRINT_GR   24'h00FF7F
`define COLOR_STATE_BL    24'h836FFF
`define COLOR_OLIVE_DR1   24'hC0FF3E
`define COLOR_FORREST_GR  24'h228B22
`define COLOR_FIRE_BR_RED 24'hFF3030
`define COLOR_DARK_PINK   24'hFF1493

`ifndef CLOG2
`define CLOG2(x) \
   (x <= 2)     ? 1 :  \
   (x <= 4)     ? 2 :  \
   (x <= 8)     ? 3 :  \
   (x <= 16)    ? 4 :  \
   -1
`endif


module rgb_led_control #(
  parameter                 COLOR_DEPTH   = 4,          //Number of States
  parameter                 SHIFT_DEPTH   = 16          //Max Depth
)(
  input   wire                              clk,
  input   wire                              rst,

  input   wire                              i_en,
  input   wire                              i_auto,
  input   wire  [15:0]                      i_trans_shift,
  input   wire  [15:0]                      i_pwm_length,
  input   wire  [31:0]                      i_clk_div,

  input   wire  [7:0]                       i_auto_state_index,
  input   wire  [7:0]                       i_auto_state_count,
  input   wire  [23:0]                      i_auto_state_color,
  input   wire                              i_auto_state_stb,

  input   wire  [23:0]                      i_rgb_manual,

  output  wire                              o_red,
  output  wire                              o_blue,
  output  wire                              o_green
);

//local parameters
localparam      MAX_SHIFTED_PWM_VAL = ((1 << (8 + SHIFT_DEPTH)) - 1);

localparam      IDLE                = 4'h0;
localparam      AUTO_STATE          = 4'h1;
localparam      TRANS_CALC          = 4'h2;
localparam      TRANS_SHIFT         = 4'h3;
localparam      TRANS_INITIAL_CALC  = 4'h4;
localparam      TRANS_AUTO          = 4'h5;

//registes/wires
`ifdef SIM_DEBUG
wire  [7:0]                     w_debug_color_state_channel_red           = w_color_state_channel[0];
wire  [7:0]                     w_debug_color_state_channel_green         = w_color_state_channel[1];
wire  [7:0]                     w_debug_color_state_channel_blue          = w_color_state_channel[2];

wire  [7:0]                     w_debug_auto_color_red                    = r_auto_color[0];
wire  [7:0]                     w_debug_auto_color_green                  = r_auto_color[1];
wire  [7:0]                     w_debug_auto_color_blue                   = r_auto_color[2];

wire  [(8 + SHIFT_DEPTH) - 1:0] w_debug_auto_working_color_red            = r_auto_working_color[0];
wire  [(8 + SHIFT_DEPTH) - 1:0] w_debug_auto_working_color_green          = r_auto_working_color[1];
wire  [(8 + SHIFT_DEPTH) - 1:0] w_debug_auto_working_color_blue           = r_auto_working_color[2];

wire  [(8 + SHIFT_DEPTH) - 1:0] w_debug_auto_delta_color_red              = r_auto_delta_color[0];
wire  [(8 + SHIFT_DEPTH) - 1:0] w_debug_auto_delta_color_green            = r_auto_delta_color[1];
wire  [(8 + SHIFT_DEPTH) - 1:0] w_debug_auto_delta_color_blue             = r_auto_delta_color[2];

wire  [(8 + SHIFT_DEPTH) - 1:0] w_debug_color_state_channel_shift_red     = w_color_state_channel_shift[0];
wire  [(8 + SHIFT_DEPTH) - 1:0] w_debug_color_state_channel_shift_green   = w_color_state_channel_shift[1];
wire  [(8 + SHIFT_DEPTH) - 1:0] w_debug_color_state_channel_shift_blue    = w_color_state_channel_shift[2];

wire  [23:0]                    w_debug_state0_color                      = r_color_state[0];
wire  [23:0]                    w_debug_state1_color                      = r_color_state[1];
wire  [23:0]                    w_debug_state2_color                      = r_color_state[2];
wire  [23:0]                    w_debug_state3_color                      = r_color_state[3];

wire  [7:0]                     w_debug_pwm_red_init                      = w_pwm_init[0];
wire  [7:0]                     w_debug_pwm_green_init                    = w_pwm_init[1];
wire  [7:0]                     w_debug_pwm_blue_init                     = w_pwm_init[2];

wire  [8:0]                     w_debug_red_color                         = r_color[0];
wire  [8:0]                     w_debug_green_color                       = r_color[1];
wire  [8:0]                     w_debug_blue_color                        = r_color[2];

`endif

reg   [3:0]                       state = IDLE;
reg   [23:0]                      r_color_state[COLOR_DEPTH - 1: 0];
reg   [COLOR_DEPTH - 1: 0]        r_curr_index;
reg   [15:0]                      r_trans_count;
reg   [15:0]                      r_pwm_count;

wire  [7:0]                       w_color_state_channel[2:0];
reg   [7:0]                       r_auto_color[2:0];
reg   [(8 + SHIFT_DEPTH) - 1:0]   r_auto_working_color[2:0];
reg   [(8 + SHIFT_DEPTH) - 1:0]   r_auto_delta_color[2:0];
wire  [(8 + SHIFT_DEPTH) - 1:0]   w_color_state_channel_shift[2:0];
reg   [2:0]                       r_trans_up;

reg   [7:0]                       r_pwm_index;
reg   [31:0]                      r_clk_div_count;
reg                               r_pwm_clk_edge;

reg   [8:0]                       r_color[2:0];
wire  [7:0]                       w_pwm_init[2:0];


reg   [7:0]                       w_auto_green;
reg   [7:0]                       w_auto_blue;

reg   [7:0]                       r_auto_prev_red;
reg   [7:0]                       r_auto_prev_green;
reg   [7:0]                       r_auto_prev_blue;

reg  [`CLOG2(SHIFT_DEPTH) - 1:0]  r_trans_shift;
wire [`CLOG2(SHIFT_DEPTH) - 1:0]  w_trans_shift;

wire                              w_pwm_cycle;
wire  [SHIFT_DEPTH - 1:0]         w_trans_count;

//submodules
//asynchronous logic
assign  w_color_state_channel[0]  = r_color_state[r_curr_index][23:16];
assign  w_color_state_channel_shift[0][((8 + SHIFT_DEPTH) - 1): SHIFT_DEPTH]  = w_color_state_channel[0];
assign  w_color_state_channel_shift[0][SHIFT_DEPTH - 1: 0]  = 0;
assign  w_color_state_channel[1]  = r_color_state[r_curr_index][16: 8];
assign  w_color_state_channel_shift[1][((8 + SHIFT_DEPTH) - 1): SHIFT_DEPTH]  = w_color_state_channel[1];
assign  w_color_state_channel_shift[1][SHIFT_DEPTH - 1: 0]  = 0;

assign  w_color_state_channel[2]  = r_color_state[r_curr_index][ 7: 0];
assign  w_color_state_channel_shift[2][((8 + SHIFT_DEPTH) - 1): SHIFT_DEPTH]  = w_color_state_channel[2];
assign  w_color_state_channel_shift[2][SHIFT_DEPTH - 1: 0]  = 0;

assign  w_pwm_init[0]       = i_auto ? r_auto_color[0]  : i_rgb_manual[23:16];
assign  w_pwm_init[1]       = i_auto ? r_auto_color[1]  : i_rgb_manual[15: 8];
assign  w_pwm_init[2]       = i_auto ? r_auto_color[2]  : i_rgb_manual[ 7: 0];

assign  o_red               = r_color[0][8];
assign  o_green             = r_color[1][8];
assign  o_blue              = r_color[2][8];

//assign  o_red               = (r_color[0] > 9'h0FF);
//assign  o_green             = (r_color[1] > 9'h0FF);
//assign  o_blue              = (r_color[2] > 9'h0FF);



assign  w_pwm_cycle         = ((r_pwm_index == 255) && r_pwm_clk_edge);
assign  w_trans_count       = (2 ** w_trans_shift);
assign  w_trans_shift       = (i_trans_shift > `CLOG2(SHIFT_DEPTH)) ?
                                (i_trans_shift[`CLOG2(SHIFT_DEPTH) - 1:0]) :
                                (`CLOG2(SHIFT_DEPTH) - 1);

//synchronous logic

integer i;
initial begin
  //Initialize the color state table to 0x00 (black, off)
  for (i = 0; i < COLOR_DEPTH; i = i + 1) begin
    r_color_state[i]  <=  24'h00;
  end
end

//Clock Divider for PWM (use a clock edge instead of a clock so we don't need to generate a reset)
always @ (posedge clk) begin
  r_pwm_clk_edge              <=  0;
  if (rst) begin
    //clock divider
    r_clk_div_count           <=  0;
  end
  else begin
    if (r_clk_div_count < i_clk_div) begin
      r_clk_div_count         <=  r_clk_div_count + 1;
    end
    else begin
      r_clk_div_count         <=  r_clk_div_count <= 0;
      r_pwm_clk_edge          <=  1;
    end
  end
end

integer c;
//Color State Control
always @ (posedge clk) begin
  if (rst) begin
    state                   <= IDLE;
    r_curr_index            <=  0;
    r_trans_count           <=  0;
    r_pwm_count             <=  0;
    r_trans_shift           <=  0;
    r_trans_up              <=  0;

    for (c = 0; c < 3; c = c + 1) begin
      r_auto_color[c]           <=  0;
      r_auto_working_color[c]   <=  0;
      r_auto_delta_color[c]     <=  0;
    end
  end
  else begin
    if (i_auto_state_stb) begin
      r_color_state[i_auto_state_index] <=  i_auto_state_color;
    end

    case (state)
      IDLE: begin
        r_trans_shift <=  0;
        r_curr_index  <=  0;
        r_pwm_count   <=  0;
        r_trans_count <=  0;
        if (i_auto && i_en) begin
          state       <=  AUTO_STATE;
        end
      end
      AUTO_STATE: begin
        for (c = 0; c < 3; c = c + 1) begin
          r_auto_color[c] <=  w_color_state_channel[c];
        end
        if (r_pwm_count < i_pwm_length) begin
          if (w_pwm_cycle) begin
            r_pwm_count <=  r_pwm_count + 1;
          end
        end
        else begin
          if ((r_curr_index + 1) < i_auto_state_count)
            r_curr_index      <=  r_curr_index + 1;
          else
            r_curr_index      <=  0;

          for (c = 0; c < 3; c = c + 1) begin
            r_auto_working_color[c]       <=  0;
            r_auto_working_color[c][(8 + SHIFT_DEPTH) - 1:(8 + SHIFT_DEPTH) - 8]  <=  r_auto_color[c];
          end
          r_pwm_count         <=  0;
          r_trans_count       <=  0;
          state               <=  TRANS_CALC;
        end
      end
      TRANS_CALC: begin
        r_trans_shift         <=  0;
        if (w_trans_shift == 0) begin
          //No transition
          state               <=  AUTO_STATE;
        end
        else begin
          for (c = 0; c < 3; c = c + 1) begin
            r_auto_delta_color[c]           <=  0;
            if (w_color_state_channel[c] > r_auto_color[c]) begin
              r_auto_delta_color[c][((8 + SHIFT_DEPTH) - 1): SHIFT_DEPTH]  <=  w_color_state_channel[c] - r_auto_color[c];
              r_trans_up[c]                 <=  1;
            end
            else begin
              r_auto_delta_color[c][((8 + SHIFT_DEPTH) - 1): SHIFT_DEPTH]  <=  r_auto_color[c] - w_color_state_channel[c];
              r_trans_up[c]                 <=  0;
            end
          end
          state                             <=  TRANS_SHIFT;
        end
      end
      TRANS_SHIFT: begin
        if ((r_trans_shift) < w_trans_shift) begin
          for (c = 0; c < 3; c = c + 1) begin
            r_auto_delta_color[c][((8 + SHIFT_DEPTH) - 2):0]  <= r_auto_delta_color[c][((8 + SHIFT_DEPTH) - 1):1];
            r_auto_delta_color[c][((8 + SHIFT_DEPTH) - 1)]    <= 1'b0;
          end
          r_trans_shift                     <=  r_trans_shift + 1;  //Is there a less fugly way to do this??
        end
        else begin
          state                             <= TRANS_INITIAL_CALC;
        end

      end
      TRANS_INITIAL_CALC: begin
        for (c = 0; c < 3; c = c + 1) begin
          if (r_trans_up[c]) begin
            //going up
            if ((w_color_state_channel_shift[c] - r_auto_delta_color[c]) < r_auto_working_color[c])
              r_auto_working_color[c]        <=  w_color_state_channel_shift[c];
            else
              r_auto_working_color[c]        <=  r_auto_working_color[c] + r_auto_delta_color[c];
          end
          else begin
            //going down
            if ((w_color_state_channel_shift[c] + r_auto_delta_color[c]) > r_auto_working_color[c])
              r_auto_working_color[c]        <=  w_color_state_channel_shift[c];
            else
              r_auto_working_color[c]        <=  r_auto_working_color[c] - r_auto_delta_color[c];
          end
        end
        state                                 <=  TRANS_AUTO;
      end
      TRANS_AUTO: begin
        if (r_trans_count < w_trans_count) begin
          if (w_pwm_cycle) begin
            for (c = 0; c < 3; c = c + 1) begin
              r_auto_color[c]             <= r_auto_working_color[c][((8 + SHIFT_DEPTH) - 1): SHIFT_DEPTH];
              if (r_trans_up[c]) begin
                //going up
                if ((w_color_state_channel_shift[c] - r_auto_delta_color[c]) < r_auto_working_color[c])
                  r_auto_working_color[c]    <=  w_color_state_channel_shift[c];
                else
                  r_auto_working_color[c]    <=  r_auto_working_color[c] + r_auto_delta_color[c];
              end
              else begin
                //going down
                if ((w_color_state_channel_shift[c] + r_auto_delta_color[c]) > r_auto_working_color[c])
                  r_auto_working_color[c]    <=  w_color_state_channel_shift[c];
                else
                  r_auto_working_color[c]    <=  r_auto_working_color[c] - r_auto_delta_color[c];
              end
            end
            r_trans_count                     <=  r_trans_count + 1;
          end
        end
        else begin
          r_pwm_count   <=  0;
          r_trans_count <=  0;
          state         <=  AUTO_STATE;
        end
      end
      default: begin
        state           <=  IDLE;
      end
    endcase


    //Reset to IDLE when enable is de-asserted
    if (!i_en) begin
      state <=  IDLE;
    end
  end
end

//PWM Controller
always @ (posedge clk) begin
  if (rst) begin
    r_pwm_index           <=  0;

    for (c = 0; c < 3; c = c + 1) begin
      r_color[c]          <=  0;
    end
  end
  else begin
    if (i_en) begin
      if (r_pwm_clk_edge) begin
        if (r_pwm_index == 0) begin
          for (c = 0; c < 3; c = c + 1) begin
            r_color[c]  <=  w_pwm_init[c] + 1;
          end
        end
        else begin
          for (c = 0; c < 3; c = c + 1) begin
            if ((r_pwm_index != 8'hFF) || (r_color[c] != 9'h0FF))
              r_color[c]  <=  r_color[c] + 1;


          end
        end
        r_pwm_index     <=  r_pwm_index + 1;
      end
    end
    else begin
      r_pwm_index       <=  0;
    end
  end
end



endmodule
