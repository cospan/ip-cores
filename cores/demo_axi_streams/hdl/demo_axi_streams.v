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
`default_nettype none

`define MAJOR_VERSION             1
`define MINOR_VERSION             0
`define REVISION                  0

`define MAJOR_RANGE               31:28
`define MINOR_RANGE               27:20
`define REVISION_RANGE            19:16
`define VERSION_PAD_RANGE         15:0

module demo_axi_streams #(
  parameter ADDR_WIDTH          = 16,
  parameter DATA_WIDTH          = 32,


  parameter AXIS_DATA_WIDTH     = 32,
  parameter AXIS_KEEP_WIDTH     = (AXIS_DATA_WIDTH / 8),
  parameter AXIS_DATA_USER_WIDTH= 0,
  parameter FIFO_DATA_WIDTH     = AXIS_DATA_WIDTH + 1 + 1,
//XXX Must be a power of 2
  parameter FIFO_DEPTH          = 4,
  //parameter FIFO_DEPTH          = 8,
  //parameter FIFO_DEPTH          = 16,
  parameter INVERT_AXI_RESET    = 1,
  parameter INVERT_AXIS_RESET   = 1
)(
  input  wire                             i_axi_clk,
  input  wire                             i_axi_rst,

  //Write Address Channel
  input  wire                             i_awvalid,
  input  wire [ADDR_WIDTH - 1: 0]         i_awaddr,
  output wire                             o_awready,

  //Write Data Channel
  input  wire                             i_wvalid,
  output wire                             o_wready,
  input  wire [DATA_WIDTH - 1: 0]         i_wdata,

  //Write Response Channel
  output wire                             o_bvalid,
  input  wire                             i_bready,
  output wire [1:0]                       o_bresp,

  //Read Address Channel
  input  wire                             i_arvalid,
  output wire                             o_arready,
  input  wire [ADDR_WIDTH - 1: 0]         i_araddr,

  //Read Data Channel
  output wire                             o_rvalid,
  input  wire                             i_rready,
  output wire [1:0]                       o_rresp,
  output wire [DATA_WIDTH - 1: 0]         o_rdata,


  //Input AXI Stream
  input  wire                             i_axis_clk,
  input  wire                             i_axis_rst,

  input  wire                             i_axis_in_tuser,
  input  wire                             i_axis_in_tvalid,
  output wire                             o_axis_in_tready,
  input  wire                             i_axis_in_tlast,
  input  wire   [AXIS_DATA_WIDTH - 1:0]   i_axis_in_tdata,


  output wire                             o_axis_out_tuser,
  output wire                             o_axis_out_tvalid,
  input  wire                             i_axis_out_tready,
  output wire                             o_axis_out_tlast,
  output wire    [AXIS_DATA_WIDTH - 1:0]  o_axis_out_tdata

);
//local parameters

//Address Map
localparam  REG_CONTROL      = 0 << 2;
localparam  REG_VERSION      = 1 << 2;

localparam  MAX_ADDR = REG_VERSION;

//registers/wires

//User Interface
wire                            w_axi_rst;
wire                            w_axis_rst;
wire  [ADDR_WIDTH - 1: 0]       w_reg_address;
reg                             r_reg_invalid_addr;
                                
wire                            w_reg_in_rdy;
reg                             r_reg_in_ack_stb;
wire  [DATA_WIDTH - 1: 0]       w_reg_in_data;
                                
wire                            w_reg_out_req;
reg                             r_reg_out_rdy_stb;
reg   [DATA_WIDTH - 1: 0]       r_reg_out_data;


//TEMP DATA, JUST FOR THE DEMO
reg   [DATA_WIDTH - 1: 0]       r_control;
wire  [DATA_WIDTH - 1: 0]       w_version;
                                
wire  [FIFO_DATA_WIDTH - 1:0]   w_fifo_w_data;
wire                            w_fifo_w_stb;
wire                            w_fifo_full;
wire                            w_fifo_not_full;
                                
wire  [FIFO_DATA_WIDTH - 1:0]   w_fifo_r_data;
wire                            w_fifo_r_stb;
wire                            w_fifo_empty;
wire                            w_fifo_not_empty;

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
  .i_reg_in_ack_stb   (r_reg_in_ack_stb     ),
  .o_reg_in_data      (w_reg_in_data        ),

  //Egress Path (To Master)
  .o_reg_out_req      (w_reg_out_req        ),
  .i_reg_out_rdy_stb  (r_reg_out_rdy_stb    ),
  .i_reg_out_data     (r_reg_out_data       )
);



