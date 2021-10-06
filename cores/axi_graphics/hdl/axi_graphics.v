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

`define VERSION_PAD_RANGE         15:0

`define DEFAULT_WIDTH           640
`define DEFAULT_HEIGHT          480

//Given a 100MHz reference clock, 60Hz Output
`define DEFAULT_INTERVAL        1666666

`define CTL_BIT_ENABLE          0
`define CTL_BIT_RGBA_FMT        1

`define ANMT_BIT_ENABLE         0
`define ANMT_BIT_X_DIR          1
`define ANMT_BIT_Y_DIR          2
`define ANMT_BIT_BOUNCE         3
`define ANMT_BR_COUNT_DIV       15:8
`define ANMT_BR_X_STEP          23:16
`define ANMT_BR_Y_STEP          31:24

`define COLOR_RED               {8'hFF, 8'h00, 8'h00}
`define COLOR_GREEN             {8'h00, 8'hFF, 8'h00}
`define COLOR_BLUE              {8'h00, 8'h00, 8'hFF}
`define COLOR_MAGENTA           {8'hFF, 8'h00, 8'hFF}
`define COLOR_CYAN              {8'h00, 8'hFF, 8'hFF}
`define COLOR_YELLOW            {8'hFF, 8'hFF, 8'h00}
`define COLOR_BLACK             {8'h00, 8'h00, 8'h00}
`define COLOR_WHITE             {8'hFF, 8'hFF, 8'hFF}
`define COLOR_GRAY              {8'h7F, 8'h7F, 8'h7F}
`define COLOR_ORANGE            {8'hFF, 8'h80, 8'h00}
`define COLOR_PURPLE            {8'h80, 8'h00, 8'hFF}

`define BM_REF_X                11:0
`define BM_REF_Y                27:16

module axi_graphics #(
  parameter ADDR_WIDTH          = 16,
  parameter AXIS_DATA_WIDTH     = 32,

  parameter WIDTH_SIZE          = 12,
  parameter HEIGHT_SIZE         = 12,
  parameter INTERVAL_SIZE       = 32,
  parameter INVERT_AXI_RESET    = 1
)(
  input                               i_axi_clk,
  input                               i_axi_rst,

  //AXI Lite Interface

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


  //Read Data Channel
  output  reg                         o_axis_out_tuser,
  output                              o_axis_out_tvalid,
  input                               i_axis_out_tready,
  output      [AXIS_DATA_WIDTH - 1: 0]o_axis_out_tdata,
  output                              o_axis_out_tlast
);
//local parameters

//Address Map
localparam  REG_CONTROL       =   0  << 2;
localparam  REG_STATUS        =   1  << 2;
localparam  REG_WIDTH         =   2  << 2;
localparam  REG_HEIGHT        =   3  << 2;
localparam  REG_INTERVAL      =   4  << 2;
localparam  REG_MODE_SEL      =   5  << 2;
localparam  REG_XY_REF0       =   6  << 2;
localparam  REG_XY_REF1       =   7  << 2;
localparam  REG_FG_COLOR_REF  =   8  << 2;
localparam  REG_BG_COLOR_REF  =   9  << 2;
localparam  REG_ALPHA         =   10 << 2;
localparam  REG_ANIMATE       =   11 << 2;

localparam  REG_VERSION       =   20;

localparam  MAX_ADDR          =   REG_VERSION;

//State Machine
localparam  IDLE              =   0;
localparam  DRAW              =   1;
localparam  END_LINE          =   2;

//registers/wires
localparam  MODE_BLACK        =   0;
localparam  MODE_WHITE        =   1;
localparam  MODE_RED          =   2;
localparam  MODE_GREEN        =   3;
localparam  MODE_BLUE         =   4;
localparam  MODE_CB           =   5;
localparam  MODE_SQUARE       =   6;
localparam  MODE_RAMP         =   7;
//localparam  MODE_ANIMATE      =   8;

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

reg [WIDTH_SIZE - 1:0]          r_width;
reg [WIDTH_SIZE - 1:0]          r_temp_width;
reg [HEIGHT_SIZE - 1:0]         r_height;
reg [INTERVAL_SIZE - 1:0]       r_interval;
reg [INTERVAL_SIZE - 1:0]       r_interval_count;
reg [31:0]                      r_mode;

wire [WIDTH_SIZE - 1: 0]        w_cb_width;
wire [31: 0]                    w_version;

//Control Bits
reg                             r_enable;
reg                             r_rgba_format;

reg [3:0]                       state                 = IDLE;
reg                             r_last                = 0;
reg [WIDTH_SIZE - 1:0]          x;
reg [HEIGHT_SIZE - 1:0]         y;
reg                             r_start_stb;

reg [WIDTH_SIZE - 1: 0]         r_ref_x0;
reg [HEIGHT_SIZE - 1: 0]        r_ref_y0;

reg [WIDTH_SIZE - 1: 0]         r_ref_x1;
reg [HEIGHT_SIZE - 1: 0]        r_ref_y1;
reg [31:0]                      r_ref_fg_color;
reg [31:0]                      r_ref_bg_color;

reg [7:0]                       r_alpha = 8'hFF;
reg [23:0]                      r_rgb = 24'hFFFFFF;

//reg                             r_animate_en;       // enable animate
//reg                             r_animate_bounce;   // 0 = stop at the wall, 1 change dir
//reg                             r_animate_x_dir;    // 0 = negative, 1 = positive
//reg                             r_animate_y_dir;    // 0 = negative, 1 = positive
//reg                             r_animate_bounce;   // Change direction if encountered a wall
//reg [7:0]                       r_animate_count_div;// divide the image counter by this, 0 = full speed
//reg signed [7:0]                r_animate_x_step;   // move x by this amount each iteration
//reg signed [7:0]                r_animate_y_step;   // move y by this amount each iteration
//
//reg [WIDTH_SIZE - 1: 0]         r_animate_pos_x;
//reg [HEIGHT_SIZE - 1: 0]        r_animate_pos_y;
//reg [WIDTH_SIZE - 1: 0]         r_animate_width_x;
//reg [HEIGHT_SIZE - 1: 0]        r_animate_width_y;
//reg [7:0]                       r_anim_image_count;

reg                             r_frame_finished;

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

//asynchronous logic

assign w_axi_rst                      = INVERT_AXI_RESET ? ~i_axi_rst : i_axi_rst;
assign w_version[`MAJOR_RANGE]        = `MAJOR_VERSION;
assign w_version[`MINOR_RANGE]        = `MINOR_VERSION;
assign w_version[`REVISION_RANGE]     = `REVISION;
assign w_version[`VERSION_PAD_RANGE]  = 0;


//synchronous logic
always @ (posedge i_axi_clk) begin
  //De-assert
  r_reg_in_ack                            <= 0;
  r_reg_out_rdy                           <= 0;
  r_reg_invalid_addr                      <= 0;

  if (w_axi_rst) begin
    r_reg_out_data                        <= 0;

    //Reset the temporary Data
    r_width                               <= `DEFAULT_WIDTH;
    r_height                              <= `DEFAULT_HEIGHT;

    r_enable                              <= 0;
    r_rgba_format                         <= 1;
    r_interval                            <= `DEFAULT_INTERVAL;
    r_mode                                <= MODE_CB;

    r_ref_x0                              <= 0;
    r_ref_y0                              <= 0;

    r_ref_x1                              <= 0;
    r_ref_y1                              <= 0;
    r_ref_fg_color                        <= {8'hFF, `COLOR_WHITE};
    r_ref_bg_color                        <= {8'hFF, `COLOR_BLACK};
    r_alpha                               <= 8'hFF;

//    r_animate_en                          <= 0;
//    r_animate_x_dir                       <= 0;
//    r_animate_y_dir                       <= 0;
//    r_animate_bounce                      <= 0;
//    r_animate_count_div                   <= 0;
//    r_animate_x_step                      <= 0;
//    r_animate_y_step                      <= 0;

  end
  else begin

    if (w_reg_in_rdy) begin
      //From master
      case (w_reg_address)
        REG_CONTROL: begin
          r_enable                        <=  w_reg_in_data[`CTL_BIT_ENABLE];
          r_rgba_format                   <=  w_reg_in_data[`CTL_BIT_RGBA_FMT];
        end
        REG_WIDTH: begin
          r_width                         <=  w_reg_in_data[WIDTH_SIZE - 1: 0];
        end
        REG_HEIGHT: begin
          r_height                        <=  w_reg_in_data[HEIGHT_SIZE - 1: 0];
        end
        REG_INTERVAL: begin
          r_interval                      <=  w_reg_in_data[INTERVAL_SIZE - 1: 0];
        end
        REG_MODE_SEL: begin
          r_mode                          <=  w_reg_in_data;
        end
        REG_XY_REF0: begin
          r_ref_x0                        <=  w_reg_in_data[`BM_REF_X];
          r_ref_y0                        <=  w_reg_in_data[`BM_REF_Y];
        end
        REG_XY_REF1: begin
          r_ref_x1                        <=  w_reg_in_data[`BM_REF_X];
          r_ref_y1                        <=  w_reg_in_data[`BM_REF_Y];
        end
        REG_FG_COLOR_REF: begin
          r_ref_fg_color                  <=  w_reg_in_data;
        end
        REG_BG_COLOR_REF: begin
          r_ref_bg_color                  <=  w_reg_in_data;
        end
        REG_ALPHA: begin
          r_alpha                         <=  w_reg_in_data[7:0];
        end

//        REG_ANIMATE: begin
//          r_animate_en                    <=  w_reg_in_data[`ANMT_BIT_ENABLE];
//          r_animate_x_dir                 <=  w_reg_in_data[`ANMT_BIT_X_DIR];
//          r_animate_y_dir                 <=  w_reg_in_data[`ANMT_BIT_Y_DIR];
//          r_animate_bounce                <=  w_reg_in_data[`ANMT_BIT_BOUNT];
//          r_animate_count_div             <=  w_reg_in_data[`ANMT_BR_COUNT_DIV];
//          r_animate_x_step                <=  w_reg_in_data[`ANMT_BR_X_STEP];
//          r_animate_y_step                <=  w_reg_in_data[`ANMT_BR_Y_STEP];
//        end
        default: begin
          $display ("Unknown address: 0x%h", w_reg_address);
        end
      endcase
      if (w_reg_address > MAX_ADDR) begin
        //Tell the host they wrote to an invalid address
        r_reg_invalid_addr                <= 1;
      end
      //Tell the AXI Slave Control we're done with the data
      r_reg_in_ack                        <= 1;
    end
    else if (w_reg_out_req) begin
      //To master
      //$display("User is reading from address 0x%0h", w_reg_address);
      case (w_reg_address)
        REG_CONTROL: begin
          r_reg_out_data                    <= 32'h0;
          r_reg_out_data[`CTL_BIT_ENABLE]   <=  r_enable;
          r_reg_out_data[`CTL_BIT_RGBA_FMT] <=  r_rgba_format;
        end
        REG_STATUS: begin
          r_reg_out_data                  <= 32'h0;
        end
        REG_WIDTH: begin
          r_reg_out_data                  <= 32'h0;
          r_reg_out_data[WIDTH_SIZE - 1:0]<= r_width;
        end
        REG_HEIGHT: begin
          r_reg_out_data                  <= 32'h0;
          r_reg_out_data[HEIGHT_SIZE - 1:0]   <= r_height;
        end
        REG_INTERVAL: begin
          r_reg_out_data[INTERVAL_SIZE - 1:0] <= r_interval;
        end
        REG_MODE_SEL: begin
          r_reg_out_data                      <= r_mode;
        end
        REG_XY_REF0: begin
          r_reg_out_data                      <= 32'h00;
          r_reg_out_data[`BM_REF_X]           <=  r_ref_x0;
          r_reg_out_data[`BM_REF_Y]           <=  r_ref_y0;
        end
        REG_XY_REF1: begin
          r_reg_out_data                      <= 32'h00;
          r_reg_out_data[`BM_REF_X]           <=  r_ref_x1;
          r_reg_out_data[`BM_REF_Y]           <=  r_ref_y1;
        end
        REG_FG_COLOR_REF: begin
          r_reg_out_data                      <= r_ref_fg_color;
        end
        REG_BG_COLOR_REF: begin
          r_reg_out_data                      <= r_ref_bg_color;
        end
        REG_ALPHA: begin
          r_reg_out_data                      <= {24'h0, r_alpha};
        end
//        REG_ANIMAGE: begin
//          r_reg_out_data                      <=  32'h0;
//          r_reg_out_data[`ANMT_BIT_ENABLE]    <=  r_animate_en;
//          r_reg_out_data[`ANMT_BIT_X_DIR]     <=  r_animate_x_dir;
//          r_reg_out_data[`ANMT_BIT_Y_DIR]     <=  r_animate_y_dir;
//          r_reg_out_data[`ANMT_BIT_BOUNT]     <=  r_animate_bounce;
//          r_reg_out_data[`ANMT_BR_COUNT_DIV]  <=  r_animate_count_div;
//          r_reg_out_data[`ANMT_BR_X_STEP]     <=  r_animate_x_step;
//          r_reg_out_data[`ANMT_BR_Y_STEP]     <=  r_animate_y_step;
//        end
        REG_VERSION: begin
          r_reg_out_data                  <= w_version;
        end
        default: begin
          r_reg_out_data                  <= 32'h00;
          //r_reg_invalid_addr              <= 1;
        end
      endcase
      //Tell the AXI Slave to send back this packet
      if (w_reg_address > MAX_ADDR) begin
        r_reg_invalid_addr                <= 1;
      end
      r_reg_out_rdy                       <= 1;
    end
  end
end

//Interval Timer
always @ (posedge i_axi_clk) begin
  r_start_stb                         <=  0;
  if (w_axi_rst) begin
    r_interval_count                  <=  0;
  end
  else begin
    if (r_enable) begin
      if (r_interval_count  < r_interval) begin
        r_interval_count              <= r_interval_count + 1;
      end
      else begin
        r_interval_count              <=  0;
        r_start_stb                   <=  1;
      end
    end
    else begin
      r_interval_count                <=  r_interval;
    end
  end
end

reg  [3:0]                r_cm_index;
assign o_axis_out_tlast     = (x == (r_width - 1));
assign o_axis_out_tvalid    = (state == DRAW);

//Main Video Transmitter Controller
always @ (posedge i_axi_clk) begin
  r_frame_finished                    <=  0;
  if (w_axi_rst) begin
    state                             <=  IDLE;
    o_axis_out_tuser                  <=  0;
    r_last                            <=  0;
    x                                 <=  0;
    y                                 <=  0;
    r_temp_width                      <=  0;
    r_cm_index                        <=  0;
  end
  else begin
    case (state)
      IDLE: begin
        o_axis_out_tuser              <=  0;
        r_last                        <=  0;
        x                             <=  0;
        y                             <=  0;
        if (r_start_stb) begin
          o_axis_out_tuser            <=  1;
          state                       <=  DRAW;
        end
      end
      DRAW: begin
        if (i_axis_out_tready) begin
          o_axis_out_tuser            <=  0;
          if (o_axis_out_tlast) begin
            state                     <=  END_LINE;
            x                         <=  0;
          end
          else begin
            x                         <=  x + 1;
          end
        end
      end
      END_LINE: begin
        if (y < r_height) begin
          y                           <=  y + 1;
          state                       <=  DRAW;
        end
        else begin
          //Finished
          state                       <=  IDLE;
          r_frame_finished            <=  1;
        end
      end
      default: begin
        state                         <=  IDLE;
      end
    endcase

    //Specifically for color bars
    if (r_mode == MODE_CB) begin
      if ((x < 1) || (x >= r_width)) begin
        r_temp_width                  <=  (r_width >> 3);
        r_cm_index                    <=  0;
      end
      else if (x >= (r_temp_width - 1)) begin
        r_temp_width                  <= r_temp_width + (r_width >> 3);
        r_cm_index                    <=  r_cm_index + 1;
      end
    end
  end
end



wire [WIDTH_SIZE - 1: 0]  w_start_x;
wire [HEIGHT_SIZE - 1: 0] w_start_y;

wire [WIDTH_SIZE - 1: 0]  w_end_x;
wire [HEIGHT_SIZE - 1: 0] w_end_y;

//assign  o_axis_out_tdata[31:24]  = (r_rgba_format) ? r_rgb[23:16] : r_alpha;
//assign  o_axis_out_tdata[23:16]  = (r_rgba_format) ? r_rgb[15: 8] : r_rgb[23:16];
//assign  o_axis_out_tdata[15: 8]  = (r_rgba_format) ? r_rgb[ 7: 0] : r_rgb[15: 8];
//assign  o_axis_out_tdata[ 7: 0]  = (r_rgba_format) ? r_alpha      : r_rgb[ 7: 0];

//assign  o_axis_out_tdata[31:24]  = r_alpha;
//assign  o_axis_out_tdata[23:16]  = r_rgb[ 7: 0]; //Set Green -> Got Blue
//assign  o_axis_out_tdata[15: 8]  = r_rgb[15: 8]; //Set Blue -> Got Red
//assign  o_axis_out_tdata[ 7: 0]  = r_rgb[23:16]; //Set Red -> Got Green

assign  o_axis_out_tdata[31:24]  = r_alpha;
assign  o_axis_out_tdata[23:16]  = r_rgb[23:16]; //Red
assign  o_axis_out_tdata[15: 8]  = r_rgb[ 7: 0]; //Blue
assign  o_axis_out_tdata[ 7: 0]  = r_rgb[15: 8]; //Green

//assign  w_cb_width                    = (r_width >> 3);
assign  w_start_x = (r_ref_y0 < r_ref_y1) ?
                      r_ref_x0 :
                      ((r_ref_y0 == r_ref_y1) && (r_ref_x0 < r_ref_x1)) ? r_ref_x0 : r_ref_x1;
assign  w_end_x   = (r_ref_y0 < r_ref_y1) ?
                      r_ref_x1 :
                      ((r_ref_y0 == r_ref_y1) && (r_ref_x0 < r_ref_x1)) ? r_ref_x1 : r_ref_x0;

assign  w_start_y = (r_ref_y0 < r_ref_y1) ?
                      r_ref_y0 :
                      ((r_ref_y0 == r_ref_y1) && (r_ref_x0 < r_ref_x1)) ? r_ref_y0 : r_ref_y1;

assign  w_end_y   = (r_ref_y0 < r_ref_y1) ?
                      r_ref_y1 :
                      ((r_ref_y0 == r_ref_y1) && (r_ref_x0 < r_ref_x1)) ? r_ref_y1 : r_ref_y0;

//always @ (x or y or w_axi_rst or r_mode or r_enable or r_frame_finished or r_anim_image_count or r_anim_x_dir or r_anim_y_dir) begin
always @ (x or y or w_axi_rst or r_mode or r_enable or r_frame_finished) begin
  if (w_axi_rst) begin
    r_rgb                       <=  0;
//    r_animate_pos_x             <=  0;
//    r_animate_pos_y             <=  0;
//    r_animate_width_x           <=  0;
//    r_animate_width_y           <=  0;
//    r_anim_image_count          <=  0;
//    r_anim_x_dir                <=  0;
//    r_anim_y_dir                <=  0;
  end
  else begin
    if (!r_enable) begin
//      r_animate_pos_x           <=  w_start_x;
//      r_animate_pos_y           <=  w_start_y;
//      r_animate_width_x         <=  (w_end_x - w_start_x);
//      r_animate_width_y         <=  (w_end_y - w_start_y);
//      r_anim_x_dir              <=  r_animate_x_dir;
//      r_anim_y_dir              <=  r_animate_y_dir;
    end
    case (r_mode)
      MODE_BLACK: begin
        r_rgb[23:0]             <=  `COLOR_BLACK;
      end
      MODE_WHITE: begin
        r_rgb[23:0]             <=  `COLOR_WHITE;
      end
      MODE_RED: begin
        r_rgb[23:0]             <=  `COLOR_RED;
      end
      MODE_GREEN: begin
        r_rgb[23:0]             <=  `COLOR_GREEN;
      end
      MODE_BLUE: begin
        r_rgb[23:0]             <=  `COLOR_BLUE;
      end
      MODE_CB: begin
        case (r_cm_index)
          0: begin
            r_rgb[23:0]         <=  `COLOR_BLACK;
          end
          1: begin
            r_rgb[23:0]         <=  `COLOR_RED;
          end
          2: begin
            r_rgb[23:0]         <=  `COLOR_ORANGE;
          end
          3: begin
            r_rgb[23:0]         <=  `COLOR_YELLOW;
          end
          4: begin
            r_rgb[23:0]         <=  `COLOR_GREEN;
          end
          5: begin
            r_rgb[23:0]         <=  `COLOR_BLUE;
          end
          6: begin
            r_rgb[23:0]         <=  `COLOR_PURPLE;
          end
          7: begin
            r_rgb[23:0]         <=  `COLOR_WHITE;
          end
          default: begin
            r_rgb[23:0]         <=  `COLOR_GRAY;
          end
        endcase
      end
      MODE_SQUARE: begin
        if ((x >= w_start_x) && (y >= w_start_y) && (x <= w_end_x) && (y <= w_end_y)) begin
          r_rgb                 <=  r_ref_fg_color[23:0];
        end
        else begin
          r_rgb                 <=  r_ref_bg_color[23:0];
        end
      end
      MODE_RAMP: begin
        r_rgb                   <=  {y[7:0], 8'h00, x[7:0]};
      end
//      MODE_ANIMATE: begin
//        if ((x >=  r_animate_pos_x) &&
//            (y >=  r_animate_pos_y) &&
//            (x <= (r_animate_pos_x + r_animate_width_x)) &&
//            (y <= (r_animate_pos_y + r_animate_width_y))) begin
//          r_rgb                 <=  r_ref_fg_color[23:0];
//        end
//        else begin
//          r_rgb                 <=  r_ref_bg_color[23:0];
//        end
//        if (r_frame_finished) begin
//          if (r_animate_en) begin
//            if (r_anim_image_count >= r_animate_count_div) begin
//              if (r_anim_x_dir) begin // Positive ->
//                if ((r_animate_pos_x + r_animate_width_x) >= r_width) begin //Collision
//                else
//
//              end
//              else begin  //Negative <-
//              end
//              if (r_anim_y_dir) begin //Positive V
//              end
//              else begin              //Negative ^
//              end
//              r_anim_image_count <=  0;
//            end
//            else begin
//              r_anim_image_count <=  r_anim_image_count + 1;
//            end
//          end
//        end
//      end
      default: begin
        r_rgb                   <=  {8'h00, 8'h00, 8'h00};
      end
    endcase

  end
end
endmodule
