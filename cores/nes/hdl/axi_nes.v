
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
`define CTL_BIT_LOADER_RESET    4


`define STS_BIT_ROM_LOADED      4


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


  parameter WIDTH_SIZE          = 12,
  parameter HEIGHT_SIZE         = 12,

  parameter INVERT_AXI_RESET    = 1
)(
  input                               i_axi_clk,
  input                               i_axi_rst,

  input                               nes_clk,

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

  output      [DATA_WIDTH-1:0]  axi_rdata,
  input       [ID_WIDTH-1: 0]   axi_rid,
  output                        axi_rlast,
  output                        axi_rvalid,
  input       [1:0]             axi_rresp,
  input                         axi_rready


  /*************************************************************************
  * AXI Streams
  *************************************************************************/

  //Audio Channel
  input                               i_axis_audio_clk,
  output  reg                         o_axis_audio_tuser,
  output                              o_axis_audio_tvalid,
  input                               i_axis_audio_tready,
  output      [VIDEO_WIDTH - 1: 0]    o_axis_audio_tdata,
  output                              o_axis_audio_tlast

  //Video Channel
  input                               i_axis_video_clk,
  output  reg                         o_axis_video_tuser,
  output                              o_axis_video_tvalid,
  input                               i_axis_video_tready,
  output      [VIDEO_WIDTH - 1: 0]    o_axis_video_tdata,
  output                              o_axis_video_tlast
);
//local parameters

//Address Map
localparam  REG_CONTROL     = 0 << 2;
localparam  REG_STATUS      = 1 << 2;
localparam  REG_VERSION     = 1 << 16;

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
reg   [31: 0]                   r_control;
wire  [31: 0]                   w_version;


/*************************************************************************
* Memory Interface
*************************************************************************/
reg    [AM_ID_WIDTH-1:0]      mi_req_id,
reg    [AM_ADDR_WIDTH - 1:0]  mi_req_addr,
reg    [7:0]                  mi_req_data_len,
reg                           mi_req_en_strb,
reg                           mi_read_stb,
reg                           mi_write_stb,

wire                          mi_ready,
wire   [AM_ID_WIDTH-1:0]      mi_resp_id,

wire   [AM_DATA_WIDTH-1:0]    usr_w_tdata,
wire   [AM_STRB_WIDTH-1:0]    usr_w_tstrb,
wire                          usr_w_tlast,
wire                          usr_w_tvalid,
wire                          usr_w_tready,

wire   [AM_DATA_WIDTH-1:0]    usr_r_tdata,
wire                          usr_r_tlast,
wire                          usr_r_tvalid,
wire                          usr_r_tready,




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
  .clk                (i_axi_clk            ),
  .rst                (w_axi_rst            ),
  /*************************************************************************
  * User Interface
  *************************************************************************/
  .i_id               (mi_req_id            ),
  .i_addr             (mi_req_addr          ),
  .i_data_len         (mi_req_data_len      ),
  .i_en_strb          (mi_req_en_strb       ),
  .i_start_read_stb   (mi_read_stb          ),
  .i_start_write_stb  (mi_write_stb         ),

  .o_ready            (mi_ready             ),
  .o_resp_id          (mi_resp_id           ),

  .usr_w_tdata        (mi_w_tdata           ),
  .usr_w_tstrb        (mi_w_tstrb           ),
  .usr_w_tlast        (mi_w_tlast           ),
  .usr_w_tvalid       (mi_w_tvalid          ),
  .usr_w_tready       (mi_w_tready          ),

  .usr_r_tdata        (mi_r_tdata           ),
  .usr_r_tlast        (mi_r_tlast           ),
  .usr_r_tvalid       (mi_r_tvalid          ),
  .usr_r_tready       (mi_r_tready          ),

  /*************************************************************************
  * AXI Master Interface
  *************************************************************************/
  .axi_awaddr         (axi_awaddr          ),
  .axi_awid           (axi_awid            ),
  .axi_awlen          (axi_awlen           ),
  .axi_awsize         (axi_awsize          ),
  .axi_awburst        (axi_awburst         ),
  .axi_awvalid        (axi_awvalid         ),
  .axi_awready        (axi_awready         ),

  .axi_wdata          (axi_wdata           ),
  .axi_wid            (axi_wid             ),
  .axi_wstrb          (axi_wstrb           ),
  .axi_wlast          (axi_wlast           ),
  .axi_wvalid         (axi_wvalid          ),
  .axi_wready         (axi_wready          ),

  .axi_bresp          (axi_bresp           ),
  .axi_bid            (axi_bid             ),
  .axi_bvalid         (axi_bvalid          ),
  .axi_bready         (axi_bready          ),

  .axi_araddr         (axi_araddr          ),
  .axi_arid           (axi_arid            ),
  .axi_arlen          (axi_arlen           ),
  .axi_arsize         (axi_arsize          ),
  .axi_arburst        (axi_arburst         ),
  .axi_arvalid        (axi_arvalid         ),
  .axi_arready        (axi_arready         ),

  .axi_rdata          (axi_rdata           ),
  .axi_rid            (axi_rid             ),
  .axi_rlast          (axi_rlast           ),
  .axi_rvalid         (axi_rvalid          ),
  .axi_rresp          (axi_rresp           ),
  .axi_rready         (axi_rready          )
);


