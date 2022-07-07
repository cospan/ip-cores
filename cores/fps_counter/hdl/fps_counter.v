
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
`define VERSION_PAD_RANGE         15:0

`define BIT_CTRL_RESET_FRAME_COUNTS 0

`define BIT_STS_FRAME_DETECTED      0
`define BIT_STS_ROWS_NOT_EQUAL      1
`define BIT_STS_LINES_NOT_EQUAL     2

module fps_counter #(
  parameter ADDR_WIDTH          = 16,
  parameter CLOCK_PERIOD        = 100000000,
  parameter IMG_WIDTH_MAX       = 16,
  parameter IMG_HEIGHT_MAX      = 16,

  parameter FPS_COUNT_MAX       = 16,

  parameter AXIS_DATA_WIDTH     = 8,
  parameter AXIS_KEEP_WIDTH     = (AXIS_DATA_WIDTH / 8),
  parameter AXIS_DATA_USER_WIDTH= 0,

  parameter INVERT_AXI_RESET    = 1
)(
  input                                   i_axi_clk,
  input                                   i_axi_rst,

  //Write Address Channel
  input                                   i_awvalid,
  input       [ADDR_WIDTH - 1: 0]         i_awaddr,
  output                                  o_awready,

  //Write Data Channel
  input                                   i_wvalid,
  output                                  o_wready,
  input       [31: 0]                     i_wdata,
  input       [3:0]                       i_wstrb,

  //Write Response Channel
  output                                  o_bvalid,
  input                                   i_bready,
  output      [1:0]                       o_bresp,

  //Read Address Channel
  input                                   i_arvalid,
  output                                  o_arready,
  input       [ADDR_WIDTH - 1: 0]         i_araddr,

  //Read Data Channel
  output                                  o_rvalid,
  input                                   i_rready,
  output      [1:0]                       o_rresp,
  output      [31: 0]                     o_rdata,


  //Input AXI Stream
  input  wire                             i_axis_in_tuser,
  input  wire                             i_axis_in_tvalid,
  input  wire                             i_axis_in_tready,
  input  wire                             i_axis_in_tlast,
  input  wire   [AXIS_DATA_WIDTH - 1:0]   i_axis_in_tdata
);
//local parameters

//Address Map
localparam  REG_CONTROL           = 0 << 2;
localparam  REG_STATUS            = 1 << 2;
localparam  REG_CLK_PERIOD        = 2 << 2;
localparam  REG_TOTAL_FRAMES      = 3 << 2;
localparam  REG_FRAMES_PER_SECOND = 4 << 2;
localparam  REG_LINES_PER_FRAME   = 5 << 2;
localparam  REG_PIXELS_PER_ROW    = 6 << 2;




localparam  REG_VERSION           = 7 << 2;
localparam  MAX_ADDR = REG_VERSION;

//registers/wires

//User Interface
wire                        w_axi_rst;
wire                        w_new_frame_stb;
reg                         r_axis_tuser_prev;
wire                        w_axis_rst;
wire  [ADDR_WIDTH - 1: 0]   w_reg_address;
reg                         r_reg_invalid_addr         = 0;

wire                        w_reg_in_rdy;
reg                         r_reg_in_ack               = 0;
wire  [31: 0]               w_reg_in_data;

wire                        w_reg_out_req;
reg                         r_reg_out_rdy              = 0;
reg   [31: 0]               r_reg_out_data             = 0;


//TEMP DATA, JUST FOR THE DEMO
wire  [31: 0]               w_version;
reg   [31: 0]               r_clock_period             = 0;
reg   [31: 0]               r_counts_per_second        = 0;
reg   [31: 0]               r_total_frame_count        = 0;
reg   [31: 0]               r_frames_per_second        = 0;


reg   [IMG_WIDTH_MAX - 1: 0]  r_image_width_count      = 0;
reg   [IMG_WIDTH_MAX - 1: 0]  r_image_width_count_out  = 0;

reg   [IMG_HEIGHT_MAX - 1: 0] r_image_height_count     = 0;
reg   [IMG_HEIGHT_MAX - 1: 0] r_image_height_count_out = 0;

reg   [IMG_HEIGHT_MAX - 1: 0] r_fps_count              = 0;
reg   [IMG_HEIGHT_MAX - 1: 0] r_fps_count_out          = 0;

reg                           r_rows_not_equal         = 0;
reg                           r_lines_not_equal        = 0;
reg                           r_new_frame              = 0;
reg                           r_frame_detected         = 0;

wire                          w_valid_pixel_stb;
wire                          w_valid_line_stb;

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

//asynchronous logic

assign w_axi_rst                      = INVERT_AXI_RESET  ? ~i_axi_rst  : i_axi_rst;
assign w_version[`MAJOR_RANGE]        = `MAJOR_VERSION;
assign w_version[`MINOR_RANGE]        = `MINOR_VERSION;
assign w_version[`REVISION_RANGE]     = `REVISION;
assign w_version[`VERSION_PAD_RANGE]  = 0;


