// Copyright (c) 2012-2013 Ludvig Strigeus
// This program is GPL Licensed. See COPYING for the full license.

module len_ctr_lookup(input [4:0] X, output [7:0] Yout);
reg [6:0] Y;
always @*
begin
  case(X)
  0: Y = 7'h05;
  1: Y = 7'h7F;
  2: Y = 7'h0A;
  3: Y = 7'h01;
  4: Y = 7'h14;
  5: Y = 7'h02;
  6: Y = 7'h28;
  7: Y = 7'h03;
  8: Y = 7'h50;
  9: Y = 7'h04;
  10: Y = 7'h1E;
  11: Y = 7'h05;
  12: Y = 7'h07;
  13: Y = 7'h06;
  14: Y = 7'h0D;
  15: Y = 7'h07;
  16: Y = 7'h06;
  17: Y = 7'h08;
  18: Y = 7'h0C;
  19: Y = 7'h09;
  20: Y = 7'h18;
  21: Y = 7'h0A;
  22: Y = 7'h30;
  23: Y = 7'h0B;
  24: Y = 7'h60;
  25: Y = 7'h0C;
  26: Y = 7'h24;
  27: Y = 7'h0D;
  28: Y = 7'h08;
  29: Y = 7'h0E;
  30: Y = 7'h10;
  31: Y = 7'h0F;
  endcase