axis_2_fifo_adapter #(
  .AXIS_DATA_WIDTH    (AXIS_DATA_WIDTH      )
)a2fa(
  .i_axis_tuser       (i_axis_in_tuser      ),
  .i_axis_tvalid      (i_axis_in_tvalid     ),
  .o_axis_tready      (o_axis_in_tready     ),
  .i_axis_tlast       (i_axis_in_tlast      ),
  .i_axis_tdata       (i_axis_in_tdata      ),

  .o_fifo_data        (w_fifo_w_data        ),
  .o_fifo_w_stb       (w_fifo_w_stb         ),
  .i_fifo_not_full    (w_fifo_not_full      )
);

fifo #(
  .DEPTH              (FIFO_DEPTH           ),
  .WIDTH              (FIFO_DATA_WIDTH      )
) axis_fifo (
  .clk                (i_axis_clk           ),
  .rst                (w_axis_rst           ),

  .i_fifo_w_stb       (w_fifo_w_stb         ),
  .i_fifo_w_data      (w_fifo_w_data        ),
  .o_fifo_full        (w_fifo_full          ),
  .o_fifo_not_full    (w_fifo_not_full      ),


  .i_fifo_r_stb       (w_fifo_r_stb         ),
  .o_fifo_r_data      (w_fifo_r_data        ),
  .o_fifo_empty       (w_fifo_empty         ),
  .o_fifo_not_empty   (w_fifo_not_empty     )
);

fifo_2_axis_adapter #(
  .AXIS_DATA_WIDTH    (AXIS_DATA_WIDTH      )
)f2aa(
  .o_fifo_r_stb       (w_fifo_r_stb         ),
  .i_fifo_data        (w_fifo_r_data        ),
  .i_fifo_not_empty   (w_fifo_not_empty     ),

  .o_axis_tuser       (o_axis_out_tuser     ),
  .o_axis_tdata       (o_axis_out_tdata     ),
  .o_axis_tvalid      (o_axis_out_tvalid    ),
  .i_axis_tready      (i_axis_out_tready    ),
  .o_axis_tlast       (o_axis_out_tlast     )
);


//asynchronous logic

assign w_axi_rst                      = INVERT_AXI_RESET  ? ~i_axi_rst    : i_axi_rst;
assign w_axis_rst                     = INVERT_AXIS_RESET ? ~i_axis_rst   : i_axis_rst;
assign w_version[`MAJOR_RANGE]        = `MAJOR_VERSION;
assign w_version[`MINOR_RANGE]        = `MINOR_VERSION;
assign w_version[`REVISION_RANGE]     = `REVISION;
assign w_version[`VERSION_PAD_RANGE]  = 0;


//synchronous logic
always @ (posedge i_axi_clk) begin
  //De-assert Strobes
  r_reg_in_ack_stb                        <=  0;
  r_reg_out_rdy_stb                       <=  0;
  r_reg_invalid_addr                      <=  0;

  if (w_axi_rst) begin
    r_reg_out_data                        <=  0;

    //Reset the temporary Data
    r_control                             <=  0;
  end
  else begin

    if (w_reg_in_rdy) begin
      //From master
      case (w_reg_address)
        REG_CONTROL: begin
          //$display("Incomming data on address: 0x%h: 0x%h", w_reg_address, w_reg_in_data);
          r_control                       <=  w_reg_in_data;
        end
        REG_VERSION: begin
          //$display("Incomming data on address: 0x%h: 0x%h", w_reg_address, w_reg_in_data);
        end
        default: begin
          $display ("Unknown address: 0x%h", w_reg_address);
          //Tell the host they wrote to an invalid address
          r_reg_invalid_addr              <= 1;
        end
      endcase
      //Tell the AXI Slave Control we're done with the data
      r_reg_in_ack_stb                    <= 1;
    end
    else if (w_reg_out_req) begin
      //To master
      //$display("User is reading from address 0x%0h", w_reg_address);
      case (w_reg_address)
        REG_CONTROL: begin
          r_reg_out_data                  <= r_control;
        end
        REG_VERSION: begin
          r_reg_out_data                  <= w_version;
        end
        default: begin
          //Unknown address
          r_reg_out_data                  <= 32'h00;
          r_reg_invalid_addr              <= 1;
        end
      endcase
      //Tell the AXI Slave to send back this packet
      r_reg_out_rdy_stb                   <= 1;
    end
  end
end



//AXIS OUT State


endmodule
