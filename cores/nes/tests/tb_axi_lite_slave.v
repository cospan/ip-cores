`timescale 1ns/1ps


module tb_axi_lite_slave #(
  parameter AM_DATA_WIDTH       = 8,
  parameter AM_ADDR_WIDTH       = 32,
  parameter AM_STRB_WIDTH       = (AM_DATA_WIDTH/8),
  parameter AM_ID_WIDTH         = 4,


  parameter ADDR_WIDTH          = 32
)(

input                               clk,
input                               rst,


input                               nes_clk,
input                               ppu_clk,
input                               apu_clk,

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

/*************************************************************************
* AXI Master Interface
*************************************************************************/
output            [AM_ADDR_WIDTH-1:0] axi_slave_awaddr,
output            [AM_ID_WIDTH-1: 0]  axi_slave_awid,
output            [7:0]               axi_slave_awlen,  //Length of transaction (plus 1) so a value of 0x00 would be one transaction
output            [2:0]               axi_slave_awsize,   //Maximum number of bytes per transfer 0x00 = 1 byte, 0x01: 2 bytes 0x02: 4...
output            [1:0]               axi_slave_awburst,
output                                axi_slave_awvalid,
input                                 axi_slave_awready,

output            [AM_DATA_WIDTH-1:0] axi_slave_wdata,
output            [AM_ID_WIDTH-1: 0]  axi_slave_wid,
output            [AM_STRB_WIDTH-1:0] axi_slave_wstrb,
output                                axi_slave_wlast,
output                                axi_slave_wvalid,
input                                 axi_slave_wready,

input             [1:0]               axi_slave_bresp,
input             [AM_ID_WIDTH-1: 0]  axi_slave_bid,
input                                 axi_slave_bvalid,
output                                axi_slave_bready,

output            [AM_ADDR_WIDTH-1:0] axi_slave_araddr,
output            [AM_ID_WIDTH-1: 0]  axi_slave_arid,
output            [7:0]               axi_slave_arlen,
output            [2:0]               axi_slave_arsize, //Related to beats ??
output            [1:0]               axi_slave_arburst,
output                                axi_slave_arvalid,
input                                 axi_slave_arready,

input             [AM_DATA_WIDTH-1:0] axi_slave_rdata,
input             [AM_ID_WIDTH-1: 0]  axi_slave_rid,
input                                 axi_slave_rlast,
input                                 axi_slave_rvalid,
input             [1:0]               axi_slave_rresp,
output                                axi_slave_rready

);


//Local Parameters
//Registers

reg               r_rst;
reg [7:0] 	      test_id         = 0;

//Workaround for weird icarus simulator bug
always @ (*)      r_rst           = rst;

//submodules
axi_nes #(
  .ADDR_WIDTH       (ADDR_WIDTH           ),
  .INVERT_AXI_RESET (0                    )
) dut (
  .i_axi_clk        (clk                  ),
  .i_axi_rst        (r_rst                ),

  .nes_clk          (nes_clk              ),
  .ppu_clk          (ppu_clk              ),
  .apu_clk          (apu_clk              ),


  .i_awvalid        (aximl_awvalid        ),
  .i_awaddr         (aximl_awaddr         ),
  .o_awready        (aximl_awready        ),


  .i_wvalid         (aximl_wvalid         ),
  .o_wready         (aximl_wready         ),
  .i_wdata          (aximl_wdata          ),
  .i_wstrb          (aximl_wstrb          ),


  .o_bvalid         (aximl_bvalid         ),
  .i_bready         (aximl_bready         ),
  .o_bresp          (aximl_bresp          ),


  .i_arvalid        (aximl_arvalid        ),
  .o_arready        (aximl_arready        ),
  .i_araddr         (aximl_araddr         ),


  .o_rvalid         (aximl_rvalid         ),
  .i_rready         (aximl_rready         ),
  .o_rresp          (aximl_rresp          ),
  .o_rdata          (aximl_rdata          ),


  /*************************************************************************
  * AXI Master Interface
  *************************************************************************/
  .axim_awaddr      (axi_slave_awaddr     ),
  .axim_awid        (axi_slave_awid       ),
  .axim_awlen       (axi_slave_awlen      ),
  .axim_awsize      (axi_slave_awsize     ),
  .axim_awburst     (axi_slave_awburst    ),
  .axim_awvalid     (axi_slave_awvalid    ),
  .axim_awready     (axi_slave_awready    ),

  .axim_wdata       (axi_slave_wdata      ),
  .axim_wid         (axi_slave_wid        ),
  .axim_wstrb       (axi_slave_wstrb      ),
  .axim_wlast       (axi_slave_wlast      ),
  .axim_wvalid      (axi_slave_wvalid     ),
  .axim_wready      (axi_slave_wready     ),

  .axim_bresp       (axi_slave_bresp      ),
  .axim_bid         (axi_slave_bid        ),
  .axim_bvalid      (axi_slave_bvalid     ),
  .axim_bready      (axi_slave_bready     ),

  .axim_araddr      (axi_slave_araddr     ),
  .axim_arid        (axi_slave_arid       ),
  .axim_arlen       (axi_slave_arlen      ),
  .axim_arsize      (axi_slave_arsize     ),
  .axim_arburst     (axi_slave_arburst    ),
  .axim_arvalid     (axi_slave_arvalid    ),
  .axim_arready     (axi_slave_arready    ),

  .axim_rdata       (axi_slave_rdata      ),
  .axim_rid         (axi_slave_rid        ),
  .axim_rlast       (axi_slave_rlast      ),
  .axim_rvalid      (axi_slave_rvalid     ),
  .axim_rresp       (axi_slave_rresp      ),
  .axim_rready      (axi_slave_rready     )




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
