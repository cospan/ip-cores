
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

`define MAJOR_VERSION           1
`define MINOR_VERSION           0
`define REVISION                0

`define MAJOR_RANGE             31:28
`define MINOR_RANGE             27:20
`define REVISION_RANGE          19:16

`define VERSION_PAD_RANGE       15:0

`define DEFAULT_WIDTH           640
`define DEFAULT_HEIGHT          480


`define CTL_BIT_ENABLE          0
`define CTL_BIT_RGBA_FMT        1




//Generate Clocks Externally
//  Video Clock (Frequency ??)
//  Audio Clock (Frequency ??)
//  85 MHz Clock (SDRAM?? Don't need)
//  50 MHz Clock



module axi_nes #(
  parameter ADDR_WIDTH          = 16,
  parameter VIDEO_WIDTH         = 32,

  parameter AM_DATA_WIDTH       = 8,
  parameter AM_ADDR_WIDTH       = 32,
  parameter AM_STRB_WIDTH       = (AM_DATA_WIDTH/8),
  parameter AM_ID_WIDTH         = 4,

  //Local Mem Address Width
  parameter MEM_ADDR_WIDTH      = (15 / AM_DATA_WIDTH / 8),   //32KB

  parameter WIDTH_SIZE          = 12,
  parameter HEIGHT_SIZE         = 12,

  parameter INVERT_AXI_RESET    = 1
)(
  input                               i_axi_clk,
  input                               i_axi_rst,

  input                               nes_clk,
  input                               ppu_clk,
  input                               apu_clk,

  //Write Address Channel
  input                               i_awvalid,
  input       [ADDR_WIDTH - 1: 0]     i_awaddr,
  output                              o_awready,

  //Write Data Channel
  input                               i_wvalid,
  output                              o_wready,
  input       [3:0]                   i_wstrb,
  input       [31: 0]                 i_wdata,

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
  output      [31: 0]                 o_rdata,


  /*************************************************************************
  * AXI Master Interface
  *************************************************************************/
  output            [AM_ADDR_WIDTH-1:0] axim_awaddr,
  output            [AM_ID_WIDTH-1: 0]  axim_awid,
  output            [7:0]               axim_awlen,  //Length of transaction (plus 1) so a value of 0x00 would be one transaction
  output            [2:0]               axim_awsize, //Maximum number of bytes per transfer 0x00 = 1 byte, 0x01: 2 bytes 0x02: 4...
  output            [1:0]               axim_awburst,
  output                                axim_awvalid,
  input                                 axim_awready,

  output            [AM_DATA_WIDTH-1:0] axim_wdata,
  output            [AM_ID_WIDTH-1: 0]  axim_wid,
  output            [AM_STRB_WIDTH-1:0] axim_wstrb,
  output                                axim_wlast,
  output                                axim_wvalid,
  input                                 axim_wready,

  input             [1:0]               axim_bresp,
  input             [AM_ID_WIDTH-1: 0]  axim_bid,
  input                                 axim_bvalid,
  output                                axim_bready,

  output            [AM_ADDR_WIDTH-1:0] axim_araddr,
  output            [AM_ID_WIDTH-1: 0]  axim_arid,
  output            [7:0]               axim_arlen,
  output            [2:0]               axim_arsize, //Related to beats ??
  output            [1:0]               axim_arburst,
  output                                axim_arvalid,
  input                                 axim_arready,

  input             [AM_DATA_WIDTH-1:0] axim_rdata,
  input             [AM_ID_WIDTH-1: 0]  axim_rid,
  input                                 axim_rlast,
  input                                 axim_rvalid,
  input             [1:0]               axim_rresp,
  output                                axim_rready
);
//local parameters

//Address Map
localparam  REG_CONTROL     =  0 << 2;
localparam  REG_STATUS      =  1 << 2;
localparam  REG_VERSION     = 16 << 2;

localparam  MAX_ADDR = REG_VERSION;

//registers/wires

//User Interface
wire                            w_axi_rst;
wire [ADDR_WIDTH - 1: 0]        w_reg_address;
reg                             r_reg_invalid_addr;

wire                            w_reg_in_rdy;
reg                             r_reg_in_ack;
wire [31: 0]                    w_reg_in_data;

wire                            w_reg_out_req;
reg                             r_reg_out_rdy;
reg [31: 0]                     r_reg_out_data;

reg                             nes_reset;


//TEMP DATA, JUST FOR THE DEMO
reg   [31: 0]                   r_control;
wire  [31: 0]                   w_version;


/*************************************************************************
* Memory Interface
*************************************************************************/
reg    [AM_ID_WIDTH-1:0]      am_req_id;
reg    [AM_ADDR_WIDTH - 1:0]  am_req_addr;
reg    [7:0]                  am_req_data_len;
reg                           am_req_en_strb;
reg                           am_read_stb;
reg                           am_write_stb;

wire                          am_ready;
wire   [AM_ID_WIDTH-1:0]      am_resp_id;

wire   [AM_DATA_WIDTH-1:0]    usr_w_tdata;
wire   [AM_STRB_WIDTH-1:0]    usr_w_tstrb;
wire                          usr_w_tlast;
wire                          usr_w_tvalid;
wire                          usr_w_tready;

wire   [AM_DATA_WIDTH-1:0]    usr_r_tdata;
wire                          usr_r_tlast;
wire                          usr_r_tvalid;
wire                          usr_r_tready;



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

axi_master #
(
    .DATA_WIDTH       (AM_DATA_WIDTH        ),
    .ADDR_WIDTH       (AM_ADDR_WIDTH        ),
    .ID_WIDTH         (AM_ID_WIDTH          ),
    .INVERT_AXI_RESET (0                    )
) memory_interface
(
  .i_axi_clk          (i_axi_clk            ),
  .i_axi_rst          (w_axi_rst            ),
  /*************************************************************************
  * User Interface
  *************************************************************************/
  .i_id               (am_req_id            ),
  .i_addr             (am_req_addr          ),
  .i_data_len         (am_req_data_len      ),
  .i_en_strb          (am_req_en_strb       ),
  .i_start_read_stb   (am_read_stb          ),
  .i_start_write_stb  (am_write_stb         ),

  .o_ready            (am_ready             ),
  .o_resp_id          (am_resp_id           ),

  .usr_w_tdata        (usr_w_tdata          ),
  .usr_w_tstrb        (usr_w_tstrb          ),
  .usr_w_tlast        (usr_w_tlast          ),
  .usr_w_tvalid       (usr_w_tvalid         ),
  .usr_w_tready       (usr_w_tready         ),

  .usr_r_tdata        (usr_r_tdata          ),
  .usr_r_tlast        (usr_r_tlast          ),
  .usr_r_tvalid       (usr_r_tvalid         ),
  .usr_r_tready       (usr_r_tready         ),

  /*************************************************************************
  * AXI Master Interface
  *************************************************************************/
  .axi_awaddr         (axim_awaddr          ),
  .axi_awid           (axim_awid            ),
  .axi_awlen          (axim_awlen           ),
  .axi_awsize         (axim_awsize          ),
  .axi_awburst        (axim_awburst         ),
  .axi_awvalid        (axim_awvalid         ),
  .axi_awready        (axim_awready         ),

  .axi_wdata          (axim_wdata           ),
  .axi_wid            (axim_wid             ),
  .axi_wstrb          (axim_wstrb           ),
  .axi_wlast          (axim_wlast           ),
  .axi_wvalid         (axim_wvalid          ),
  .axi_wready         (axim_wready          ),

  .axi_bresp          (axim_bresp           ),
  .axi_bid            (axim_bid             ),
  .axi_bvalid         (axim_bvalid          ),
  .axi_bready         (axim_bready          ),

  .axi_araddr         (axim_araddr          ),
  .axi_arid           (axim_arid            ),
  .axi_arlen          (axim_arlen           ),
  .axi_arsize         (axim_arsize          ),
  .axi_arburst        (axim_arburst         ),
  .axi_arvalid        (axim_arvalid         ),
  .axi_arready        (axim_arready         ),

  .axi_rdata          (axim_rdata           ),
  .axi_rid            (axim_rid             ),
  .axi_rlast          (axim_rlast           ),
  .axi_rvalid         (axim_rvalid          ),
  .axi_rresp          (axim_rresp           ),
  .axi_rready         (axim_rready          )
);


wire                          lma_wen;
wire  [MEM_ADDR_WIDTH - 1:0]  lma_addr;
wire  [AM_DATA_WIDTH - 1:0]   lma_dina;
wire  [AM_DATA_WIDTH - 1:0]   lma_douta;

reg                           lmb_wen;
wire  [MEM_ADDR_WIDTH - 1:0]  lmb_addr;
wire  [AM_DATA_WIDTH - 1:0]   lmb_dina;
wire  [AM_DATA_WIDTH - 1:0]   lmb_douta;

dpb #(
  .DATA_WIDTH         (AM_DATA_WIDTH        ),
  .ADDR_WIDTH         (MEM_ADDR_WIDTH       ),
  //.MEM_FILE           ("NOTHING"            ),
  //.MEM_FILE_LENGTH    (0                    ),
  .INITIALIZE         (0                    )
) lm(
  .clka               (i_axi_clk            ),
  .wea                (lma_wen              ),
  .addra              (lma_addr             ),
  .dina               (lma_dina             ),
  .douta              (lma_douta            ),

  .clkb               (i_axi_clk            ),  //This clock can be changed
  .web                (lmb_wen              ),
  .addrb              (lmb_addr             ),
  .dinb               (lmb_dina             ),
  .doutb              (lmb_douta            )
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
  nes_reset                               <=  0;

  if (w_axi_rst) begin
    r_reg_out_data                        <=  0;

    //Reset the temporary Data
    r_control                             <=  0;
    nes_reset                             <=  1;
  end
  else begin

    if (w_reg_in_rdy) begin
      //From master
      case (w_reg_address)
        REG_CONTROL: begin
          //$display("Incoming data on address: 0x%h: 0x%h", w_reg_address, w_reg_in_data);
          r_control                       <=  w_reg_in_data;
        end
        REG_STATUS: begin
        end
        REG_VERSION: begin
          //$display("Incoming data on address: 0x%h: 0x%h", w_reg_address, w_reg_in_data);
        end
        default: begin
          $display ("Unknown address: 0x%h", w_reg_address);
          //Tell the host they wrote to an invalid address
          r_reg_invalid_addr                  <= 1;
        end
      endcase
      //Tell the AXI Slave Control we're done with the data
      r_reg_in_ack                            <= 1;
    end
    else if (w_reg_out_req) begin
      //To master
      //$display("User is reading from address 0x%0h", w_reg_address);
      case (w_reg_address)
        REG_CONTROL: begin
          r_reg_out_data                          <= 0;
        end
        REG_STATUS: begin
          r_reg_out_data                      <=  0;
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


//Download Types Block
//On Screen Display Reset Block
//Save Block
//Save Pending Block
//Pallette Loader Block
//Codes BLock
//State Save/Load

reg   [3:0]   am_state;
localparam  MI_IDLE       = 0;
localparam  MI_CTRL_WR    = 1;
localparam  MI_WR         = 2;
localparam  MI_WR_RESP    = 3;
localparam  MI_CTRL_RD    = 4;
localparam  MI_RD         = 5;

always @ (posedge i_axi_clk) begin
  am_read_stb         <=  0;
  am_write_stb        <=  0;
  if (w_axi_rst) begin
    am_req_id         <=  0;
    am_req_addr       <=  0;
    am_req_data_len   <=  0;
    am_req_en_strb    <=  0;
    am_state          <=  MI_IDLE;
  end
  else begin
    case (am_state)
      MI_IDLE: begin
      end
      MI_CTRL_WR: begin
      end
      MI_WR: begin
      end
      MI_WR_RESP: begin
      end
      MI_CTRL_RD: begin
      end
      MI_RD: begin
      end
      default: begin
        am_state      <= MI_IDLE;
      end


    endcase
  end
end


endmodule
