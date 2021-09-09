/*
Distributed under the MIT license.
Copyright (c) 2021 Dave McCoy (dave.mccoy@cospandesign.com)

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
 * Changes:
 */

`timescale 1ps / 1ps

`ifndef CLOG2
`define CLOG2(x) \
   (x <= 2)     ? 1 :  \
   (x <= 4)     ? 2 :  \
   (x <= 8)     ? 3 :  \
   (x <= 16)    ? 4 :  \
   -1
`endif

`define MAJOR_VERSION             1
`define MINOR_VERSION             0
`define REVISION                  0

`define MAJOR_RANGE               31:28
`define MINOR_RANGE               27:20
`define REVISION_RANGE            19:16
`define VERSION_PAD_RANGE         15:0

`define RED_BIT_RANGE             23:16
`define GREEN_BIT_RANGE           15:8
`define BLUE_BIT_RANGE            7:0

`define CTRL_BIT_EN               0
`define CTRL_BIT_AUTO             1

`define PWM_LENGTH_RANGE          15:0

`define STATE_CTRL_COUNT_RANGE   31:24
`define STATE_CTRL_COLOR_RANGE   23:0
`define STATE_COUNT_RANGE         7:0
`define STATE_TRANS_RANGE         15:0

`define DEFAULT_PWM_LENGTH        10
`define DEFAULT_TRANS_SHIFT       10

`default_nettype wire

module lightshow #(
  parameter ADDR_WIDTH          = 16,
  parameter DATA_WIDTH          = 32,
  parameter STROBE_WIDTH        = (DATA_WIDTH / 8),
  parameter INVERT_AXI_RESET    = 1,
  parameter COLOR_DEPTH         = 16,          //Number of
  parameter DEFAULT_CLK_DIV     = 100,
  parameter SHIFT_DEPTH         = 16          //Max Depth

)(
  input                               i_axi_clk,
  input                               i_axi_rst,

  //Write Address Channel
  input                               i_awvalid,
  input       [ADDR_WIDTH - 1: 0]     i_awaddr,
  output                              o_awready,

  //Write Data Channel
  input                               i_wvalid,
  output                              o_wready,
  input       [STROBE_WIDTH - 1:0]    i_wstrb,
  input       [DATA_WIDTH - 1: 0]     i_wdata,

  //Write Response Channel
  output                              o_bvalid,
  input                               i_bready,
  output      [1:0]                   o_bresp,

  //Read Address Channel
  input                               i_arvalid,
  output                              o_arready,
  input       [ADDR_WIDTH - 1: 0]     i_araddr,

  //Read Data Channel
  output                              o_rvalid,
  input                               i_rready,
  output      [1:0]                   o_rresp,
  output      [DATA_WIDTH - 1: 0]     o_rdata,

  output                              o_red,
  output                              o_green,
  output                              o_blue
);
//local parameters

//Address Map
localparam  REG_CONTROL       = 0 << 2;
localparam  REG_CLK_DIV       = 1 << 2;
localparam  REG_RGB0_COLOR    = 2 << 2;
localparam  REG_RGB1_COLOR    = 3 << 2;
localparam  REG_ST_CTRL       = 4 << 2;
localparam  REG_ST_COUNT      = 5 << 2;
localparam  REG_ST_PWM_LEN    = 6 << 2;
localparam  REG_ST_TRANS_LEN  = 7 << 2;
localparam  REG_VERSION       = 8 << 2;

localparam  MAX_ADDR          = REG_VERSION;

//registers/wires

//User Interface
wire                              w_axi_rst;
wire  [ADDR_WIDTH - 1: 0]         w_reg_address;
reg                               r_reg_invalid_addr;
reg   [31:0]                      r_clk_div;

wire                              w_reg_in_rdy;
reg                               r_reg_in_ack;
wire  [DATA_WIDTH - 1: 0]         w_reg_in_data;

wire                              w_reg_out_req;
reg                               r_reg_out_rdy;
reg   [DATA_WIDTH - 1: 0]         r_reg_out_data;

reg                               r_en            = 0;
reg                               r_auto          = 0;

reg   [7:0]                       r_rgb0_red      = 0;
reg   [7:0]                       r_rgb0_green    = 0;
reg   [7:0]                       r_rgb0_blue     = 0;

reg   [7:0]                       r_rgb1_red      = 0;
reg   [7:0]                       r_rgb1_green    = 0;
reg   [7:0]                       r_rgb1_blue     = 0;

wire  [23:0]                      w_rgb0_manual;
wire  [23:0]                      w_rgb1_manual;


