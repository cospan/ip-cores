`timescale 1ns/1ps


module tb_axi_lite_slave #(
  parameter ADDR_WIDTH          = 32,
  parameter MSTR_ADDR_WIDTH     = 8,
  parameter MSTR_DATA_WIDTH     = 32,
  parameter MSTR_STRB_WIDTH     = (MSTR_DATA_WIDTH >> 3),
  parameter MSTR_ID_WIDTH       = 4
)(

input                               clk,
input                               rst,

//Write Address Channel
input                               aximl_awvalid,
input       [ADDR_WIDTH-1: 0]       aximl_awaddr,
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
input       [ADDR_WIDTH-1: 0]       aximl_araddr,

//Read Data Channel
output                              aximl_rvalid,
input                               aximl_rready,
output      [1:0]                   aximl_rresp,
output      [31: 0]                 aximl_rdata,


/*************************************************************************
* User Write Interface
*************************************************************************/
input       [MSTR_DATA_WIDTH-1:0]   usr_w_tdata,
input       [MSTR_STRB_WIDTH-1:0]   usr_w_tstrb,
input                               usr_w_tlast,
input                               usr_w_tvalid,
output                              usr_w_tready,

/*************************************************************************
* User Read Interface
*************************************************************************/
output      [MSTR_DATA_WIDTH-1:0]   usr_r_tdata,
output                              usr_r_tlast,
output                              usr_r_tvalid,
input                               usr_r_tready,



/*************************************************************************
* AXI Master Interface
*************************************************************************/
output      [MSTR_ADDR_WIDTH-1:0]   axi_slave_awaddr,
output      [MSTR_ID_WIDTH-1: 0]    axi_slave_awid,
output      [7:0]                   axi_slave_awlen,
output      [2:0]                   axi_slave_awsize,
output      [1:0]                   axi_slave_awburst,
output                              axi_slave_awvalid,
input                               axi_slave_awready,

output      [MSTR_DATA_WIDTH-1:0]   axi_slave_wdata,
output      [MSTR_ID_WIDTH-1: 0]    axi_slave_wid,
output      [MSTR_STRB_WIDTH-1:0]   axi_slave_wstrb,
output                              axi_slave_wlast,
output                              axi_slave_wvalid,
input                               axi_slave_wready,

input       [1:0]                   axi_slave_bresp,
input       [MSTR_ID_WIDTH-1: 0]    axi_slave_bid,
output                              axi_slave_bvalid,
input                               axi_slave_bready,

output      [MSTR_ADDR_WIDTH-1:0]   axi_slave_araddr,
output      [MSTR_ID_WIDTH-1: 0]    axi_slave_arid,
output      [7:0]                   axi_slave_arlen,
output      [2:0]                   axi_slave_arsize,
output      [1:0]                   axi_slave_arburst,
output                              axi_slave_arvalid,
input                               axi_slave_arready,

output      [MSTR_DATA_WIDTH-1:0]   axi_slave_rdata,
input       [MSTR_ID_WIDTH-1: 0]    axi_slave_rid,
output                              axi_slave_rlast,
output                              axi_slave_rvalid,
input       [1:0]                   axi_slave_rresp,
input                               axi_slave_rready


);


//Local Parameters
//Registers

reg               r_rst;
reg [7:0] 	      test_id         = 0;

//Workaround for weird icarus simulator bug
always @ (*)      r_rst           = rst;

//submodules
axi_master_tester #(
  .MSTR_ADDR_WIDTH  (MSTR_ADDR_WIDTH),
  .MSTR_DATA_WIDTH  (MSTR_DATA_WIDTH),
  .MSTR_STRB_WIDTH  (MSTR_STRB_WIDTH),
  .MSTR_ID_WIDTH    (MSTR_ID_WIDTH  ),


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
  .o_rdata          (aximl_rdata    ),

  /*************************************************************************
  * User Write Interface
  *************************************************************************/
  .usr_w_tdata      (usr_w_tdata    ),
  .usr_w_tstrb      (usr_w_tstrb    ),
  .usr_w_tlast      (usr_w_tlast    ),
  .usr_w_tvalid     (usr_w_tvalid   ),
  .usr_w_tready     (usr_w_tready   ),

  /*************************************************************************
  * User Read Interface
  *************************************************************************/
  .usr_r_tdata      (usr_r_tdata    ),
  .usr_r_tlast      (usr_r_tlast    ),
  .usr_r_tvalid     (usr_r_tvalid   ),
  .usr_r_tready     (usr_r_tready   ),


  /*************************************************************************
  * AXI Master Interface
  *************************************************************************/
  .axi_awaddr       (axi_slave_awaddr     ),
  .axi_awid         (axi_slave_awid       ),
  .axi_awlen        (axi_slave_awlen      ),
  .axi_awsize       (axi_slave_awsize     ),
  .axi_awburst      (axi_slave_awburst    ),
  .axi_awvalid      (axi_slave_awvalid    ),
  .axi_awready      (axi_slave_awready    ),

  .axi_wdata        (axi_slave_wdata      ),
  .axi_wid          (axi_slave_wid        ),
  .axi_wstrb        (axi_slave_wstrb      ),
  .axi_wlast        (axi_slave_wlast      ),
  .axi_wvalid       (axi_slave_wvalid     ),
  .axi_wready       (axi_slave_wready     ),

  .axi_bresp        (axi_slave_bresp      ),
  .axi_bid          (axi_slave_bid        ),
  .axi_bvalid       (axi_slave_bvalid     ),
  .axi_bready       (axi_slave_bready     ),

  .axi_araddr       (axi_slave_araddr     ),
  .axi_arid         (axi_slave_arid       ),
  .axi_arlen        (axi_slave_arlen      ),
  .axi_arsize       (axi_slave_arsize     ),
  .axi_arburst      (axi_slave_arburst    ),
  .axi_arvalid      (axi_slave_arvalid    ),
  .axi_arready      (axi_slave_arready    ),

  .axi_rdata        (axi_slave_rdata      ),
  .axi_rid          (axi_slave_rid        ),
  .axi_rlast        (axi_slave_rlast      ),
  .axi_rvalid       (axi_slave_rvalid     ),
  .axi_rresp        (axi_slave_rresp      ),
  .axi_rready       (axi_slave_rready     )
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
