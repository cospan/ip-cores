`timescale 1ns/1ps


module tb_axi_lite_slave #(
  parameter AXIS_DATA_WIDTH     = 8,
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
output      [31: 0]                 aximl_rdata,

input                               axis_in_tuser,
input                               axis_in_tvalid,
output                              axis_in_tready,
input                               axis_in_tlast,
input       [AXIS_DATA_WIDTH - 1:0] axis_in_tdata
);


//Local Parameters
//Registers

reg               r_rst;
reg [7:0] 	      test_id         = 0;

wire                             axis_tuser;
wire                             axis_tvalid;
wire                             axis_tready;
wire                             axis_tlast;
wire   [AXIS_DATA_WIDTH - 1:0]   axis_tdata;



//Workaround for weird icarus simulator bug
always @ (*)      r_rst           = rst;

//submodules
fps_counter #(
  .ADDR_WIDTH       (ADDR_WIDTH        ),
  .INVERT_AXI_RESET (0                 )
) dut (
  .i_axi_clk        (clk               ),
  .i_axi_rst        (r_rst             ),


  .i_awvalid        (aximl_awvalid     ),
  .i_awaddr         (aximl_awaddr      ),
  .o_awready        (aximl_awready     ),


  .i_wvalid         (aximl_wvalid      ),
  .o_wready         (aximl_wready      ),
  .i_wdata          (aximl_wdata       ),
  .i_wstrb          (aximl_wstrb       ),


  .o_bvalid         (aximl_bvalid      ),
  .i_bready         (aximl_bready      ),
  .o_bresp          (aximl_bresp       ),


  .i_arvalid        (aximl_arvalid     ),
  .o_arready        (aximl_arready     ),
  .i_araddr         (aximl_araddr      ),


  .o_rvalid         (aximl_rvalid      ),
  .i_rready         (aximl_rready      ),
  .o_rresp          (aximl_rresp       ),
  .o_rdata          (aximl_rdata       ),

  //Input AXI Stream
  .i_axis_in_tuser  (axis_in_tuser     ),
  .i_axis_in_tvalid (axis_in_tvalid    ),
  .i_axis_in_tready (axis_in_tready    ),
  .i_axis_in_tlast  (axis_in_tlast     ),
  .i_axis_in_tdata  (axis_in_tdata     )
);

//asynchronus logic
assign axis_in_tready = 1'b1;
//synchronous logic

`ifndef VERILATOR // traced differently
  initial begin
    $dumpfile ("design.vcd");
    $dumpvars(0, tb_axi_lite_slave);
  end
`endif

endmodule