assign w_new_frame_stb                = i_axis_in_tuser & !r_axis_tuser_prev;
assign w_valid_pixel_stb              = i_axis_in_tvalid & i_axis_in_tready;
assign w_valid_line_stb               = i_axis_in_tvalid & i_axis_in_tready & i_axis_in_tlast;




//synchronous logic
always @ (posedge i_axi_clk) begin
  //De-assert
  r_reg_in_ack                            <= 0;
  r_reg_out_rdy                           <= 0;
  r_reg_invalid_addr                      <= 0;
  r_new_frame                             <= 0;

  r_axis_tuser_prev                       <= i_axis_in_tuser;

  if (w_axi_rst) begin
    r_reg_out_data                        <= 0;

    //Reset the temporary Data
    r_clock_period                        <= CLOCK_PERIOD;
    r_counts_per_second                   <= 0;

    r_axis_tuser_prev                     <= 0;
    r_rows_not_equal                      <= 0;
    r_lines_not_equal                     <= 0;
    r_frame_detected                      <= 0;
    r_total_frame_count                   <= 0;
    r_fps_count                           <= 0;
    r_fps_count_out                       <= 0;

    r_image_width_count                   <= 0;
    r_image_width_count_out               <= 0;

    r_image_height_count                  <= 0;
    r_image_height_count_out              <= 0;


  end
  else begin

    if (w_reg_in_rdy) begin
      //From master
      case (w_reg_address)
        REG_CONTROL: begin
          //$display("Incoming data on address: 0x%h: 0x%h", w_reg_address, w_reg_in_data);
          if (w_reg_in_data[`BIT_CTRL_RESET_FRAME_COUNTS])
            r_total_frame_count           <=  0;
        end
        REG_STATUS: begin
          r_frame_detected                <=  w_reg_in_data[`BIT_STS_FRAME_DETECTED]  ? 1'b0 : 1'b1;
          r_rows_not_equal                <=  w_reg_in_data[`BIT_STS_ROWS_NOT_EQUAL]  ? 1'b0 : r_rows_not_equal;
          r_lines_not_equal               <=  w_reg_in_data[`BIT_STS_LINES_NOT_EQUAL] ? 1'b0 : r_lines_not_equal;
        end
        REG_VERSION: begin
          //$display("Incoming data on address: 0x%h: 0x%h", w_reg_address, w_reg_in_data);
        end
        REG_CLK_PERIOD: begin
          r_clock_period                  <= w_reg_in_data;
        end
        REG_TOTAL_FRAMES: begin
        end
        REG_FRAMES_PER_SECOND: begin
        end
        REG_LINES_PER_FRAME: begin
        end
        REG_PIXELS_PER_ROW: begin
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
        end
        REG_STATUS: begin
          r_reg_out_data                  <=  0;
          r_reg_out_data[`BIT_STS_FRAME_DETECTED]   <= r_frame_detected;
          r_reg_out_data[`BIT_STS_ROWS_NOT_EQUAL]   <= r_rows_not_equal;
          r_reg_out_data[`BIT_STS_LINES_NOT_EQUAL]  <= r_lines_not_equal;
        end
        REG_VERSION: begin
          r_reg_out_data                  <= w_version;
        end
        REG_CLK_PERIOD: begin
          r_reg_out_data                  <= r_clock_period;
        end
        REG_TOTAL_FRAMES: begin
          r_reg_out_data                  <= r_total_frame_count;
        end
        REG_FRAMES_PER_SECOND: begin
          r_reg_out_data                  <= r_fps_count_out;
        end
        REG_LINES_PER_FRAME: begin
          r_reg_out_data                  <= r_image_height_count_out;
        end
        REG_PIXELS_PER_ROW: begin
          r_reg_out_data                  <= r_image_width_count_out;
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



    //Frequency Counter
    if (r_counts_per_second < r_clock_period)
      r_counts_per_second                 <= r_counts_per_second + 1;
    else begin
      r_counts_per_second                 <= 0;
      r_fps_count_out                     <= r_fps_count;
      r_fps_count                         <= 0;
    end


    //Reset Vertical Lines (new frame)
    if (w_new_frame_stb) begin
      r_new_frame                         <=  1;
      r_frame_detected                    <=  1;
      if ((r_image_height_count_out != 0) && (r_image_height_count_out != r_image_height_count))
        r_lines_not_equal                 <=  1;
      r_image_height_count_out            <=  r_image_height_count;
      r_image_height_count                <=  0;
      r_total_frame_count                 <=  r_total_frame_count + 1;
      r_fps_count                         <=  r_fps_count + 1;
    end

    //New pixel
    if (w_valid_pixel_stb && ! w_valid_line_stb) begin
      r_image_width_count                 <=  r_image_width_count + 1;
    end

    //End of Line
    if (w_valid_line_stb) begin
      //Check if the previous line matches with the current line
      if ((r_image_width_count_out != 0) && (r_image_width_count_out != (r_image_width_count + 1)))
        r_rows_not_equal                  <=  1;

      r_image_width_count_out             <=  r_image_width_count + 1;
      r_image_width_count                 <=  0;

      r_image_height_count                <=  r_image_height_count + 1;
    end

  end
end


endmodule