reg   [15:0]                      r_trans_shift;
reg   [15:0]                      r_pwm_length;
reg   [7:0]                       r_auto_state_index;
reg   [7:0]                       r_auto_state_count;
reg   [23:0]                      r_auto_state_color;
reg                               r_auto_state_stb;

//TEMP DATA, JUST FOR THE DEMO
wire  [DATA_WIDTH - 1: 0]         w_version;


//submodules

//Convert AXI Slave bus to a simple register/address strobe
axi_lite_slave #(
  .ADDR_WIDTH         (ADDR_WIDTH           ),
  .DATA_WIDTH         (DATA_WIDTH           )

) axi_lite_reg_interface (
  .clk                (i_axi_clk            ),
  .rst                (w_axi_rst            ),


  .i_awvalid          (i_awvalid            ),
  .i_awaddr           (i_awaddr             ),
  .o_awready          (o_awready            ),

  .i_wvalid           (i_wvalid             ),
  .o_wready           (o_wready             ),
  .i_wstrb            (i_wstrb              ),
  .i_wdata            (i_wdata              ),

  .o_bvalid           (o_bvalid             ),
  .i_bready           (i_bready             ),
  .o_bresp            (o_bresp              ),

  .i_arvalid          (i_arvalid            ),
  .o_arready          (o_arready            ),
  .i_araddr           (i_araddr             ),

  .o_rvalid           (o_rvalid             ),
  .i_rready           (i_rready             ),
  .o_rresp            (o_rresp              ),
  .o_rdata            (o_rdata              ),


  //Simple Register Interface
  .o_reg_address      (w_reg_address        ),
  .i_reg_invalid_addr (r_reg_invalid_addr   ),

  //Ingress Path (From Master)
  .o_reg_in_rdy       (w_reg_in_rdy         ),
  .i_reg_in_ack       (r_reg_in_ack         ),
  .o_reg_in_data      (w_reg_in_data        ),

  //Egress Path (To Master)
  .o_reg_out_req      (w_reg_out_req        ),
  .i_reg_out_rdy      (r_reg_out_rdy        ),
  .i_reg_out_data     (r_reg_out_data       )
);

rgb_led_control #(
  .COLOR_DEPTH        (COLOR_DEPTH          ),
  .SHIFT_DEPTH        (SHIFT_DEPTH          )

) rgb0_c (
  .clk                (i_axi_clk            ),
  .rst                (w_axi_rst            ),

  .i_en               (r_en                 ),
  .i_auto             (r_auto               ),
  .i_rgb_manual       (w_rgb0_manual        ),
  .i_trans_shift      (r_trans_shift        ),
  .i_pwm_length       (r_pwm_length         ),
  .i_clk_div          (r_clk_div            ),

  .i_auto_state_index (r_auto_state_index   ),
  .i_auto_state_count (r_auto_state_count   ),
  .i_auto_state_color (r_auto_state_color   ),
  .i_auto_state_stb   (r_auto_state_stb     ),

  .o_red              (o_red                ),
  .o_blue             (o_blue               ),
  .o_green            (o_green              )



);

//asynchronous logic

