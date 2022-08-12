
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

`define MAJOR_VERSION             1
`define MINOR_VERSION             0
`define REVISION                  0

`define MAJOR_RANGE               31:28
`define MINOR_RANGE               27:20
`define REVISION_RANGE            19:16

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



module nes #(
  parameter ADDR_WIDTH          = 16,
  parameter INVERT_AXI_RESET    = 1

  parameter M_ADDR_WIDTH        = 32,
  parameter M_DATA_WIDTH        = 64,
  parameter M_STRB_WIDTH        = (M_DATA_WIDTH / 8)

  parameter VIDEO_WIDTH         = 32,
  parameter AUDIO_WIDTH         = 32,
  parameter WIDTH_SIZE          = 12,
  parameter HEIGHT_SIZE         = 12,


  parameter CLOCK_FREQ_KHZ      = 50000,    //50 MHz

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

  output  reg                         o_led_power,
  output  reg                         o_led_disk,




  //Master Interface
  //Write Address Channel
  output                              o_master_awvalid,
  output      [M_ADDR_WIDTH - 1: 0]   o_master_awaddr,
  input                               i_master_awready,

  //Write Data Channel
  output                              o_master_wvalid,
  input                               i_master_wready,
  output      [M_STRB_WIDTH - 1:0]    o_master_wstrb,
  output      [M_DATA_WIDTH - 1:0]    o_master_wdata,

  //Write Response Channel
  input                               i_master_bvalid,
  output                              o_master_bready,
  input       [1:0]                   i_master_bresp,

  //Read Address Channel
  output                              o_master_arvalid,
  input                               i_master_arready,
  output      [ADDR_WIDTH - 1: 0]     o_master_araddr,

  //Read Data Channel
  input                               i_master_rvalid,
  output                              o_master_rready,
  input      [1:0]                    i_master_rresp,
  input      [M_STRB_WIDTH - 1: 0]    i_master_rstrb,
  input      [M_DATA_WIDTH - 1: 0]    i_master_rdata,




  //Read Data Channel
  input                               i_axis_video_clk,
  output  reg                         o_axis_video_tuser,
  output                              o_axis_video_tvalid,
  input                               i_axis_video_tready,
  output      [VIDEO_WIDTH - 1: 0]    o_axis_video_tdata,
  output                              o_axis_video_tlast,

  input                               i_axis_audio_clk,
  output  reg                         o_axis_audio_tuser,
  output                              o_axis_audio_tvalid,
  input                               i_axis_audio_tready,
  output      [AUDIO_WIDTH - 1: 0]    o_axis_audio_tdata,
  output                              o_axis_audio_tlast



);
//local parameters

//Address Map
localparam  REG_CONTROL      = 0 << 2;
localparam  REG_VERSION      = 1 << 2;

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


//TEMP DATA, JUST FOR THE DEMO
reg   [31: 0]               r_control;
wire  [31: 0]               w_version;


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

//Video Freak
//HPS IO
//PLL
//Video
//Video Mixer
//Save State UI



//Game Loader
wire          clk;
wire          loader_reset;
wire          downloading;
wire          type_nsf;
wire          type_fds;
wire          type_nes;
wire          type_bios;
wire          is_bios;
wire [7:0]    loader_input;
wire          loader_clk;
wire [24:0]   loader_addr;
wire [7:0]    loader_write_data;
wire          loader_write;
wire [63:0]   loader_flags;
wire [9:0]    prg_mask;
wire [9:0]    chr_mask;
wire          loader_busy;
wire          loader_done;
wire          loader_fail;
wire          rom_loaded;

game_loader gl
(
	.clk              (clk                                                ),
	.reset            (loader_reset                                       ),
	.downloading      (downloading                                        ),
	.filetype         ({4'b0000, type_nsf, type_fds, type_nes, type_bios} ),
	.is_bios          (is_bios                                            ), // boot0 bios
	.indata           (loader_input                                       ),
	.indata_clk       (loader_clk                                         ),
	.mem_addr         (loader_addr                                        ),
	.mem_data         (loader_write_data                                  ),
	.mem_write        (loader_write                                       ),
	.mapper_flags     (loader_flags                                       ),
	.prg_mask         (prg_mask                                           ),
	.chr_mask         (chr_mask                                           ),
	.busy             (loader_busy                                        ),
	.done             (loader_done                                        ),
	.error            (loader_fail                                        ),
	.rom_loaded       (rom_loaded                                         )

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
          //$display("Incoming data on address: 0x%h: 0x%h", w_reg_address, w_reg_in_data);
          r_control                       <=  w_reg_in_data;
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


endmodule
