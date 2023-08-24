`timescale 1ns/1ps


module tb_axi_lite_slave #(
  parameter ADDR_WIDTH          = 32
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
output      [31: 0]                 aximl_rdata

);


//Local Parameters
//Registers

reg               r_rst;
reg [7:0] 	      test_id         = 0;

//Workaround for weird icarus simulator bug
always @ (*)      r_rst           = rst;

//submodules
demo_part2 #(
  .ADDR_WIDTH       (ADDR_WIDTH     ),
  .INVERT_AXI_RESET (0              )
) dut (
  .i_axi_clk        (clk            ),
  .i_axi_rst        (r_rst          ),


  .i_awvalid        (aximl_awvalid  ),
  .i_awaddr         (aximl_awaddr   ),
  .o_awready        (aximl_awready  ),


  .i_wvalid         (aximl_wvalid   ),
  .o_wready         (aximl_wready   ),
  .i_wdata          (aximl_wdata    ),
  .i_wstrb          (aximl_wstrb    ),


  .o_bvalid         (aximl_bvalid   ),
  .i_bready         (aximl_bready   ),
  .o_bresp          (aximl_bresp    ),


  .i_arvalid        (aximl_arvalid  ),
  .o_arready        (aximl_arready  ),
  .i_araddr         (aximl_araddr   ),


  .o_rvalid         (aximl_rvalid   ),
  .i_rready         (aximl_rready   ),
  .o_rresp          (aximl_rresp    ),
  .o_rdata          (aximl_rdata    )

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
