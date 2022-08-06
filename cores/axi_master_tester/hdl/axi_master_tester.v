
/*
 Your license here
 */

/*
 * Author:
 * Description:
 *
 * Changes:
 */

`timescale 1ps / 1ps

`define BIT_CTRL_READ_START       0
`define BIT_CTRL_WRITE_START      1
`define BIT_CTRL_EN_STRB          2
`define BIT_STS_READY             0

`define BITRANGE_ID_HIGH      31
`define BITRANGE_ID_LOW       16

`define BITRANGE_ID           `BITRANGE_ID_HIGH:`BITRANGE_ID_LOW

`define MAJOR_VERSION             1
`define MINOR_VERSION             0
`define REVISION                  0

`define MAJOR_RANGE               31:28
`define MINOR_RANGE               27:20
`define REVISION_RANGE            19:16
`define VERSION_PAD_RANGE         15:0

module axi_master_tester #(

  parameter MSTR_ADDR_WIDTH     = 32,
  parameter MSTR_DATA_WIDTH     = 32,
  parameter MSTR_STRB_WIDTH     = (MSTR_DATA_WIDTH >> 3),
  parameter MSTR_ID_WIDTH       = 4,

  parameter ADDR_WIDTH          = 16,
  parameter INVERT_AXI_RESET    = 1



)(
  input                               i_axi_clk,
  input                               i_axi_rst,

  //Write Address Channel
  input                               i_awvalid,
  input       [ADDR_WIDTH-1: 0]       i_awaddr,
  output                              o_awready,

  //Write Data Channel
  input                               i_wvalid,
  output                              o_wready,
  input       [31: 0]                 i_wdata,
  input       [3:0]                   i_wstrb,

  //Write Response Channel
  output                              o_bvalid,
  input                               i_bready,
  output      [1:0]                   o_bresp,

  //Read Address Channel
  input                               i_arvalid,
  output                              o_arready,
  input       [ADDR_WIDTH-1: 0]       i_araddr,

  //Read Data Channel
  output                              o_rvalid,
  input                               i_rready,
  output      [1:0]                   o_rresp,
  output      [31: 0]                 o_rdata,

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
  output      [MSTR_ADDR_WIDTH-1:0]   axi_awaddr,
  output      [MSTR_ID_WIDTH-1: 0]    axi_awid,
  output      [7:0]                   axi_awlen,
  output      [2:0]                   axi_awsize,
  output      [1:0]                   axi_awburst,
  output  reg                         axi_awvalid,
  input                               axi_awready,

  output      [MSTR_DATA_WIDTH-1:0]   axi_wdata,
  output      [MSTR_ID_WIDTH-1: 0]    axi_wid,
  output      [MSTR_STRB_WIDTH-1:0]   axi_wstrb,
  output                              axi_wlast,
  output                              axi_wvalid,
  input                               axi_wready,

  input       [1:0]                   axi_bresp,
  input       [MSTR_ID_WIDTH-1: 0]    axi_bid,
  output  reg                         axi_bvalid,
  input                               axi_bready,

  output      [MSTR_ADDR_WIDTH-1:0]   axi_araddr,
  output      [MSTR_ID_WIDTH-1: 0]    axi_arid,
  output      [7:0]                   axi_arlen,
  output      [2:0]                   axi_arsize,
  output      [1:0]                   axi_arburst,
  output  reg                         axi_arvalid,
  input                               axi_arready,

  output      [MSTR_DATA_WIDTH-1:0]   axi_rdata,
  input       [MSTR_ID_WIDTH-1: 0]    axi_rid,
  output                              axi_rlast,
  output                              axi_rvalid,
  input       [1:0]                   axi_rresp,
  input                               axi_rready

);
//local parameters

//Address Map
localparam  REG_CONTROL       = 0 << 2;
localparam  REG_STATUS        = 1 << 2;
localparam  REG_ADDR          = 2 << 2;
localparam  REG_DATA_LEN      = 3 << 2;
localparam  REG_VERSION       = 4 << 2;

localparam  MAX_ADDR          = REG_VERSION;

//localparam  ID_FILL           = ((1 << ((`BITRANGE_ID_HIGH - `BITRANGE_ID_LOW) - MSTR_ID_WIDTH)) - 1);

//registers/wires

//User Interface
wire                        w_axi_rst;
wire  [ADDR_WIDTH-1: 0]     w_reg_address;
reg                         r_reg_invalid_addr;

wire                        w_reg_in_rdy;
reg                         r_reg_in_ack;
wire  [31: 0]               w_reg_in_data;

wire                        w_reg_out_req;
reg                         r_reg_out_rdy;
reg   [31: 0]               r_reg_out_data;


//TEMP DATA, JUST FOR THE DEMO
wire  [31: 0]               w_version;

wire                        w_master_ready;
wire  [MSTR_ID_WIDTH - 1:0] w_resp_id;
reg   [MSTR_ID_WIDTH - 1:0] r_usr_id;
reg   [MSTR_ADDR_WIDTH - 1: 0] r_address;
reg   [7:0]                 r_data_len;
reg                         r_start_write_stb;
reg                         r_start_read_stb;
reg                         r_en_strb;


//submodules

//Convert AXI Slave bus to a simple register/address strobe
axi_lite_slave #(
  .ADDR_WIDTH         (ADDR_WIDTH           )
) axi_lite_reg_interface (
  .clk                (i_axi_clk            ),
  .rst                (w_axi_rst            ),


  .i_awvalid          (i_awvalid            ),
  .i_awaddr           (i_awaddr             ),
  .o_awready          (o_awready            ),

  .i_wvalid           (i_wvalid             ),
  .o_wready           (o_wready             ),
  .i_wdata            (i_wdata              ),
  .i_wstrb            (i_wstrb              ),

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


axi_master #(
  .DATA_WIDTH       (MSTR_DATA_WIDTH ),
  .ADDR_WIDTH       (MSTR_ADDR_WIDTH ),
  .STRB_WIDTH       (MSTR_STRB_WIDTH ),
  .ID_WIDTH         (MSTR_ID_WIDTH   ),
  .INVERT_AXI_RESET (INVERT_AXI_RESET)
) am (
  .i_axi_clk        (i_axi_clk      ),
  .i_axi_rst        (i_axi_rst      ),

  /*************************************************************************
  * User Interface
  *************************************************************************/
  .o_ready          (w_master_ready ),
  .o_resp_id        (w_resp_id      ),
  //If a trollie user strobes both at a time we need to handle this condition :(
  .i_id             (r_usr_id       ),
  .i_start_read_stb (r_start_read_stb),
  .i_start_write_stb(r_start_write_stb),
  .i_en_strb        (r_en_strb      ),

  .i_addr           (r_address      ),
  .i_data_len       (r_data_len     ),

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
  .axi_awaddr       (axi_awaddr     ),
  .axi_awid         (axi_awid       ),
  .axi_awlen        (axi_awlen      ),
  .axi_awsize       (axi_awsize     ),
  .axi_awburst      (axi_awburst    ),
  .axi_awvalid      (axi_awvalid    ),
  .axi_awready      (axi_awready    ),

  .axi_wdata        (axi_wdata      ),
  .axi_wid          (axi_wid        ),
  .axi_wstrb        (axi_wstrb      ),
  .axi_wlast        (axi_wlast      ),
  .axi_wvalid       (axi_wvalid     ),
  .axi_wready       (axi_wready     ),

  .axi_bresp        (axi_bresp      ),
  .axi_bid          (axi_bid        ),
  .axi_bvalid       (axi_bvalid     ),
  .axi_bready       (axi_bready     ),

  .axi_araddr       (axi_araddr     ),
  .axi_arid         (axi_arid       ),
  .axi_arlen        (axi_arlen      ),
  .axi_arsize       (axi_arsize     ),
  .axi_arburst      (axi_arburst    ),
  .axi_arvalid      (axi_arvalid    ),
  .axi_arready      (axi_arready    ),

  .axi_rdata        (axi_rdata      ),
  .axi_rid          (axi_rid        ),
  .axi_rlast        (axi_rlast      ),
  .axi_rvalid       (axi_rvalid     ),
  .axi_rresp        (axi_rresp      ),
  .axi_rready       (axi_rready     )
);

//asynchronous logic

assign w_axi_rst                      = INVERT_AXI_RESET ? ~i_axi_rst : i_axi_rst;
assign w_version[`MAJOR_RANGE]        = `MAJOR_VERSION;
assign w_version[`MINOR_RANGE]        = `MINOR_VERSION;
assign w_version[`REVISION_RANGE]     = `REVISION;
assign w_version[`VERSION_PAD_RANGE]  = 0;