//Video Freak
//HPS IO
//PLL
//Video
//Video Mixer
//Save State UI



//Game Loader
wire          clk;
reg           r_loader_reset;
reg           r_download;
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
wire          w_rom_loaded;

game_loader gl
(
  .clk              (clk                                                ),
  .reset            (r_loader_reset                                     ),
  .download         (r_download                                         ),
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
  .rom_loaded       (w_rom_loaded                                       )

);


wire  [1:0]   w_sys_type;



//Save State Interface
wire          ss_save_state_mapper_has_ss;  //SS Control Flag to enable mapper has save state
wire          ss_increase_header_count;     //SS Control Bit Increase SS Header FLAG
wire          ss_save_stb;                  //SS Control Bit Save State Save STB
wire          ss_load_stb;                  //SS Control Bit Save State Load STB
wire  [1:0]   ss_slot_index;                //Register: Slot Index Select
wire          ss_save_state_sleep;          //SS Status Bit

wire  [7:0]   ss_sdram_read_data;
wire  [7:0]   ss_sdram_write_data;
wire  [24:0]  ss_sdram_addr;
wire          ss_sdram_rd_en;
wire          ss_sdram_wr_en;

wire  [63:0]  ss_ext_din;
wire  [63:0]  ss_ext_dout;
wire  [9:0]   ss_ext_addr;
wire          ss_ext_wren;
wire          ss_ext_rst;
wire          ss_ext_load;

wire  [63:0]  ss_out_din;
wire  [63:0]  ss_out_dout;
wire  [25:0]  ss_out_addr;
wire          ss_out_rnw;
wire          ss_out_req;
wire   [7:0]  ss_out_be;
wire          ss_out_ack;





