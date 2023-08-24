/*
 * Author: Dave McCoy
 * Description: AXI Master
 *
 * Changes:
 *
 * Notes:
 *  - The user must be aware of the ID, the response will align with the ID, for multiple transactions the user will need to manage the IDs because this core cannot know the significance of each ID
 *  - Select an ID to read/write data on
 *    - If writing we need to lock onto an ID until the user has sent both
 *      control data as well as data
 *        - We can release the ID when we receive a write response
 *    - If reading all we need to to is send the control data
 *        - We can release the ID when we receive a read response, need to verify that the read response status is last
 */


`timescale 1ns / 1ns

`define SIZE_MAX(x) \
  (x == 8)    ? 0 : \
  (x == 16)   ? 1 : \
  (x == 32)   ? 2 : \
  (x == 64)   ? 3 : \
  (x == 128)  ? 4 : \
  (x == 256)  ? 5 : \
  (x == 512)  ? 6 : \
  (x == 1024) ? 7 : 0

module axi_master #
(
    parameter DATA_WIDTH        = 32,
    parameter ADDR_WIDTH        = 32,
    parameter STRB_WIDTH        = (DATA_WIDTH/8),
    parameter ID_WIDTH          = 4,
    parameter INVERT_AXI_RESET  = 1
)
(
    input                         i_axi_clk,
    input                         i_axi_rst,

    /*************************************************************************
    * User Interface
    *************************************************************************/
    output                        o_ready,
    output reg [ID_WIDTH-1:0]     o_resp_id,
    //If a trollie user strobes both at a time we need to handle this condition :(
    input                         i_start_read_stb,
    input                         i_start_write_stb,

    input  [ID_WIDTH-1:0]         i_id,
    input  [ADDR_WIDTH - 1:0]     i_addr,
    input  [7:0]                  i_data_len,
    input                         i_en_strb,


    input  [DATA_WIDTH-1:0]       usr_w_tdata,
    input  [STRB_WIDTH-1:0]       usr_w_tstrb,
    input                         usr_w_tlast,
    input                         usr_w_tvalid,
    output                        usr_w_tready,

    output [DATA_WIDTH-1:0]       usr_r_tdata,
    output                        usr_r_tlast,
    output                        usr_r_tvalid,
    input                         usr_r_tready,

    /*************************************************************************
    * AXI Master Interface
    *************************************************************************/
    output      [ADDR_WIDTH-1:0]  axi_awaddr,
    output  reg [ID_WIDTH-1: 0]   axi_awid,
    output      [7:0]             axi_awlen,  //Length of transaction (plus 1) so a value of 0x00 would be one transaction
    output      [2:0]             axi_awsize,   //Maximum number of bytes per transfer 0x00 = 1 byte, 0x01: 2 bytes 0x02: 4...
    output      [1:0]             axi_awburst,
    output  reg                   axi_awvalid,
    input                         axi_awready,

    output      [DATA_WIDTH-1:0]  axi_wdata,
    output  reg [ID_WIDTH-1: 0]   axi_wid,
    output      [STRB_WIDTH-1:0]  axi_wstrb,
    output                        axi_wlast,
    output                        axi_wvalid,
    input                         axi_wready,

    input       [1:0]             axi_bresp,
    input       [ID_WIDTH-1: 0]   axi_bid,
    input                         axi_bvalid,
    output  reg                   axi_bready,

    output      [ADDR_WIDTH-1:0]  axi_araddr,
    output  reg [ID_WIDTH-1: 0]   axi_arid,
    output      [7:0]             axi_arlen,
    output      [2:0]             axi_arsize, //Related to beats ??
    output      [1:0]             axi_arburst,
    output  reg                   axi_arvalid,
    input                         axi_arready,

    input       [DATA_WIDTH-1:0]  axi_rdata,
    input       [ID_WIDTH-1: 0]   axi_rid,
    input                         axi_rlast,
    input                         axi_rvalid,
    input       [1:0]             axi_rresp,
    output                        axi_rready
);

//Local Parameters
localparam  S_IDLE              = 0;

localparam  S_RD_READY          = 1;
localparam  S_RD_WAIT_FOR_DATA  = 2;

localparam  S_WR_READY          = 3;
localparam  S_WR_WAIT_RESP      = 4;
//Registers/Wires

reg     [3:0]                   state;
wire                            w_axi_rst;



//Submodules
//Assignments

assign w_axi_rst                  = INVERT_AXI_RESET ? ~i_axi_rst : i_axi_rst;
assign o_ready                    = (state == S_IDLE);

assign axi_awsize                 = `SIZE_MAX(DATA_WIDTH);
assign axi_arsize                 = `SIZE_MAX(DATA_WIDTH);

assign axi_awaddr                 = i_addr;
assign axi_araddr                 = i_addr;

assign axi_awlen                  = i_data_len;
assign axi_arlen                  = i_data_len;

assign axi_awburst                = 2'b01;  //Incrementing address only supported right now
assign axi_arburst                = 2'b01;  //Incrementing address only supported right now


assign usr_r_tdata                = axi_rdata;
assign usr_r_tlast                = axi_rlast;
assign usr_r_tvalid               = axi_rvalid;
assign axi_rready                 = usr_r_tready;

assign axi_wdata                  = usr_w_tdata;
assign axi_wstrb                  = i_en_strb ? usr_w_tstrb : ((1 << STRB_WIDTH) - 1);
assign axi_wlast                  = usr_w_tlast;
assign axi_wvalid                 = usr_w_tvalid;
assign usr_w_tready               = axi_wready;


//Processes
always @ (posedge i_axi_clk) begin
  if (w_axi_rst) begin
    state             <=  S_IDLE;
    axi_awid          <=  0;
    axi_wid           <=  0;
    axi_arid          <=  0;
    o_resp_id         <=  0;
    axi_awvalid       <=  0;
    axi_arvalid       <=  0;
    axi_bready        <=  0;

  end
  else begin
    case (state)
      S_IDLE: begin
        axi_awvalid   <=  0;
        axi_arvalid   <=  0;
        axi_bready    <=  0;
        if (i_start_read_stb) begin
          axi_arid    <=  i_id;
          state       <=  S_RD_READY;
        end
        else if (i_start_write_stb) begin
          axi_awid    <=  i_id;
          axi_wid     <=  i_id;
          state       <=  S_WR_READY;
        end
      end
      S_RD_READY: begin
        axi_arvalid   <=  1;
        if (axi_arvalid & axi_arready) begin
          state       <=  S_RD_WAIT_FOR_DATA;
          axi_arvalid <=  0;
        end
      end
      S_RD_WAIT_FOR_DATA: begin
        //XXX: Check if I need to worry about beats ??
        if (axi_rlast) begin
          state       <=  S_IDLE;
          o_resp_id   <=  axi_rid;
        end
      end
      S_WR_READY: begin
        axi_awvalid   <=  1;
        if (axi_awvalid & axi_awready) begin
          state       <=  S_WR_WAIT_RESP;
          axi_awvalid <=  0;
        end
      end
      S_WR_WAIT_RESP: begin
        axi_bready    <=  1;
        if (axi_bvalid & axi_bready) begin
          state       <=  S_IDLE;
          o_resp_id   <=  axi_bid;
          axi_bready  <=  0;
        end
      end
      default: begin
        state         <=  S_IDLE;
      end
    endcase
  end
end


endmodule
