
/*
Distributed under the MIT license.
Copyright (c) 2017 Dave McCoy (dave.mccoy@cospandesign.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

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
`define REVISION                  1

`define BIT_CTRL_EN               0
`define BIT_CTRL_CLEAR_SCREEN_STB 1
`define BIT_CTRL_SCROLL_EN        4
`define BIT_CTRL_SCROLL_UP_STB    5
`define BIT_CTRL_SCROLL_DOWN_STB  6

`define MAJOR_RANGE               31:28
`define MINOR_RANGE               27:20
`define REVISION_RANGE            19:16
`define VERSION_PAD_RANGE         15:0

`define CHAR_ADDR_RANGE           7:0
`define BIT_CHAR_ALT_ENABLE       8

`define TAB_COUNT_RANGE           2:0

`define BIT_AXIS_RST              0
`define BIT_CHAR_BUF_RDY          1
`define BIT_CONSOLE_IDLE          2
`define BIT_RANGE_COSD_STATE      7:4
`define BIT_AXIS_RDY              12
`define BIT_AXIS_VLD              13
`define BIT_AXIS_USR              14
`define BIT_AXIS_LST              15
`define BIT_RANGE_PCOUNT          31:16

`define DEFAULT_WIDTH             640
`define DEFAULT_HEIGHT            480
//Given a 100MHz reference clock, 60Hz Output

module axi_terminal #(
  parameter                           CONSOLE_DEPTH       = 12,
  parameter                           IMAGE_WIDTH         = 640,
  parameter                           IMAGE_HEIGHT        = 480,
  parameter                           FOREGROUND_COLOR    = 24'hFFFFFF,
  parameter                           BACKGROUND_COLOR    = 24'h000000,
  //parameter                           DEFAULT_INTERVAL    = 10,
  parameter                           DEFAULT_INTERVAL    = 1000,
  parameter                           FONT_FILE           = "fontdata.mif",
  parameter                           FONT_WIDTH          = 5,
  parameter                           FONT_HEIGHT         = 7,
  parameter                           DEFAULT_ALPHA       = 8'hFF,
  parameter                           DEFAULT_TAB_COUNT   = 2,
  parameter                           DEFAULT_X_START     = 0,
  parameter                           DEFAULT_X_END       = IMAGE_WIDTH,
  parameter                           DEFAULT_Y_START     = 0,
  parameter                           DEFAULT_Y_END       = IMAGE_HEIGHT,
  parameter                           AXIS_WIDTH          = 32,
  parameter                           ADDR_WIDTH          = 16,
  parameter                           INVERT_AXIS_RESET   = 1,
  parameter                           INVERT_AXI_RESET    = 1
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
  input       [31: 0]                 i_wdata,
  input       [3:0]                   i_wstrb,

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

  //AXI Stream Output
  input                               i_axis_clk,
  input                               i_axis_rst,

  output                              o_axis_out_tuser,
  output                              o_axis_out_tvalid,
  output      [AXIS_WIDTH - 1:0]      o_axis_out_tdata,
  input                               i_axis_out_tready,
  output                              o_axis_out_tlast

);
//local parameters

//Address Map
localparam  REG_CONTROL         = 0  << 2;
localparam  REG_STATUS          = 1  << 2;
localparam  REG_IMAGE_WIDTH     = 2  << 2;
localparam  REG_IMAGE_HEIGHT    = 3  << 2;
localparam  REG_IMAGE_SIZE      = 4  << 2;
localparam  REG_FG_COLOR        = 5  << 2;
localparam  REG_BG_COLOR        = 6  << 2;
localparam  REG_CONSOLE_CHAR    = 7  << 2;
localparam  REG_CONSOLE_COMMAND = 8  << 2;
localparam  REG_TAB_COUNT       = 9  << 2;
localparam  REG_X_START         = 10 << 2;
localparam  REG_X_END           = 11 << 2;
localparam  REG_Y_START         = 12 << 2;
localparam  REG_Y_END           = 13 << 2;
localparam  REG_ADAPTER_DEBUG   = 14 << 2;
localparam  REG_ALPHA           = 15 << 2;
localparam  REG_INTERVAL        = 16 << 2;
localparam  REG_VERSION         = 20 << 2;

localparam  MAX_ADDR            = REG_VERSION;

localparam  PIXEL_WIDTH         = 24;
//registers/wires

//User Interface
wire                        w_axi_rst;
wire  [ADDR_WIDTH - 1: 0]   w_reg_address;
reg                         r_reg_invalid_addr;

wire                        w_reg_in_rdy;
reg                         r_reg_in_ack;
wire  [31: 0]               w_reg_in_data;

wire                        w_reg_out_req;
reg                         r_reg_out_rdy;
reg   [31: 0]               r_reg_out_data;
reg   [7:0]                 r_alpha;


reg                         r_enable;
reg                         r_clear_screen_stb;
wire                        w_clear_screen;
reg                         r_scroll_en;
reg                         r_scroll_up_stb;
reg                         r_scroll_down_stb;

reg   [31:0]                r_image_width;
reg   [31:0]                r_image_height;
reg   [31:0]                r_image_size;
reg   [31:0]                r_console_command;
reg   [7:0]                 r_char_data;




wire  [31: 0]               status;
wire                        w_console_idle;
wire  [31: 0]               w_version;

wire  [23:0]                w_block_fifo_size;
wire                        w_block_fifo_rdy;
wire                        w_block_fifo_act;
wire                        w_block_fifo_stb;
wire  [PIXEL_WIDTH:0]       w_block_fifo_data;
wire  [31:0]                w_adapter_debug;

//Simple User Interface

//Handle Inversion
wire                        w_axis_rst;
wire  [31:0]                w_debug;
reg   [23: 0]               r_fg_color;
reg   [23: 0]               r_bg_color;
reg                         r_alt_char;
reg   [2:0]                 r_tab_count;

reg                         r_cmd_stb;
reg                         r_char_stb;
wire                        w_wr_char_rdy;
wire  [3:0]                 w_cosd_state;
wire  [15:0]                w_pcount;

reg   [31:0]                r_x_start;
reg   [31:0]                r_x_end;
reg   [31:0]                r_y_start;
reg   [31:0]                r_y_end;

reg                         r_start_frame_stb;
reg   [31:0]                r_interval;
reg   [31:0]                r_interval_count;





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

console_osd #(
  .CONSOLE_DEPTH      (CONSOLE_DEPTH        ),
  .IMAGE_WIDTH        (IMAGE_WIDTH          ),
  .IMAGE_HEIGHT       (IMAGE_HEIGHT         ),
  .PIXEL_WIDTH        (PIXEL_WIDTH          ),
  .FONT_FILE          (FONT_FILE            ),
  .FONT_WIDTH         (FONT_WIDTH           ),
  .FONT_HEIGHT        (FONT_HEIGHT          )
)cosd(
  .clk                (i_axi_clk            ),
  .rst                (w_axi_rst            ),
  .i_enable           (r_enable             ),
  .o_idle             (w_console_idle       ),

  .i_fg_color         (r_fg_color           ),
  .i_bg_color         (r_bg_color           ),

  .i_cmd_stb          (r_cmd_stb            ),
  .i_cmd              (r_console_command    ),

  .i_char_stb         (r_char_stb           ),
  .i_char             (r_char_data          ),
  .o_wr_char_rdy      (w_wr_char_rdy        ),

  .i_clear_screen_stb (r_clear_screen_stb   ),
  .i_alt_func_en      (r_alt_char           ),
  .i_tab_count        (r_tab_count          ),

  .o_clear_screen     (w_clear_screen       ),
  .i_scroll_en        (r_scroll_en          ),
  .i_scroll_up_stb    (r_scroll_up_stb      ),
  .i_scroll_down_stb  (r_scroll_down_stb    ),

  .i_start_frame_stb  (r_start_frame_stb    ),

  .i_x_start          (r_x_start            ),
  .i_x_end            (r_x_end              ),
  .i_y_start          (r_y_start            ),
  .i_y_end            (r_y_end              ),

  .i_block_fifo_clk   (i_axis_clk           ),
  .i_block_fifo_rst   (w_axis_rst           ),
  .o_block_fifo_rdy   (w_block_fifo_rdy     ),
  .i_block_fifo_act   (w_block_fifo_act     ),
  .o_block_fifo_size  (w_block_fifo_size    ),
  .o_block_fifo_data  (w_block_fifo_data    ),
  .i_block_fifo_stb   (w_block_fifo_stb     ),

  //Debug Signals
  .o_state            (w_cosd_state         ),
  .o_pixel_count      (w_pcount             )
);

wire  [AXIS_WIDTH: 0] w_axis_out_data;

generate
case (AXIS_WIDTH)
  32:       assign w_axis_out_data = {w_block_fifo_data[PIXEL_WIDTH], r_alpha, w_block_fifo_data[PIXEL_WIDTH - 1: 0]};
  24:       assign w_axis_out_data = w_block_fifo_data;
  default:  assign w_axis_out_data = w_block_fifo_data;
endcase
endgenerate

//Take in an AXI video stream and output the data into a PPFIFO
adapter_block_fifo_2_axi_stream #(
  .DATA_WIDTH         (AXIS_WIDTH           ),
  .USER_DATA_WIDTH    (1                    )
) as2p (
  .rst                (w_axis_rst           ),

  //Ping Pong FIFO Write Controller
  .i_block_fifo_rdy   (w_block_fifo_rdy     ),
  .o_block_fifo_act   (w_block_fifo_act     ),
  .i_block_fifo_size  (w_block_fifo_size    ),
  .i_block_fifo_data  (w_axis_out_data      ),
  .o_block_fifo_stb   (w_block_fifo_stb     ),
  //i_axi_user,

  //AXI Stream Input
  .i_axi_clk          (i_axis_clk           ),
  .i_axi_ready        (i_axis_out_tready    ),
  .o_axi_data         (o_axis_out_tdata     ),
  .o_axi_last         (o_axis_out_tlast     ),
  .o_axi_valid        (o_axis_out_tvalid    ),
  .o_axi_user         (o_axis_out_tuser     ),

  .o_debug            (w_adapter_debug      )
);

//Asynchronous logic

assign w_axi_rst                      = INVERT_AXI_RESET      ? ~i_axi_rst : i_axi_rst;
assign w_axis_rst                     = INVERT_AXIS_RESET     ? ~i_axis_rst  : i_axis_rst;
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
  r_cmd_stb                               <=  0;
  r_char_stb                              <=  0;
  r_alt_char                              <=  0;
  r_clear_screen_stb                      <=  0;
  r_scroll_up_stb                         <=  0;
  r_scroll_down_stb                       <=  0;



  if (w_axi_rst) begin
    //Reset the temporary Data
    r_enable                                                  <=  0;
    r_scroll_en                                               <=  0;
    r_interval                                                <= DEFAULT_INTERVAL;
    r_reg_out_data                                            <=  0;
    r_image_width                                             <=  IMAGE_WIDTH;
    r_image_height                                            <=  IMAGE_HEIGHT;
    r_image_size                                              <=  (IMAGE_WIDTH * IMAGE_HEIGHT);
    r_x_start                                                 <=  DEFAULT_X_START;
    r_x_end                                                   <=  DEFAULT_X_END;
    r_y_start                                                 <=  DEFAULT_Y_START;
    r_y_end                                                   <=  DEFAULT_Y_END;
    r_fg_color                                                <=  FOREGROUND_COLOR;
    r_bg_color                                                <=  BACKGROUND_COLOR;
    r_tab_count                                               <=  DEFAULT_TAB_COUNT;
    r_char_data                                               <=  0;
    r_console_command                                         <=  0;
    r_alpha                                                   <=  DEFAULT_ALPHA;
  end
  else begin
    if (w_reg_in_rdy) begin
      //From master
      case (w_reg_address)
        REG_CONTROL: begin
          r_enable                                            <= w_reg_in_data[`BIT_CTRL_EN];
          r_clear_screen_stb                                  <= w_reg_in_data[`BIT_CTRL_CLEAR_SCREEN_STB];
          r_scroll_en                                         <= w_reg_in_data[`BIT_CTRL_SCROLL_EN];
          r_scroll_up_stb                                     <= w_reg_in_data[`BIT_CTRL_SCROLL_UP_STB];
          r_scroll_down_stb                                   <= w_reg_in_data[`BIT_CTRL_SCROLL_DOWN_STB];
        end
        REG_FG_COLOR: r_fg_color                              <= w_reg_in_data[23: 0];
        REG_BG_COLOR: r_bg_color                              <= w_reg_in_data[23: 0];
        REG_CONSOLE_CHAR: begin
          r_char_data                                         <= w_reg_in_data[`CHAR_ADDR_RANGE];
          r_alt_char                                          <= w_reg_in_data[`BIT_CHAR_ALT_ENABLE];
          if (w_wr_char_rdy) r_char_stb                       <= 1;
        end
        REG_INTERVAL:        r_interval                       <= w_reg_in_data;
        REG_CONSOLE_COMMAND: r_console_command                <= w_reg_in_data;
        REG_X_START:         r_x_start                        <= w_reg_in_data;
        REG_X_END:           r_x_end                          <= w_reg_in_data;
        REG_Y_START:         r_y_start                        <= w_reg_in_data;
        REG_Y_END:           r_y_end                          <= w_reg_in_data;
        REG_TAB_COUNT:       r_tab_count                      <= w_reg_in_data[`TAB_COUNT_RANGE];
        REG_ALPHA:           r_alpha                          <= w_reg_in_data;
        default: begin
          $display ("Unknown address: 0x%h", w_reg_address);
        end
      endcase
      //Tell the AXI Slave Control we're done with the data
      if (w_reg_address > REG_VERSION) begin
        r_reg_invalid_addr                                    <= 1;
      end
      r_reg_in_ack                                            <= 1;
    end
    else if (w_reg_out_req) begin
      //To master
      case (w_reg_address)
        REG_CONTROL: begin
          r_reg_out_data                                      <=  0;
          r_reg_out_data[`BIT_CTRL_EN]                        <= r_enable;
          r_reg_out_data[`BIT_CTRL_SCROLL_EN]                 <= r_scroll_en;
        end
        REG_STATUS: begin
          r_reg_out_data                                      <=  0;
          r_reg_out_data[`BIT_CHAR_BUF_RDY]                   <= w_wr_char_rdy;
          r_reg_out_data[`BIT_CONSOLE_IDLE]                   <= w_console_idle;
          r_reg_out_data[`BIT_AXIS_RST]                       <= w_axis_rst;
          r_reg_out_data[`BIT_RANGE_COSD_STATE]               <= w_cosd_state;
          r_reg_out_data[`BIT_AXIS_RDY]                       <= i_axis_out_tready;
          r_reg_out_data[`BIT_AXIS_VLD]                       <= o_axis_out_tvalid;
          r_reg_out_data[`BIT_AXIS_USR]                       <= o_axis_out_tuser;
          r_reg_out_data[`BIT_AXIS_LST]                       <= o_axis_out_tlast;
          r_reg_out_data[`BIT_RANGE_PCOUNT]                   <= w_pcount;
        end
        REG_IMAGE_WIDTH:       r_reg_out_data                  <= r_image_width;
        REG_IMAGE_HEIGHT:      r_reg_out_data                  <= r_image_height;
        REG_INTERVAL:         r_reg_out_data                  <= r_interval;
        REG_IMAGE_SIZE:       r_reg_out_data                  <= r_image_size;
        REG_FG_COLOR:         r_reg_out_data                  <= {8'h0, r_fg_color};
        REG_BG_COLOR:         r_reg_out_data                  <= {8'h0, r_bg_color};
        REG_CONSOLE_CHAR:     r_reg_out_data                  <= r_char_data;
        REG_CONSOLE_COMMAND:  r_reg_out_data                  <= r_console_command;
        REG_X_START:          r_reg_out_data                  <= r_x_start;
        REG_X_END:            r_reg_out_data                  <= r_x_end;
        REG_Y_START:          r_reg_out_data                  <= r_y_start;
        REG_Y_END:            r_reg_out_data                  <= r_y_end;
        REG_TAB_COUNT:        r_reg_out_data[`TAB_COUNT_RANGE]<= r_tab_count;
        REG_ADAPTER_DEBUG:    r_reg_out_data                  <= w_adapter_debug;
        REG_ALPHA:            r_reg_out_data                  <= r_alpha;
        REG_VERSION:          r_reg_out_data                  <= w_version;
        default: begin
          //Unknown address
          r_reg_out_data                                      <= 32'h00;
        end
      endcase
      if (w_reg_address > REG_VERSION) begin
        r_reg_invalid_addr                                    <= 1;
      end
      //Tell the AXI Slave to send back this packet
      r_reg_out_rdy                                           <= 1;
    end
  end
end


//Generated a start pulse for a new frame
always @ (posedge i_axi_clk) begin
  r_start_frame_stb                   <=  0;
  if (w_axi_rst) begin
    r_interval_count                  <=  0;
  end
  else begin
    if (r_enable && !w_clear_screen) begin
      if (r_interval_count  < r_interval) begin
        r_interval_count              <= r_interval_count + 1;
      end
      else begin
        r_interval_count              <=  0;
        r_start_frame_stb             <=  1;
      end
    end
    else begin
      r_interval_count                <=  r_interval;
    end
  end
end


endmodule
