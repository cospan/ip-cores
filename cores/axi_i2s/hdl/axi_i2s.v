
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


`define CTL_BIT_ENABLE            0
`define CTL_BIT_ENABLE_WAVE       1
`define CTL_BIT_ENABLE_INTERRUPT  2
`define CTL_BIT_WAVE_SEL          3


module axi_i2s #(
  parameter AUDIO_CLOCK_FREQ    = 100000000,
  parameter ADDR_WIDTH          = 16,
  parameter INVERT_AXI_RESET    = 1
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

  /*************************************************************************
  * AXI Streams: Audio Channel
  *************************************************************************/
  input                               axis_audio_clk,
  input                               axis_audio_rst,
  output                              axis_audio_tvalid,
  input                               axis_audio_tready,
  output      [ 3: 0]                 axis_audio_tid,
  output      [31: 0]                 axis_audio_tdata,
  output                              axis_audio_tlast

);
//local parameters

//Address Map
localparam  REG_CONTROL         = 0 << 2;
localparam  REG_STATUS          = 1 << 2;
localparam  REG_CLOCK_RATE      = 2 << 2;
localparam  REG_CLOCK_DIVIDER   = 3 << 2;
localparam  REG_AUDIO_RATE      = 4 << 2;
localparam  REG_AUDIO_BITS      = 5 << 2;
localparam  REG_AUDIO_CHANNELS  = 6 << 2;

localparam  REG_VERSION         = 7 << 2;

localparam  MAX_ADDR = REG_VERSION;

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


//TEMP DATA, JUST FOR THE DEMO
wire  [31: 0]               w_version;
wire  [15:0]                audio_sample;

reg                         r_en      = 0;
reg                         r_en_wave = 0;
reg                         r_en_interrupt;
reg                         r_post_fifo_wave;

reg                         r_audio_rate;
reg                         r_audio_bits;
reg                         r_audio_channels;




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


audio_axi_stream_transmitter audio_tx (
  .audio_clk          (i_axi_clk            ),
  .audio_reset        (w_axi_rst            ),
  .audio_sample       (audio_sample         ),
                                            
  .ctrl_audio_en      (r_en                 ),
                                            
  .axis_audio_clk     (axis_audio_clk       ),
  .axis_audio_rst     (axis_audio_rst       ),
  .axis_audio_tid     (axis_audio_tid       ),
  .axis_audio_tvalid  (axis_audio_tvalid    ),
  .axis_audio_tready  (axis_audio_tready    ),
  .axis_audio_tdata   (axis_audio_tdata     ),
  .axis_audio_tlast   (axis_audio_tlast     )

);

reg           r_wave_sel;
reg   [7:0]   r_wave_pos;
wire  [7:0]   wavelength;


waveform w(
  .sel           (r_wave_sel         ),
  .pos           (r_wave_pos         ),
  .wavelength    (wavelength         ),
  .value         (audio_sample       )
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
  r_reg_in_ack                  <=  0;
  r_reg_out_rdy                 <=  0;
  r_reg_invalid_addr            <=  0;

  if (w_axi_rst) begin
    r_reg_out_data              <=  0;

    //Reset the temporary Data
    r_en                        <=  0;
    r_en_interrupt              <=  0;
    r_wave_sel                  <=  0;

    r_audio_rate                <=  0;
    r_audio_bits                <=  0;
    r_audio_channels            <=  0;
    r_wave_pos                  <=  0;
    r_en_wave                   <=  0;

  end
  else begin

    if (w_reg_in_rdy) begin
      //From master
      case (w_reg_address)
        REG_CONTROL: begin
          //$display("Incoming data on address: 0x%h: 0x%h", w_reg_address, w_reg_in_data);
          //r_control                       <=  w_reg_in_data;
          r_en                            <=  w_reg_in_data[`CTL_BIT_ENABLE];
          r_en_wave                       <=  w_reg_in_data[`CTL_BIT_ENABLE_WAVE];
          r_en_interrupt                  <=  w_reg_in_data[`CTL_BIT_ENABLE_INTERRUPT];
          r_wave_sel                      <=  w_reg_in_data[`CTL_BIT_WAVE_SEL];
        end
        REG_STATUS: begin
        end
        REG_CLOCK_RATE: begin
        end
        REG_CLOCK_DIVIDER: begin
        end
        REG_AUDIO_RATE: begin
        end
        REG_AUDIO_BITS: begin
        end
        REG_AUDIO_CHANNELS: begin
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
          r_reg_out_data                            <= 32'h0;
          r_reg_out_data[`CTL_BIT_ENABLE]           <= r_en;
          r_reg_out_data[`CTL_BIT_ENABLE_WAVE]      <= r_en_wave;
          r_reg_out_data[`CTL_BIT_ENABLE_INTERRUPT] <= r_en_interrupt;
          r_reg_out_data[`CTL_BIT_WAVE_SEL]         <= r_wave_sel;
        end
        REG_STATUS: begin
          r_reg_out_data                  <= 32'h0;
        end
        REG_CLOCK_RATE: begin
        end
        REG_CLOCK_DIVIDER: begin
        end
        REG_AUDIO_RATE: begin
        end
        REG_AUDIO_BITS: begin
        end
        REG_AUDIO_CHANNELS: begin
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


    if (r_en_wave) begin
      if (r_wave_pos < (wavelength - 1)) begin
        r_wave_pos                      <=  r_wave_pos + 1;
      end
      else begin
        r_wave_pos                      <=  0;
      end
    end
    else begin
        r_wave_pos                      <=  0;
    end
  end
end

endmodule