end
assign Yout = {Y, 1'b0};
endmodule

module square_chan(
  input             clk,
  input             ce,
  input             reset,
  input             sq2,
  input       [1:0] address,
  input       [7:0] data_in,
  input             write_to_apu,
  input             len_ctr_clock,
  input             env_clock,
  input             enabled,
  input       [7:0] len_ctr_in,
  output reg  [3:0] audio_sample,
  output            is_non_zero);
reg [7:0] len_ctr;

// Register 1
reg [1:0] duty;
reg env_loop, env_disable, env_do_reset;
reg [3:0] volume, envelope, env_divider;
wire len_ctr_halt = env_loop; // Aliased bit
assign is_non_zero = (len_ctr != 0);
// Register 2
reg sweep_enable, sweep_negate, sweep_reset;
reg [2:0] sweep_period, sweep_divider, sweep_shift;

reg [10:0] period;
reg [11:0] timer_ctr;
reg [2:0] seq_pos;
wire [10:0] shifted_period = (period >> sweep_shift);
wire [10:0] period_rhs = (sweep_negate ? (~shifted_period + {10'b0, sq2}) : shifted_period);
wire [11:0] new_sweep_period = period + period_rhs;
wire valid_freq = period[10:3] >= 8 && (sweep_negate || !new_sweep_period[11]);

always @(posedge clk) if (reset) begin
    len_ctr       <= 0;
    duty          <= 0;
    env_do_reset  <= 0;
    env_loop      <= 0;
    env_disable   <= 0;
    volume        <= 0;
    envelope      <= 0;
    env_divider   <= 0;
    sweep_enable  <= 0;
    sweep_negate  <= 0;
    sweep_reset   <= 0;
    sweep_period  <= 0;
    sweep_divider <= 0;
    sweep_shift   <= 0;
    period        <= 0;
    timer_ctr     <= 0;
    seq_pos       <= 0;
  end else if (ce) begin
  // Check if writing to the regs of this channel
  // NOTE: This needs to be done before the clocking below.
  if (write_to_apu) begin
    case(address)
    0: begin
//      if (sq2) $write("SQ0: duty=%d, env_loop=%d, env_disable=%d, volume=%d\n", data_in[7:6], data_in[5], data_in[4], data_in[3:0]);
      duty <= data_in[7:6];
      env_loop <= data_in[5];
      env_disable <= data_in[4];
      volume <= data_in[3:0];
    end
    1: begin
//      if (sq2) $write("SQ1: sweep_enable=%d, sweep_period=%d, sweep_negate=%d, sweep_shift=%d, data_in=%X\n", data_in[7], data_in[6:4], data_in[3], data_in[2:0], data_in);
      sweep_enable <= data_in[7];
      sweep_period <= data_in[6:4];
      sweep_negate <= data_in[3];
      sweep_shift <= data_in[2:0];
      sweep_reset <= 1;
    end
    2: begin
//      if (sq2) $write("SQ2: period=%d. data_in=%X\n", data_in, data_in);
      period[7:0] <= data_in;
    end
    3: begin
      // Upper bits of the period
//      if (sq2) $write("SQ3: periodUpper=%d len_ctr=%x data_in=%X\n", data_in[2:0], len_ctr_in, data_in);
      period[10:8] <= data_in[2:0];
      len_ctr <= len_ctr_in;
      env_do_reset <= 1;
      seq_pos <= 0;
    end
    endcase
  end


  // Count down the square timer...
  if (timer_ctr == 0) begin
    // Timer was clocked
    timer_ctr <= {period, 1'b0};
    seq_pos <= seq_pos - 1;
  end else begin
    timer_ctr <= timer_ctr - 1;
  end

  // Clock the length counter?
  if (len_ctr_clock && len_ctr != 0 && !len_ctr_halt) begin
    len_ctr <= len_ctr - 1;
  end

  // Clock the sweep unit?
  if (len_ctr_clock) begin
    if (sweep_divider == 0) begin
      sweep_divider <= sweep_period;
      if (sweep_enable && sweep_shift != 0 && valid_freq)
        period <= new_sweep_period[10:0];
    end else begin
      sweep_divider <= sweep_divider - 1;
    end
    if (sweep_reset)
      sweep_divider <= sweep_period;
    sweep_reset <= 0;
  end

  // Clock the envelope generator?
  if (env_clock) begin
    if (env_do_reset) begin
      env_divider <= volume;
      envelope <= 15;
      env_do_reset <= 0;
    end else if (env_divider == 0) begin
      env_divider <= volume;
      if (envelope != 0 || env_loop)
        envelope <= envelope - 1;
    end else begin
      env_divider <= env_divider - 1;
    end
  end

  // Length counter forced to zero if disabled.
  if (!enabled)
    len_ctr <= 0;
end

reg duty_enabled;
always @* begin
  // Determine if the duty is enabled or not
  case (duty)
  0: duty_enabled = (seq_pos == 7);
  1: duty_enabled = (seq_pos >= 6);
  2: duty_enabled = (seq_pos >= 4);
  3: duty_enabled = (seq_pos < 6);
  endcase

  // Compute the output
  if (len_ctr == 0 || !valid_freq || !duty_enabled)
    audio_sample = 0;
  else
    audio_sample = env_disable ? volume : envelope;
end
endmodule



module triangle_chan(input clk, input ce, input reset,
                    input [1:0] address,
                    input [7:0] data_in,
                    input write_to_apu,
                    input len_ctr_clock,
                    input lin_ctr_Clock,
                    input enabled,
                    input [7:0] len_ctr_in,
                    output [3:0] audio_sample,
                    output is_non_zero);
  //
  reg [10:0] period, timer_ctr;
  reg [4:0] seq_pos;
  //
  // Linear counter state
  reg [6:0] lin_ctr_period, lin_ctr;
  reg lin_ctrl, lin_halt;
  wire lin_ctr_zero = (lin_ctr == 0);
  //
  // Length counter state
  reg [7:0] len_ctr;
  wire len_ctr_halt = lin_ctrl; // Aliased bit
  wire len_ctr_zero = (len_ctr == 0);
  assign is_non_zero = !len_ctr_zero;
  //
  always @(posedge clk) if (reset) begin
    period <= 0;
    timer_ctr <= 0;
    seq_pos <= 0;
    lin_ctr_period <= 0;
    lin_ctr <= 0;
    lin_ctrl <= 0;
    lin_halt <= 0;
    len_ctr <= 0;
  end else if (ce) begin
    // Check if writing to the regs of this channel
    if (write_to_apu) begin
      case (address)
      0: begin
        lin_ctrl <= data_in[7];
        lin_ctr_period <= data_in[6:0];
      end
      2: begin
        period[7:0] <= data_in;
      end
      3: begin
        period[10:8] <= data_in[2:0];
        len_ctr <= len_ctr_in;
        lin_halt <= 1;
      end
      endcase
    end

    // Count down the period timer...
    if (timer_ctr == 0) begin
      timer_ctr <= period;
    end else begin
      timer_ctr <= timer_ctr - 1;
    end
    //
    // Clock the length counter?
    if (len_ctr_clock && !len_ctr_zero && !len_ctr_halt) begin
      len_ctr <= len_ctr - 1;
    end
    //
    // Clock the linear counter?
    if (lin_ctr_Clock) begin
      if (lin_halt)
        lin_ctr <= lin_ctr_period;
      else if (!lin_ctr_zero)
        lin_ctr <= lin_ctr - 1;
      if (!lin_ctrl)
        lin_halt <= 0;
    end
    //
    // Length counter forced to zero if disabled.
    if (!enabled)
      len_ctr <= 0;
      //
    // Clock the sequencer position
    if (timer_ctr == 0 && !len_ctr_zero && !lin_ctr_zero)
      seq_pos <= seq_pos + 1;
  end
  // Generate the output
  assign audio_sample = seq_pos[3:0] ^ {4{~seq_pos[4]}};
  //
endmodule


module noise_chan(
  input         clk,
  input         ce,
  input         reset,
  input   [1:0] address,
  input   [7:0] data_in,
  input         write_to_apu,
  input         len_ctr_clock,
  input         env_clock,
  input         enabled,
  input   [7:0] len_ctr_in,
  output  [3:0] audio_sample,
  output        is_non_zero);
  //
  // envelope volume
  reg env_loop, env_disable, env_do_reset;
  reg [3:0] volume, envelope, env_divider;
  // Length counter
  wire len_ctr_halt = env_loop; // Aliased bit
  reg [7:0] len_ctr;
  //
  reg short_mode;
  reg [14:0] shift = 1;

  assign is_non_zero = (len_ctr != 0);
  //
  // period stuff
  reg [3:0] period;
  reg [11:0] noise_period, timer_ctr;
  always @* begin
    case (period)
    0: noise_period = 12'h004;
    1: noise_period = 12'h008;
    2: noise_period = 12'h010;
    3: noise_period = 12'h020;
    4: noise_period = 12'h040;
    5: noise_period = 12'h060;
    6: noise_period = 12'h080;
    7: noise_period = 12'h0A0;
    8: noise_period = 12'h0CA;
    9: noise_period = 12'h0FE;
    10: noise_period = 12'h17C;
    11: noise_period = 12'h1FC;
    12: noise_period = 12'h2FA;
    13: noise_period = 12'h3F8;
    14: noise_period = 12'h7F2;
    15: noise_period = 12'hFE4;
    endcase
  end
  //
  always @(posedge clk) if (reset) begin
    env_loop <= 0;
    env_disable <= 0;
    env_do_reset <= 0;
    volume <= 0;
    envelope <= 0;
    env_divider <= 0;
    len_ctr <= 0;
    short_mode <= 0;
    shift <= 1;
    period <= 0;
    timer_ctr <= 0;
  end else if (ce) begin
    // Check if writing to the regs of this channel
    if (write_to_apu) begin
      case (address)
      0: begin
        env_loop <= data_in[5];
        env_disable <= data_in[4];
        volume <= data_in[3:0];
      end
      2: begin
        short_mode <= data_in[7];
        period <= data_in[3:0];
      end
      3: begin
        len_ctr <= len_ctr_in;
        env_do_reset <= 1;
      end
      endcase
    end
    // Count down the period timer...
    if (timer_ctr == 0) begin
      timer_ctr <= noise_period;
      // Clock the shift register. Use either
      // bit 1 or 6 as the tap.
      shift <= {
        shift[0] ^ (short_mode ? shift[6] : shift[1]),
        shift[14:1]};
    end else begin
      timer_ctr <= timer_ctr - 1;
    end
    // Clock the length counter?
    if (len_ctr_clock && len_ctr != 0 && !len_ctr_halt) begin
      len_ctr <= len_ctr - 1;
    end
    // Clock the envelope generator?
    if (env_clock) begin
      if (env_do_reset) begin
        env_divider <= volume;
        envelope <= 15;
        env_do_reset <= 0;
      end else if (env_divider == 0) begin
        env_divider <= volume;
        if (envelope != 0)
          envelope <= envelope - 1;
        else if (env_loop)
          envelope <= 15;
      end else
        env_divider <= env_divider - 1;
    end
    if (!enabled)
      len_ctr <= 0;
  end
  // Produce the output signal
  assign audio_sample =
    (len_ctr == 0 || shift[0]) ?
      0 :
      (env_disable ? volume : envelope);
endmodule

module dmc_chan(input clk, input ce, input reset,
               input odd_or_even,
               input [2:0] address,
               input [7:0] data_in,
               input write_to_apu,
               output [6:0] audio_sample,
               output dma_req,          // 1 when DMC wants DMA
               input dma_ack,           // 1 when DMC byte is on DmcData. Dmcdma_requested should go low.
               output [15:0] dma_addr,  // address DMC wants to read
               input [7:0] dma_data,    // Input data to DMC from memory.
               output Irq,
               output is_dmc_active);
  reg irq_enable;
  reg irq_active;
  reg loop;                      // looping enabled
  reg [3:0] freq;                // Current value of frequency register
  reg [6:0] dac = 0;             // Current value of DAC
  reg [7:0] audio_sampleaddress; // Base address of sample
  reg [7:0] audio_sampleLen;     // Length of sample
  reg [7:0] shift_reg;           // shift register
  reg [8:0] cycles;              // Down counter, is the period
  reg [14:0] address;            // 15 bits current address, 0x8000-0xffff
  reg [11:0] bytes_left;         // 12 bits bytes left counter 0 - 4081.
  reg [2:0] bits_used;           // Number of bits left in the audio_sample_buffer.
  reg [7:0] audio_sample_buffer; // Next value to be loaded into shift reg
  reg has_audio_sample_buffer;   // audio_sample buffer is nonempty
  reg has_shift_reg;             // shift reg is non empty
  reg [8:0] new_period[0:15];
  reg dmc_enabled;
  reg [1:0] ActivationDelay;
  assign dma_addr = {1'b1, address};
  assign audio_sample = dac;
  assign Irq = irq_active;
  assign is_dmc_active = dmc_enabled;

  assign dma_req = !has_audio_sample_buffer && dmc_enabled && !ActivationDelay[0];

  initial begin
    new_period[0] = 428;
    new_period[1] = 380;
    new_period[2] = 340;
    new_period[3] = 320;
    new_period[4] = 286;
    new_period[5] = 254;
    new_period[6] = 226;
    new_period[7] = 214;
    new_period[8] = 190;
    new_period[9] = 160;
    new_period[10] = 142;
    new_period[11] = 128;
    new_period[12] = 106;
    new_period[13] = 84;
    new_period[14] = 72;
    new_period[15] = 54;
  end
  // shift register initially loaded with 07
  always @(posedge clk) begin
    if (reset) begin
      irq_enable <= 0;
      irq_active <= 0;
      loop <= 0;
      freq <= 0;
      dac <= 0;
      audio_sampleaddress <= 0;
      audio_sampleLen <= 0;
      shift_reg <= 8'hff;
      cycles <= 439;
      address <= 0;
      bytes_left <= 0;
      bits_used <= 0;
      audio_sample_buffer <= 0;
      has_audio_sample_buffer <= 0;
      has_shift_reg <= 0;
      dmc_enabled <= 0;
      ActivationDelay <= 0;
    end else if (ce) begin
      if (ActivationDelay == 3 && !odd_or_even) ActivationDelay <= 1;
      if (ActivationDelay == 1) ActivationDelay <= 0;

      if (write_to_apu) begin
        case (address)
        0: begin  // $4010   il-- ffff   IRQ enable, loop, frequency index
            irq_enable <= data_in[7];
            loop <= data_in[6];
            freq <= data_in[3:0];
            if (!data_in[7]) irq_active <= 0;
          end
        1: begin  // $4011   -ddd dddd   DAC
            // This will get missed if the dac <= far below runs, that is by design.
            dac <= data_in[6:0];
          end
        2: begin  // $4012   aaaa aaaa   sample address
            audio_sampleaddress <= data_in[7:0];
          end
        3: begin  // $4013   llll llll   sample length
            audio_sampleLen <= data_in[7:0];
          end
        5: begin // $4015 write ---D NT21  Enable DMC (D)
            irq_active <= 0;
            dmc_enabled <= data_in[4];
            // If the DMC bit is set, the DMC sample will be restarted only if not already active.
            if (data_in[4] && !dmc_enabled) begin
              address <= {1'b1, audio_sampleaddress, 6'b000000};
              bytes_left <= {audio_sampleLen, 4'b0000};
              ActivationDelay <= 3;
            end
          end
        endcase
      end

      cycles <= cycles - 1;
      if (cycles == 1) begin
        cycles <= new_period[freq];
        if (has_shift_reg) begin
          if (shift_reg[0]) begin
            dac[6:1] <= (dac[6:1] != 6'b111111) ? dac[6:1] + 6'b000001 : dac[6:1];
          end else begin
            dac[6:1] <= (dac[6:1] != 6'b000000) ? dac[6:1] + 6'b111111 : dac[6:1];
          end
        end
        shift_reg <= {1'b0, shift_reg[7:1]};
        bits_used <= bits_used + 1;
        if (bits_used == 7) begin
          has_shift_reg <= has_audio_sample_buffer;
          shift_reg <= audio_sample_buffer;
          has_audio_sample_buffer <= 0;
        end
      end

      // Acknowledge DMA?
      if (dma_ack) begin
        address                    <= address + 1;
        bytes_left                 <= bytes_left - 1;
        has_audio_sample_buffer    <= 1;
        audio_sample_buffer        <= dma_data;
        if (bytes_left == 0) begin
          address                  <= {1'b1, audio_sampleaddress, 6'b000000};
          bytes_left               <= {audio_sampleLen, 4'b0000};
          dmc_enabled              <= loop;
          if (!loop && irq_enable)
            irq_active             <= 1;
        end
      end
    end
  end
endmodule

module apu_lookup_table(input clk, input [7:0] in_a, input [7:0] in_b, output [15:0] out);
  reg [15:0] lookup[0:511];
  reg [15:0] tmp_a, tmp_b;
  initial begin
    lookup[  0] =     0; lookup[  1] =   760; lookup[  2] =  1503; lookup[  3] =  2228;
    lookup[  4] =  2936; lookup[  5] =  3627; lookup[  6] =  4303; lookup[  7] =  4963;
    lookup[  8] =  5609; lookup[  9] =  6240; lookup[ 10] =  6858; lookup[ 11] =  7462;
    lookup[ 12] =  8053; lookup[ 13] =  8631; lookup[ 14] =  9198; lookup[ 15] =  9752;
    lookup[ 16] = 10296; lookup[ 17] = 10828; lookup[ 18] = 11349; lookup[ 19] = 11860;
    lookup[ 20] = 12361; lookup[ 21] = 12852; lookup[ 22] = 13334; lookup[ 23] = 13807;
    lookup[ 24] = 14270; lookup[ 25] = 14725; lookup[ 26] = 15171; lookup[ 27] = 15609;
    lookup[ 28] = 16039; lookup[ 29] = 16461; lookup[ 30] = 16876; lookup[256] =     0;
    lookup[257] =   439; lookup[258] =   874; lookup[259] =  1306; lookup[260] =  1735;
    lookup[261] =  2160; lookup[262] =  2581; lookup[263] =  2999; lookup[264] =  3414;
    lookup[265] =  3826; lookup[266] =  4234; lookup[267] =  4639; lookup[268] =  5041;
    lookup[269] =  5440; lookup[270] =  5836; lookup[271] =  6229; lookup[272] =  6618;
    lookup[273] =  7005; lookup[274] =  7389; lookup[275] =  7769; lookup[276] =  8147;
    lookup[277] =  8522; lookup[278] =  8895; lookup[279] =  9264; lookup[280] =  9631;
    lookup[281] =  9995; lookup[282] = 10356; lookup[283] = 10714; lookup[284] = 11070;
    lookup[285] = 11423; lookup[286] = 11774; lookup[287] = 12122; lookup[288] = 12468;
    lookup[289] = 12811; lookup[290] = 13152; lookup[291] = 13490; lookup[292] = 13825;
    lookup[293] = 14159; lookup[294] = 14490; lookup[295] = 14818; lookup[296] = 15145;
    lookup[297] = 15469; lookup[298] = 15791; lookup[299] = 16110; lookup[300] = 16427;
    lookup[301] = 16742; lookup[302] = 17055; lookup[303] = 17366; lookup[304] = 17675;
    lookup[305] = 17981; lookup[306] = 18286; lookup[307] = 18588; lookup[308] = 18888;
    lookup[309] = 19187; lookup[310] = 19483; lookup[311] = 19777; lookup[312] = 20069;
    lookup[313] = 20360; lookup[314] = 20648; lookup[315] = 20935; lookup[316] = 21219;
    lookup[317] = 21502; lookup[318] = 21783; lookup[319] = 22062; lookup[320] = 22339;
    lookup[321] = 22615; lookup[322] = 22889; lookup[323] = 23160; lookup[324] = 23431;
    lookup[325] = 23699; lookup[326] = 23966; lookup[327] = 24231; lookup[328] = 24494;
    lookup[329] = 24756; lookup[330] = 25016; lookup[331] = 25274; lookup[332] = 25531;
    lookup[333] = 25786; lookup[334] = 26040; lookup[335] = 26292; lookup[336] = 26542;
    lookup[337] = 26791; lookup[338] = 27039; lookup[339] = 27284; lookup[340] = 27529;
    lookup[341] = 27772; lookup[342] = 28013; lookup[343] = 28253; lookup[344] = 28492;
    lookup[345] = 28729; lookup[346] = 28964; lookup[347] = 29198; lookup[348] = 29431;
    lookup[349] = 29663; lookup[350] = 29893; lookup[351] = 30121; lookup[352] = 30349;
    lookup[353] = 30575; lookup[354] = 30800; lookup[355] = 31023; lookup[356] = 31245;
    lookup[357] = 31466; lookup[358] = 31685; lookup[359] = 31904; lookup[360] = 32121;
    lookup[361] = 32336; lookup[362] = 32551; lookup[363] = 32764; lookup[364] = 32976;
    lookup[365] = 33187; lookup[366] = 33397; lookup[367] = 33605; lookup[368] = 33813;
    lookup[369] = 34019; lookup[370] = 34224; lookup[371] = 34428; lookup[372] = 34630;
    lookup[373] = 34832; lookup[374] = 35032; lookup[375] = 35232; lookup[376] = 35430;
    lookup[377] = 35627; lookup[378] = 35823; lookup[379] = 36018; lookup[380] = 36212;
    lookup[381] = 36405; lookup[382] = 36597; lookup[383] = 36788; lookup[384] = 36978;
    lookup[385] = 37166; lookup[386] = 37354; lookup[387] = 37541; lookup[388] = 37727;
    lookup[389] = 37912; lookup[390] = 38095; lookup[391] = 38278; lookup[392] = 38460;
    lookup[393] = 38641; lookup[394] = 38821; lookup[395] = 39000; lookup[396] = 39178;
    lookup[397] = 39355; lookup[398] = 39532; lookup[399] = 39707; lookup[400] = 39881;
    lookup[401] = 40055; lookup[402] = 40228; lookup[403] = 40399; lookup[404] = 40570;
    lookup[405] = 40740; lookup[406] = 40909; lookup[407] = 41078; lookup[408] = 41245;
    lookup[409] = 41412; lookup[410] = 41577; lookup[411] = 41742; lookup[412] = 41906;
    lookup[413] = 42070; lookup[414] = 42232; lookup[415] = 42394; lookup[416] = 42555;
    lookup[417] = 42715; lookup[418] = 42874; lookup[419] = 43032; lookup[420] = 43190;
    lookup[421] = 43347; lookup[422] = 43503; lookup[423] = 43659; lookup[424] = 43813;
    lookup[425] = 43967; lookup[426] = 44120; lookup[427] = 44273; lookup[428] = 44424;
    lookup[429] = 44575; lookup[430] = 44726; lookup[431] = 44875; lookup[432] = 45024;
    lookup[433] = 45172; lookup[434] = 45319; lookup[435] = 45466; lookup[436] = 45612;
    lookup[437] = 45757; lookup[438] = 45902; lookup[439] = 46046; lookup[440] = 46189;
    lookup[441] = 46332; lookup[442] = 46474; lookup[443] = 46615; lookup[444] = 46756;
    lookup[445] = 46895; lookup[446] = 47035; lookup[447] = 47173; lookup[448] = 47312;
    lookup[449] = 47449; lookup[450] = 47586; lookup[451] = 47722; lookup[452] = 47857;
    lookup[453] = 47992; lookup[454] = 48127; lookup[455] = 48260; lookup[456] = 48393;
    lookup[457] = 48526; lookup[458] = 48658;
  end
  always @(posedge clk) begin
    tmp_a <= lookup[{1'b0, in_a}];
    tmp_b <= lookup[{1'b1, in_b}];
  end
  assign out = tmp_a + tmp_b;
endmodule


module APU(
input           clk,
input           ce,
input           reset,
input   [4:0]   address,        // APU address Line
input   [7:0]   data_in,        // Data to APU
output  [7:0]   data_out,       // Data from APU
input           write_to_apu,   // Writes to APU
input           read_from_apu,  // Reads from APU
input   [4:0]   audio_channels, // enabled audio channels
output  [15:0]  audio_sample,

output          dma_req,        // 1 when DMC wants DMA
input           dma_ack,        // 1 when DMC byte is on DmcData. Dmcdma_requested should go low.
output  [15:0]  dma_addr,       // address DMC wants to read
input   [7:0]   dma_data,       // Input data to DMC from memory.

output          odd_or_even,
output          IRQ);           // IRQ asserted

// Which channels are enabled?
reg [3:0] enabled;

// Output samples from the 4 channels
wire [3:0] sq1_audio_sample,sq2_audio_sample,tri_audio_sample,no_audio_sample;

// Output samples from the DMC channel
wire [6:0] dmc_audio_sample;
wire dmc_irq;
wire is_dmc_active;

// Generate internal memory write signals
wire apu_mw0 = write_to_apu && address[4:2]==0; // SQ1
wire apu_mw1 = write_to_apu && address[4:2]==1; // SQ2
wire apu_mw2 = write_to_apu && address[4:2]==2; // TRI
wire apu_mw3 = write_to_apu && address[4:2]==3; // NOI
wire apu_mw4 = write_to_apu && address[4:2]>=4; // DMC
wire apu_mw5 = write_to_apu && address[4:2]==5; // Control registers

wire sq1_non_zero, sq2_non_zero, tri_non_zero, no_i_non_zero;

// Common input to all channels
wire [7:0] len_ctr_in;
len_ctr_lookup len(data_in[7:3], len_ctr_in);


// Frame sequencer registers
reg frame_seq_mode;
reg [15:0] cycles;
reg clk_e, clk_l;
reg wrote_4017;
reg [1:0] irq_ctr;
reg internal_clock; // APU Differentiates between Even or Odd clocks
assign odd_or_even = internal_clock;


// Generate each channel
square_chan   Sq1(clk, ce, reset, 0,            address[1:0], data_in, apu_mw0, clk_l,            clk_e,      enabled[0], len_ctr_in,       sq1_audio_sample, sq1_non_zero);
square_chan   Sq2(clk, ce, reset, 1,            address[1:0], data_in, apu_mw1, clk_l,            clk_e,      enabled[1], len_ctr_in,       sq2_audio_sample, sq2_non_zero);
triangle_chan Tri(clk, ce, reset, address[1:0], data_in,      apu_mw2, clk_l,   clk_e,            enabled[2], len_ctr_in, tri_audio_sample, tri_non_zero);
noise_chan    Noi(clk, ce, reset, address[1:0], data_in,      apu_mw3, clk_l,   clk_e,            enabled[3], len_ctr_in, no_audio_sample,  no_i_non_zero);
dmc_chan      Dmc(clk, ce, reset, odd_or_even,  address[2:0], data_in, apu_mw4, dmc_audio_sample, dma_req,    dma_ack,    dma_addr,         dma_data,         dmc_irq,        is_dmc_active);

// Reading this register clears the frame interrupt flag (but not the DMC interrupt flag).
// If an interrupt flag was set at the same moment of the read, it will read back as 1 but it will not be cleared.
reg frame_interrupt, disable_frame_interrupt;


//mode 0: 4-step  effective rate (approx)
//---------------------------------------
//    - - - f      60 Hz
//    - l - l     120 Hz
//    e e e e     240 Hz


//mode 1: 5-step  effective rate (approx)
//---------------------------------------
//    - - - - -   (interrupt flag never set)
//    l - l - -    96 Hz
//    e e e e -   192 Hz


always @(posedge clk) if (reset) begin
  frame_seq_mode          <= 0;
  disable_frame_interrupt <= 0;
  frame_interrupt         <= 0;
  enabled                 <= 0;
  internal_clock          <= 0;
  wrote_4017              <= 0;
  clk_e                   <= 0;
  clk_l                   <= 0;
  cycles                  <= 4; // This needs to be 5 for proper power up behavior
  irq_ctr                 <= 0;
end else if (ce) begin
  frame_interrupt <= irq_ctr[1] ? 1 : (address == 5'h15 && read_from_apu || apu_mw5 && address[1:0] == 3 && data_in[6]) ? 0 : frame_interrupt;
  internal_clock  <= !internal_clock;
  irq_ctr         <= {irq_ctr[0], 1'b0};
  cycles          <= cycles + 1;
  clk_e           <= 0;
  clk_l           <= 0;
  if (cycles == 7457) begin
    clk_e         <= 1;
  end else if (cycles == 14913) begin
    clk_e         <= 1;
    clk_l         <= 1;
    clk_e         <= 1;
    clk_l         <= 1;
  end else if (cycles == 22371) begin
    clk_e         <= 1;
  end else if (cycles == 29829) begin
    if (!frame_seq_mode) begin
      clk_e       <= 1;
      clk_l       <= 1;
      cycles      <= 0;
      irq_ctr     <= 3;
      frame_interrupt <= 1;
    end
  end else if (cycles == 37281) begin
    clk_e         <= 1;
    clk_l         <= 1;
    cycles        <= 0;
  end

  // Handle one cycle delayed write to 4017.
  wrote_4017      <= 0;
  if (wrote_4017) begin
    if (frame_seq_mode) begin
      clk_e       <= 1;
      clk_l       <= 1;
    end
    cycles        <= 0;
  end

//  if (clk_e||clk_l) $write("%d: Clocking %s%s\n", cycles, clk_e?"E":" ", clk_l?"L":" ");

  // Handle writes to control registers
  if (apu_mw5) begin
    case (address[1:0])
    1: begin // Register $4015
      enabled <= data_in[3:0];
//      $write("$4015 = %X\n", data_in);
    end
    3: begin // Register $4017
      frame_seq_mode <= data_in[7]; // 1 = 5 frames cycle, 0 = 4 frames cycle
      disable_frame_interrupt <= data_in[6];

      // If the internal clock is even, things happen
      // right away.
      if (!internal_clock) begin
        if (data_in[7]) begin
          clk_e <= 1;
          clk_l <= 1;
        end
        cycles <= 0;
      end

      // Otherwise they get delayed one clock
      wrote_4017 <= internal_clock;
    end
    endcase
  end
end

apu_lookup_table lookup (clk,
                        (audio_channels[0] ? {4'b0, sq1_audio_sample} : 8'b0) +
                        (audio_channels[1] ? {4'b0, sq2_audio_sample} : 8'b0),
                        (audio_channels[2] ? {4'b0, tri_audio_sample} + {3'b0, tri_audio_sample, 1'b0} : 8'b0) +
                        (audio_channels[3] ? {3'b0, no_audio_sample, 1'b0} : 8'b0) +
                        (audio_channels[4] ? {1'b0, dmc_audio_sample} : 8'b0),
                        audio_sample);

wire frame_irq = frame_interrupt && !disable_frame_interrupt;

// Generate bus output
assign data_out = { dmc_irq,
                    frame_irq,
                    1'b0,
                    is_dmc_active,
                    no_i_non_zero,
                    tri_non_zero,
                    sq2_non_zero,
                    sq1_non_zero};

assign IRQ = frame_irq || dmc_irq;

endmodule