NES nes (
  .clk                     (clk                                   ),
  .reset_nes               (reset_nes                             ),
  .cold_reset              (r_download & (type_fds | type_nes    )),
  .pausecore               (pausecore                             ),
  .corepaused              (corepaused                            ),
  .sys_type                (w_sys_type                            ),
  .nes_div                 (nes_ce                                ),
  .mapper_flags            (r_download ? 64'd0 : mapper_flags     ),

  //Game Genie
  .gg                      (status[20]                            ),
  .gg_code                 (gg_code                               ),
  .gg_reset                (gg_reset && loader_clk && !ioctl_addr ),
  .gg_avail                (gg_avail                              ),


  // Audio
  .sample                  (sample                                ),
  .audio_channels          (5'b11111                              ),
  .int_audio               (int_audio                             ),
  .ext_audio               (ext_audio                             ),
  .apu_ce                  (apu_ce                                ),
  // Video
  .ex_sprites              (status[25]                            ),
  .color                   (color                                 ),
  .emphasis                (emphasis                              ),
  .cycle                   (cycle                                 ),
  .scanline                (scanline                              ),
  .mask                    (status[28:27]                         ),
  // User Input
  .joypad_out              (joypad_out                            ),
  .joypad_clock            (joypad_clock                          ),
  .joypad1_data            (joypad1_data                          ),
  .joypad2_data            (joypad2_data                          ),

  .diskside                (diskside                              ),
  .fds_busy                (fds_busy                              ),
  .fds_eject               (fds_btn                               ),
  .fds_auto_eject          (fds_auto_eject                        ),
  .max_diskside            (max_diskside                          ),

  // Memory transactions
  .cpumem_addr             (cpu_addr                              ),
  .cpumem_read             (cpu_read                              ),
  .cpumem_write            (cpu_write                             ),
  .cpumem_dout             (cpu_dout                              ),
  .cpumem_din              (cpu_din                               ),
  .ppumem_addr             (ppu_addr                              ),
  .ppumem_read             (ppu_read                              ),
  .ppumem_write            (ppu_write                             ),
  .ppumem_dout             (ppu_dout                              ),
  .ppumem_din              (ppu_din                               ),
  .refresh                 (refresh                               ),

  .prg_mask                (prg_mask                              ),
  .chr_mask                (chr_mask                              ),

  .bram_addr               (bram_addr                             ),
  .bram_din                (bram_din                              ),
  .bram_dout               (bram_dout                             ),
  .bram_write              (bram_write                            ),
  .bram_override           (bram_en                               ),
  .save_written            (save_written                          ),

  /***************************************************************************
  * Save States
  ***************************************************************************/
  //Controls
  .save_state_mapper_has_ss   (ss_save_state_mapper_has_ss        ),
  .save_state_increase_hdr_cnt(ss_increase_header_count           ),
  .save_state_save            (ss_save_stb                        ),
  .save_state_load            (ss_load_stb                        ),
  .save_state_slot_index      (ss_slot_index                      ),
  .save_state_sleep           (ss_save_state_sleep                ),


  //Deterministic SDRAM Interface (Can we remove this and only use DDR??)
  .save_state_sdram_addr      (ss_sdram_addr                      ),  //Determinisitic SDRAM RAM State
  .save_state_sdram_rd_en     (ss_sdram_rd_en                     ),
  .save_state_sdram_wr_en     (ss_sdram_wr_en                     ),
  .save_state_sdram_wr_data   (ss_sdram_write_data                ),
  .save_state_sdram_rd_data   (ss_sdram_read_data                 ),

  //I think this is related to the mapper
  .save_state_ext_din         (ss_ext_din                         ),
  .save_state_ext_addr        (ss_ext_addr                        ),
  .save_state_ext_wren        (ss_ext_wren                        ),
  .save_state_ext_rst         (ss_ext_rst                         ),
  .save_state_ext_dout        (ss_ext_dout                        ),
  .save_state_ext_load        (ss_ext_load                        ),  // Used for SDRAM

  //DDR3 Memory
  .save_state_out_din         (ss_out_din                         ),  // data read from savestate
  .save_state_out_dout        (ss_out_dout                        ),  // data written to savestate
  .save_state_out_addr        (ss_out_addr                        ),  // all addresses are DWORD addresses!
  .save_state_out_rnw         (ss_out_rnw                         ),  // read = 1, write = 0
  .save_state_out_ena         (ss_out_req                         ),  // one cycle high for each action
  .save_state_out_be          (ss_out_be                          ),
  .save_state_out_done        (ss_out_ack                         )   // should be one cycle high when write is done or read value is valid
);


wire [63:0] ss_ext;
wire [63:0] ss_ext_back;

wire [15:0] sdram_ss_in = ss_ext[15:0];
wire [15:0] sdram_ss_out;

assign ss_ext_back[15: 0] = sdram_ss_out;
assign ss_ext_back[63:16] = 48'b0; // free to be used

eReg_Save_stateV #(
  .Adr        (SSREG_INDEX_EXT    ),
  .def        (SSREG_DEFAULT_EXT  ))
iREG_SAVESTATE_Ext (
  .clk        (i_axi_clk   ),
  .BUS_din    (ss_ext_din  ),
  .BUS_addr   (ss_ext_adr  ),
  .BUS_wren   (ss_ext_wren ),
  .BUS_rst    (ss_ext_rst  ),
  .BUS_dout   (ss_ext_dout ),
  .Din        (ss_ext_back ),
  .Dout       (ss_ext      )
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
  r_loader_reset                          <=  0;

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
          r_loader_reset                  <=  w_reg_in_data[`CTL_BIT_LOADER_RESET];
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
          r_reg_out_data                      <= r_control;
        end
        REG_STATUS: begin
          r_reg_out_data                      <=  0;
          r_reg_out_data[`STS_BIT_ROM_LOADED] <=  w_rom_loaded;
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

reg   [3:0]   mi_state;
localparam  MI_IDLE       = 0;
localparam  MI_CTRL_WR    = 1;
localparam  MI_WR         = 2;
localparam  MI_WR_RESP    = 3;
localparam  MI_CTRL_RD    = 4;
localparam  MI_RD         = 5;

always @ (posedge i_axi_clk) begin
  mi_read_stb         <=  0;
  mi_write_stb        <=  0;
  if (w_axi_rst) begin
    mi_req_id         <=  0;
    mi_req_addr       <=  0;
    mi_req_data_len   <=  0;
    mi_req_en_strb    <=  0;
    mi_state          <=  MI_IDLE;
  end
  else begin
    case (mi_state)
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
        mi_state      <= MI_IDLE;
      end


    endcase
  end
end


endmodule