//synchronous logic
always @ (posedge i_axi_clk) begin
  //De-assert
  r_reg_in_ack                            <=  0;
  r_reg_out_rdy                           <=  0;
  r_reg_invalid_addr                      <=  0;
  r_start_read_stb                        <=  0;
  r_start_write_stb                       <=  0;

  if (w_axi_rst) begin
    r_reg_out_data                        <=  0;

    //Reset the temporary Data
    r_address                             <=  0;
    r_data_len                            <=  0;
    r_usr_id                              <=  0;
    r_en_strb                             <=  0;
  end
  else begin

    if (w_reg_in_rdy) begin
      //From master
      case (w_reg_address)
        REG_CONTROL: begin
          //$display("Incoming data on address: 0x%h: 0x%h", w_reg_address, w_reg_in_data);
          r_start_read_stb                <=  w_reg_in_data[`BIT_CTRL_READ_START];
          r_start_write_stb               <=  w_reg_in_data[`BIT_CTRL_WRITE_START];
          r_en_strb                       <=  w_reg_in_data[`BIT_CTRL_EN_STRB];

          r_usr_id                        <=  w_reg_in_data[`BITRANGE_ID];
        end
        REG_STATUS: begin
        end
        REG_ADDR: begin
          r_address                       <=  w_reg_in_data[MSTR_ADDR_WIDTH - 1:0];
        end
        REG_DATA_LEN: begin
          r_data_len                      <= (w_reg_in_data[8:0] > 0) ? (w_reg_in_data[8:0] - 1) : 0;
        end
        REG_VERSION: begin
          //$display("Incoming data on address: 0x%h: 0x%h", w_reg_address, w_reg_in_data);
        end
        default: begin
          $display ("Unknown address: 0x%h", w_reg_address);
          //Tell the host they wrote to an invalid address
          r_reg_invalid_addr              <= 1;
        end
      endcase
      //Tell the AXI Slave Control we're done with the data
      r_reg_in_ack                        <= 1;
    end
    else if (w_reg_out_req) begin
      //To master
      //$display("User is reading from address 0x%0h", w_reg_address);
      case (w_reg_address)
        REG_CONTROL: begin
          r_reg_out_data                  <=  0;
          //r_reg_out_data[`BITRANGE_ID]    <= {(`BITRANGE_ID - MSTR_ID_WIDTH), r_usr_id};
          r_reg_out_data[`BITRANGE_ID]    <= r_usr_id;
          r_reg_out_data[`BIT_CTRL_EN_STRB] <= r_en_strb;

        end
        REG_STATUS: begin
//XXX: Add status
          r_reg_out_data                  <= 0;
          r_reg_out_data[`BIT_STS_READY]  <= w_master_ready;
          r_reg_out_data[`BITRANGE_ID]    <= w_resp_id;
        end
        REG_ADDR: begin
          r_reg_out_data                  <= 0;
          r_reg_out_data                  <= r_address;
        end
        REG_DATA_LEN: begin
          r_reg_out_data                  <= 0;
          r_reg_out_data[8:0]             <= (r_data_len + 1);
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
      r_reg_out_rdy                       <= 1;
    end
  end
end

endmodule
