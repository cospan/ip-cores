`timescale 1ns/1ps

//`define TEST_IMAGE_SIZE


`define DEF_FONT_WIDTH  5
`define DEF_FONT_HEIGHT 7



`ifdef TEST_IMAGE_SIZE
`define DEF_IMAGE_WIDTH     (`DEF_FONT_WIDTH + 1) * 4
`define DEF_IMAGE_HEIGHT    (`DEF_FONT_HEIGHT + 1) * 2
`define DEF_CONSOLE_DEPTH   7
`else
`define DEF_IMAGE_WIDTH     32
`define DEF_IMAGE_HEIGHT    16
`define DEF_CONSOLE_DEPTH   8
`endif


module tb_axi_lite_slave #(
  parameter AXIS_WIDTH          = 32,
  parameter FONT_WIDTH          = `DEF_FONT_WIDTH,
  parameter FONT_HEIGHT         = `DEF_FONT_HEIGHT,
  parameter FONT_FILE           = "../hdl/fontdata.mif",
  parameter IMAGE_WIDTH         = `DEF_IMAGE_WIDTH,
  parameter IMAGE_HEIGHT        = `DEF_IMAGE_HEIGHT,
  parameter CONSOLE_DEPTH       = `DEF_CONSOLE_DEPTH,
  parameter ADDR_WIDTH          = 16,
  parameter INVERT_AXIS_RESET   = 0,
  parameter INVERT_AXI_RESET    = 0
)(

input                               clk,
input                               rst,

//Write Address Channel
input                               aximl_awvalid,
input       [ADDR_WIDTH - 1: 0]     aximl_awaddr,
output                              aximl_awready,

//Write Data Channel
input                               aximl_wvalid,
output                              aximl_wready,
input       [31: 0]                 aximl_wdata,
input       [3: 0]                  aximl_wstrb,

//Write Response Channel
output                              aximl_bvalid,
input                               aximl_bready,
output      [1:0]                   aximl_bresp,

//Read Address Channel
input                               aximl_arvalid,
output                              aximl_arready,
input       [ADDR_WIDTH - 1: 0]     aximl_araddr,

//Read Data Channel
output                              aximl_rvalid,
input                               aximl_rready,
output      [1:0]                   aximl_rresp,
output      [31: 0]                 aximl_rdata,

//AXIS IN Stream
input                               axis_clk,
input                               axis_rst,


input                               axis_out_tuser,
input                               axis_out_tvalid,
output                              axis_out_tready,
input                               axis_out_tlast,
input       [AXIS_WIDTH - 1:0]      axis_out_tdata
);


//Local Parameters
//Registers

reg                                 r_rst;
reg                                 r_axis_rst;
reg [7:0] 	                        test_id         = 0;

//Workaround for weird icarus simulator bug
always @ (*)      r_rst           = rst;
always @ (*)      r_axis_rst      = axis_rst;

localparam INTERVAL = IMAGE_WIDTH * IMAGE_HEIGHT;
//localparam INTERVAL = 10;

//submodules
axi_terminal #(
  .ADDR_WIDTH       (ADDR_WIDTH             ),
  .AXIS_WIDTH       (AXIS_WIDTH             ),
  .CONSOLE_DEPTH    (CONSOLE_DEPTH          ),
  .IMAGE_WIDTH      (IMAGE_WIDTH            ),
  .IMAGE_HEIGHT     (IMAGE_HEIGHT           ),
  .DEFAULT_INTERVAL (INTERVAL               ),
  .FONT_WIDTH       (FONT_WIDTH             ),
  .FONT_HEIGHT      (FONT_HEIGHT            ),
  .FONT_FILE        (FONT_FILE              ),
  .INVERT_AXI_RESET (INVERT_AXI_RESET       ),
  .INVERT_AXIS_RESET(INVERT_AXIS_RESET      )
) dut (
  .i_axi_clk        (clk                    ),
  .i_axi_rst        (r_rst                  ),


  .i_awvalid        (aximl_awvalid          ),
  .i_awaddr         (aximl_awaddr           ),
  .o_awready        (aximl_awready          ),


  .i_wvalid         (aximl_wvalid           ),
  .o_wready         (aximl_wready           ),
  .i_wdata          (aximl_wdata            ),
  .i_wstrb          (aximl_wstrb            ),


  .o_bvalid         (aximl_bvalid           ),
  .i_bready         (aximl_bready           ),
  .o_bresp          (aximl_bresp            ),


  .i_arvalid        (aximl_arvalid          ),
  .o_arready        (aximl_arready          ),
  .i_araddr         (aximl_araddr           ),


  .o_rvalid         (aximl_rvalid           ),
  .i_rready         (aximl_rready           ),
  .o_rresp          (aximl_rresp            ),
  .o_rdata          (aximl_rdata            ),


  //Output AXI Stream
  .i_axis_clk       (axis_clk               ),
  .i_axis_rst       (r_axis_rst             ),


  .o_axis_out_tuser (axis_out_tuser         ),
  .o_axis_out_tvalid(axis_out_tvalid        ),
  .i_axis_out_tready(axis_out_tready        ),
  .o_axis_out_tlast (axis_out_tlast         ),
  .o_axis_out_tdata (axis_out_tdata         )

);

//asynchronus logic
//synchronous logic

`ifndef VERILATOR // traced differently
  initial begin
    $dumpfile ("design.vcd");
    $dumpvars(0, tb_axi_lite_slave);
  end
`endif

endmodule
