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
 * Changes:     Who?    What?
 *  XX/XX/XXXX  XXX     XXXX
 */

`define CLOG2(x) \
   (x <= 2)     ? 1 :  \
   (x <= 4)     ? 2 :  \
   (x <= 8)     ? 3 :  \
   (x <= 16)    ? 4 :  \
   (x <= 32)    ? 5 :  \
   (x <= 64)    ? 6 :  \
   (x <= 128)   ? 7 :  \
   (x <= 256)   ? 8 :  \
   (x <= 512)   ? 9 :  \
   (x <= 1024)  ? 10:  \
   (x <= 2048)  ? 11 : \
   (x <= 4096)  ? 12 : \
   -1


`timescale 1ps / 1ps

module console_osd #(
  parameter                       CONSOLE_DEPTH     = 12,
  parameter                       IMAGE_WIDTH       = 640,
  parameter                       IMAGE_HEIGHT      = 480,
  parameter                       IMAGE_SIZE        = IMAGE_WIDTH * IMAGE_HEIGHT,
  parameter                       BUFFER_DEPTH      = (`CLOG2(IMAGE_WIDTH) + 1),
  parameter                       PIXEL_WIDTH       = 24,
  parameter                       FONT_FILE         = "fontdata.mif",
  parameter                       FONT_WIDTH        = 5,
  parameter                       FONT_HEIGHT       = 7
)(
  input                           clk,
  input                           rst,
  input                           i_enable,

  output                          o_idle,

  input    [PIXEL_WIDTH - 1: 0]   i_fg_color,
  input    [PIXEL_WIDTH - 1: 0]   i_bg_color,

  input                           i_cmd_stb,
  input    [31:0]                 i_cmd,

  input                           i_char_stb,
  input    [7:0]                  i_char,
  output                          o_wr_char_rdy,

  input                           i_clear_screen_stb,
  input                           i_alt_func_en,
  input    [2:0]                  i_tab_count,

  output                          o_clear_screen,
  input                           i_scroll_en,
  input                           i_scroll_up_stb,
  input                           i_scroll_down_stb,

  input                           i_start_frame_stb,

  //PPFIFO Output
  input                           i_block_fifo_clk,
  input                           i_block_fifo_rst,
  output                          o_block_fifo_rdy,
  input                           i_block_fifo_act,
  output    [23:0]                o_block_fifo_size,
  output    [PIXEL_WIDTH: 0]      o_block_fifo_data,  //Add an extra bit to communicate start of frame
  input                           i_block_fifo_stb,
  output    [3:0]                 o_state,
  output    [15:0]                o_pixel_count

);
//local parameters
localparam    IDLE                    = 0;
localparam    PREPARE_LINE            = 1;
localparam    PROCESS_LINE            = 2;
localparam    GET_CHAR                = 3;
localparam    FONT_MEM_READ_DELAY     = 4;
localparam    PROCESS_CHAR_START      = 5;
localparam    PROCESS_CHAR            = 6;

localparam    FONT_WIDTH_ADJ          = FONT_WIDTH  + 1;
localparam    FONT_HEIGHT_ADJ         = FONT_HEIGHT + 1;
localparam    FONT_SIZE               = FONT_WIDTH        * FONT_HEIGHT_ADJ;
localparam    CHAR_IMAGE_WIDTH        = IMAGE_WIDTH   / FONT_WIDTH_ADJ;
localparam    CHAR_IMAGE_HEIGHT       = IMAGE_HEIGHT  / FONT_HEIGHT_ADJ;
localparam    CHAR_IMAGE_SIZE         = CHAR_IMAGE_WIDTH  * CHAR_IMAGE_HEIGHT;

//registes/wires
reg         [3:0]                     state;

wire                                  w_write_rdy;
reg                                   r_write_act;
wire        [23:0]                    w_write_size;
reg                                   r_write_stb;
reg         [7:0]                     r_char;
reg                                   r_char_req_en;
wire        [PIXEL_WIDTH:0]           w_write_data;

reg                                   r_start_frame;
wire                                  w_start_frame;
reg         [PIXEL_WIDTH - 1: 0]      r_pixel_data;

reg         [31:0]                    r_pixel_count;
reg         [23:0]                    r_pixel_width_count;
reg         [23:0]                    r_pixel_height_count;

wire        [23:0]                    w_pixel;

wire        [(FONT_WIDTH_ADJ - 1):0]  w_char_data_map[0: ((1 << FONT_HEIGHT_ADJ) - 1)];




wire                                  w_char_rdy;
wire        [7:0]                     w_char;

wire        [FONT_SIZE - 1: 0]        w_font_data;
reg         [FONT_SIZE - 1: 0]        r_font_data;
reg         [FONT_HEIGHT_ADJ - 1:0]   r_font_height_count;
reg         [FONT_WIDTH_ADJ - 1:0]    r_font_width_count;
reg         [23:0]                    r_char_width_count;
reg         [23:0]                    r_char_height_count;
reg                                   r_read_frame_stb;

wire                                  w_font_padding;
wire                                  w_font_width_padding;
wire                                  w_font_height_padding;

//XXX Need to figure this out
wire                                  w_valid_char_pixel;
wire                                  w_invalid_hor_char;
wire                                  w_invalid_ver_char;
//wire                                  w_inactive;
wire                                  w_starved;


//*************** DEBUG ******************************************************

wire        [31: 0]  w_dbg_font_width      = FONT_WIDTH;
wire        [31: 0]  w_dbg_font_width_adj  = FONT_WIDTH_ADJ;
wire        [31: 0]  w_dbg_font_height     = FONT_HEIGHT;
wire        [31: 0]  w_dbg_font_height_adj = FONT_HEIGHT_ADJ;
wire        [31: 0]  w_dbg_image_size      = IMAGE_SIZE;
wire        [31: 0]  w_dbg_image_height    = IMAGE_HEIGHT;
wire        [31: 0]  w_dbg_image_width     = IMAGE_WIDTH;

wire        [31: 0]  w_dbg_char_image_width  = CHAR_IMAGE_WIDTH;
wire        [31: 0]  w_dbg_char_image_height = CHAR_IMAGE_HEIGHT;
wire        [31: 0]  w_dbg_char_image_size   = CHAR_IMAGE_SIZE;


wire        [5:0]    w_data_line0;
wire        [5:0]    w_data_line1;
wire        [5:0]    w_data_line2;
wire        [5:0]    w_data_line3;
wire        [5:0]    w_data_line4;
wire        [5:0]    w_data_line5;
wire        [5:0]    w_data_line6;
wire        [5:0]    w_data_line7;


//****************************************************************************

assign  o_pixel_count       = r_pixel_count[15:0];

assign  w_font_width_padding  = r_font_width_count > FONT_WIDTH;
assign  w_font_height_padding = r_font_height_count > FONT_HEIGHT;
assign  w_font_padding        = w_font_width_padding || w_font_height_padding;

assign  o_state             = state;

assign  w_invalid_hor_char  = (r_char_width_count  >= (CHAR_IMAGE_WIDTH ));
assign  w_invalid_ver_char  = (r_char_height_count >= (CHAR_IMAGE_HEIGHT));
assign  w_valid_char_pixel  = !w_invalid_hor_char && !w_invalid_ver_char;

//Font

//submodules
block_fifo #(
  .DATA_WIDTH           (PIXEL_WIDTH + 1      ),  //Add an extra bit to hold the 'frame sync' signal
  .ADDRESS_WIDTH        (BUFFER_DEPTH         )
)bf (

  .reset                (rst || i_block_fifo_rst  ),

  //write
  .write_clock          (clk                  ),
  .write_ready          (w_write_rdy          ),
  .write_activate       (r_write_act          ),
  .write_fifo_size      (w_write_size         ),
  .write_strobe         (r_write_stb          ),
  .write_data           (w_write_data         ),
  .starved              (w_starved            ),

  //read
  .read_clock           (i_block_fifo_clk     ),
  .read_strobe          (i_block_fifo_stb     ),
  .read_ready           (o_block_fifo_rdy     ),
  .read_activate        (i_block_fifo_act     ),
  .read_count           (o_block_fifo_size    ),
  .read_data            (o_block_fifo_data    )
);

character_buffer#(
  .CONSOLE_DEPTH        (CONSOLE_DEPTH        ),
  .FONT_WIDTH           (FONT_WIDTH_ADJ       ),
  .FONT_HEIGHT          (FONT_HEIGHT_ADJ      ),
  .CHAR_IMAGE_WIDTH     (CHAR_IMAGE_WIDTH     ),
  .CHAR_IMAGE_HEIGHT    (CHAR_IMAGE_HEIGHT    ),
  .CHAR_IMAGE_SIZE      (CHAR_IMAGE_WIDTH * CHAR_IMAGE_HEIGHT)
)cb (
  .clk                  (clk                  ),
  .rst                  (rst                  ),

  .i_alt_func_en        (i_alt_func_en        ),
  .i_clear_screen_stb   (i_clear_screen_stb   ),

  .i_tab_count          (i_tab_count          ),
  .i_char_stb           (i_char_stb           ),
  .i_char               (i_char               ),
  .o_wr_char_rdy        (o_wr_char_rdy        ),

  .i_read_frame_stb     (r_read_frame_stb     ),
  .i_char_req_en        (r_char_req_en        ),
  .o_char_rdy           (w_char_rdy           ),
  .o_char               (w_char               ),

  .o_clear_screen       (o_clear_screen       ),
  .i_scroll_en          (i_scroll_en          ),
  .i_scroll_up_stb      (i_scroll_up_stb      ),
  .i_scroll_down_stb    (i_scroll_down_stb    )
);

bram #(
  .DATA_WIDTH           (40                   ),
  .ADDR_WIDTH           (8                    ),
  .MEM_FILE             (FONT_FILE            ),
  .MEM_FILE_LENGTH      (256                  )
) font_buffer (
  .clk                  (clk                  ),
  .rst                  (rst                  ),
  .en                   (1'b1                 ),
  .we                   (1'b0                 ),
  .write_address        (8'h00                ),
  .data_in              (40'h0                ),
  .read_address         (r_char               ),  //Use the char data to get the font data
  .data_out             (w_font_data          )
);

//asynchronous logic
assign  w_write_data[23:0]  = w_pixel;
assign  w_write_data[24]    = r_start_frame;

generate
genvar y;
genvar x;

for (y = 0; y < FONT_HEIGHT_ADJ; y = y + 1) begin: FOR_HEIGHT
  for (x = 0; x < FONT_WIDTH_ADJ; x = x + 1) begin: FOR_WIDTH
    if (x < FONT_WIDTH) begin
      assign  w_char_data_map[y][x] = r_font_data[(((FONT_WIDTH - 1) - x) * 8) + y];
    end
    else begin
      assign  w_char_data_map[y][x] = 0;
    end
  end
end
endgenerate

assign  w_pixel               = (!w_valid_char_pixel || w_font_padding) ?
                                  i_bg_color :
                                  (w_char_data_map[r_font_height_count][r_font_width_count]) ?
                                    i_fg_color :
                                    i_bg_color;

assign  w_data_line0 = w_char_data_map[0];
assign  w_data_line1 = w_char_data_map[1];
assign  w_data_line2 = w_char_data_map[2];
assign  w_data_line3 = w_char_data_map[3];
assign  w_data_line4 = w_char_data_map[4];
assign  w_data_line5 = w_char_data_map[5];
assign  w_data_line6 = w_char_data_map[6];
assign  w_data_line7 = w_char_data_map[7];
assign  o_idle        = (state != IDLE);

//synchronous logic

//Construct a frame one line at a time.
always @ (posedge clk) begin
  r_write_stb                     <=  0;
  r_read_frame_stb                <=  0;
  if (rst) begin
    state                         <=  IDLE;
    r_write_act                   <=  0;
    r_start_frame                 <=  0;
    r_pixel_data                  <=  0;
    r_pixel_count                 <=  0;

    r_font_width_count            <=  0;
    r_font_height_count           <=  0;
    r_char_width_count            <=  0;
    r_char_height_count           <=  0;
    r_char                        <=  0;
    r_char_req_en                 <=  0;
    r_pixel_width_count           <=  0;
    r_pixel_height_count          <=  0;
  end
  else begin
    if ((r_write_stb == 1) && r_start_frame) begin
      r_start_frame               <=  0;
    end
    case (state)
      IDLE: begin
        r_pixel_count             <=  0;
        r_pixel_height_count      <=  0;
        r_pixel_width_count       <=  0;
        r_font_width_count        <=  0;
        r_font_height_count       <=  0;
        r_char_width_count        <=  0;
        r_char_height_count       <=  0;
        r_start_frame             <=  0;
        r_write_act               <=  0;
        //set the frame strobe signal to high
        if (i_start_frame_stb && i_enable && w_write_rdy && w_starved) begin
          r_read_frame_stb        <=  1;
          r_start_frame           <=  1;
          state                   <=  PREPARE_LINE;
        end
      end
      PREPARE_LINE: begin
        r_char_width_count        <=  0;
        r_pixel_width_count       <=  0;
        if (w_write_rdy && !r_write_act) begin
          r_write_act             <=  1;
          state                   <=  PROCESS_LINE;
        end
      end
      PROCESS_LINE: begin
        if (r_pixel_width_count < (IMAGE_WIDTH)) begin
          if (w_invalid_hor_char || w_invalid_ver_char) begin
            r_pixel_count         <=  r_pixel_count + 1;
            r_pixel_width_count   <=  r_pixel_width_count + 1;
            r_pixel_data          <=  i_bg_color;
            r_write_stb           <=  1;
          end
          else begin
            state                 <=  GET_CHAR;
          end
        end
        else begin
          if (r_pixel_height_count < (IMAGE_HEIGHT - 1)) begin
            //Release the FIFO, we reached the end of the line
            if (r_font_height_count < (FONT_HEIGHT_ADJ - 1)) begin
              r_font_height_count <= r_font_height_count + 1;
            end
            else begin
              r_char_height_count <=  r_char_height_count + 1;
              r_font_height_count <= 0;
            end
 	 	        r_pixel_height_count  <=  r_pixel_height_count + 1;
 	 	        r_write_act           <=  0;
            state                 <=  PREPARE_LINE;
          end
          else begin
            //Wrote all rows of the image
            state                 <=  IDLE;
          end
        end
      end
      GET_CHAR: begin
        r_char_req_en             <=  1;
        r_font_width_count        <=  0;
        if (w_char_rdy) begin
          r_char_req_en           <=  0;
          r_char                  <=  w_char; //Store the character locally
          state                   <=  FONT_MEM_READ_DELAY;
        end
      end
      FONT_MEM_READ_DELAY: begin
        state                     <=  PROCESS_CHAR_START;
      end
      PROCESS_CHAR_START: begin
        r_pixel_count             <=  r_pixel_count + 1;
        r_pixel_width_count       <=  r_pixel_width_count + 1;
        r_pixel_data              <=  w_pixel;
        r_write_stb               <=  1;
        state                     <=  PROCESS_CHAR;
      end
      PROCESS_CHAR: begin
        if (r_font_width_count < (FONT_WIDTH_ADJ - 1)) begin
          r_write_stb             <=  1;
          r_pixel_data            <=  w_pixel;
          r_pixel_count           <=  r_pixel_count + 1;
          r_font_width_count      <=  r_font_width_count + 1;
          r_pixel_width_count     <=  r_pixel_width_count + 1;
        end
        else begin
          r_char_width_count      <=  r_char_width_count  + 1;
          if (r_char_width_count < (CHAR_IMAGE_WIDTH - 1)) begin
            state                 <=  GET_CHAR;
          end
          else begin
            state                 <=  PROCESS_LINE;
          end
        end
      end
      default: begin
        state                     <= IDLE;
      end
    endcase
  end
end


endmodule