assign w_axi_rst                      = INVERT_AXI_RESET ? ~i_axi_rst : i_axi_rst;
assign w_version[`MAJOR_RANGE]        = `MAJOR_VERSION;
assign w_version[`MINOR_RANGE]        = `MINOR_VERSION;
assign w_version[`REVISION_RANGE]     = `REVISION;
assign w_version[`VERSION_PAD_RANGE]  = 0;

assign w_rgb0_manual  = {r_rgb0_red, r_rgb0_green, r_rgb0_blue};
assign w_rgb1_manual  = {r_rgb1_red, r_rgb1_green, r_rgb1_blue};


//synchronous logic
always @ (posedge i_axi_clk) begin
  //De-assert Strobes
  r_reg_in_ack                            <=  0;
  r_reg_out_rdy                           <=  0;
  r_reg_invalid_addr                      <=  0;
  r_auto_state_stb                        <=  0;

  if (w_axi_rst) begin
    r_reg_out_data                        <=  0;

    //Reset the temporary Data
    r_en                                  <=  0;
    r_auto                                <=  0;  //Manual Mode by defualt
    r_clk_div                             <=  DEFAULT_CLK_DIV;

    r_rgb0_red                            <=  0;
    r_rgb0_green                          <=  0;
    r_rgb0_blue                           <=  0;

    r_rgb1_red                            <=  0;
    r_rgb1_green                          <=  0;
    r_rgb1_blue                           <=  0;

    r_pwm_length                          <=  `DEFAULT_PWM_LENGTH;
    r_trans_shift                         <=  `DEFAULT_TRANS_SHIFT;

    r_auto_state_index                    <= 0;
    r_auto_state_color                    <= 0;
    r_auto_state_count                    <= 0;

  end
  else begin

    if (w_reg_in_rdy) begin
      //From master
      case (w_reg_address)
        REG_CONTROL: begin
          r_en                            <=  w_reg_in_data[`CTRL_BIT_EN];
          r_auto                          <=  w_reg_in_data[`CTRL_BIT_AUTO];
        end
        REG_CLK_DIV: begin
          r_clk_div                       <=  w_reg_in_data;
        end
        REG_RGB0_COLOR: begin
          r_rgb0_red                      <=  w_reg_in_data[`RED_BIT_RANGE];
          r_rgb0_green                    <=  w_reg_in_data[`GREEN_BIT_RANGE];
          r_rgb0_blue                     <=  w_reg_in_data[`BLUE_BIT_RANGE];
        end
        REG_RGB1_COLOR: begin
          r_rgb1_red                      <=  w_reg_in_data[`RED_BIT_RANGE];
          r_rgb1_green                    <=  w_reg_in_data[`GREEN_BIT_RANGE];
          r_rgb1_blue                     <=  w_reg_in_data[`BLUE_BIT_RANGE];
        end
        REG_ST_PWM_LEN: begin
          r_pwm_length                    <=  w_reg_in_data[`PWM_LENGTH_RANGE];
        end
        REG_ST_CTRL: begin
          r_auto_state_stb                <=  1;
          r_auto_state_index              <=  w_reg_in_data[`STATE_CTRL_COUNT_RANGE];
          r_auto_state_color              <=  w_reg_in_data[`STATE_CTRL_COLOR_RANGE];
        end
        REG_ST_COUNT: begin
          r_auto_state_count              <=  w_reg_in_data[`STATE_COUNT_RANGE];
        end
        REG_ST_TRANS_LEN: begin
          r_trans_shift                   <=  w_reg_in_data[`STATE_TRANS_RANGE];
        end
        default: begin
          $display ("Unknown address: 0x%h", w_reg_address);
          //Tell the host they wrote to an invalid address
          r_reg_invalid_addr              <= 1;
        end
      endcase
      //Tell the AXI Slave Control we're done with the data
     r_reg_in_ack                         <= 1;
    end
    else if (w_reg_out_req) begin
      //To master
      case (w_reg_address)
        REG_CONTROL: begin
          r_reg_out_data                    <= 32'h0;
          r_reg_out_data[`CTRL_BIT_EN]      <= r_en;
          r_reg_out_data[`CTRL_BIT_AUTO]    <= r_auto;
        end
        REG_CLK_DIV: begin
          r_reg_out_data                    <= r_clk_div;
        end
        REG_RGB0_COLOR: begin
          r_reg_out_data                    <= 32'h0;
          r_reg_out_data[`RED_BIT_RANGE]    <= r_rgb0_red;
          r_reg_out_data[`GREEN_BIT_RANGE]  <= r_rgb0_green;
          r_reg_out_data[`BLUE_BIT_RANGE]   <= r_rgb0_blue;
        end
        REG_RGB1_COLOR: begin
          r_reg_out_data                    <= 32'h0;
          r_reg_out_data[`RED_BIT_RANGE]    <= r_rgb1_red;
          r_reg_out_data[`GREEN_BIT_RANGE]  <= r_rgb1_green;
          r_reg_out_data[`BLUE_BIT_RANGE]   <= r_rgb1_blue;
        end
        REG_ST_PWM_LEN: begin
          r_reg_out_data                    <= 32'h0;
          r_reg_out_data[`PWM_LENGTH_RANGE] <=  r_pwm_length;
        end
        REG_ST_CTRL: begin
          r_reg_out_data                    <= 32'h0;
        end
        REG_ST_COUNT: begin
          r_reg_out_data                    <= 32'h0;
          r_reg_out_data[`STATE_COUNT_RANGE]<=  r_auto_state_color;
        end
        REG_ST_TRANS_LEN: begin
          r_reg_out_data                    <= 32'h0;
          r_reg_out_data[`STATE_TRANS_RANGE]<=  r_trans_shift;
        end
        REG_VERSION: begin
          r_reg_out_data                    <= w_version;
        end
        default: begin
          //Unknown address
          r_reg_out_data                  <= 32'h00;
          r_reg_invalid_addr              <= 1;
        end
      endcase
      //Tell the AXI Slave to send back this packet
      r_reg_out_rdy                       <= 1;
    end
  end
end


endmodule
