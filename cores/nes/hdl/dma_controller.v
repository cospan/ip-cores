/*
Distributed under the MIT license.
Copyright (c) 2022 Dave McCoy (dave.mccoy@cospandesign.com)

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
 * Author: Dave McCoy
 * Description: Reads/Write to/from external memory
 *
 * Changes:     Who?    What?
 *  XX/XX/XXXX  XXX     XXXX
 */

// Sprite DMA Works as follows.
// When the CPU writes to $4014 DMA is initiated ASAP.
// DMA runs for 512 cycles, the first cycle it reads from address
// xx00 - xxFF, into a latch, and the second cycle it writes to $2004.

// Facts:
// 1) Sprite DMA always does reads on even cycles and writes on odd cycles.
// 2) There are 1-2 cycles of cpu_read=1 after cpu_read=0 until Sprite DMA starts (pause_cpu=1, aout_enable=0)
// 3) Sprite DMA reads the address value on the last clock of cpu_read=0
// 4) If DMC interrupts Sprite, then it runs on the even cycle, and the odd cycle will be idle (pause_cpu=1, aout_enable=0)
// 5) When DMC triggers && interrupts CPU, there will be 2-3 cycles (pause_cpu=1, aout_enable=0) before DMC DMA starts.



`timescale 1ps / 1ps

module dma_controller (
  input                     clk,
  input                     rst,
  input                     ce,
  input                     odd_cycle,
  input                     sprite_trigger,
  input                     dmc_trigger,
  input                     cpu_read,


	input  [7:0]              data_from_cpu, // Data written by CPU?
	input  [7:0]              data_from_ram, // Data read from RAM?
	input  [15:0]             dmc_dma_addr,  // DMC DMA Address
	output [15:0]             aout,          // Address to access
	output                    aout_enable,   // DMA controller wants bus control
	output                    read,          // 1 = read, 0 = write
	output [7:0]              data_to_ram,   // Value to write to RAM
	output                    dmc_ack,       // ACK the DMC DMA
	output                    pause_cpu      // CPU is pausede

);
//local parameters
//registes/wires
reg                         dmc_state;
reg  [1:0]                  spr_state;
reg  [7:0]                  sprite_dma_lastval;
reg  [15:0]                 sprite_dma_addr;     // sprite dma source addr
wire [8:0]                  new_sprite_dma_addr = sprite_dma_addr[7:0] + 8'h01;
//submodules
//asynchronous logic
assign pause_cpu    = (spr_state[0] || dmc_trigger);
assign dmc_ack      = (dmc_state == 1 && !odd_cycle);
assign aout_enable  = dmc_ack || spr_state[1];
assign read         = !odd_cycle;
assign data_to_ram  = sprite_dma_lastval;
assign aout         = dmc_ack ? dmc_dma_addr : !odd_cycle ? sprite_dma_addr : 16'h2004;

//synchronous logic
always @(posedge clk) if (rst) begin
	dmc_state          <= 0;
	spr_state          <= 0;
	sprite_dma_lastval <= 0;
	sprite_dma_addr    <= 0;
end else if (ce) begin
	if (dmc_state == 0 && dmc_trigger && cpu_read && !odd_cycle)  dmc_state <= 1;
	if (dmc_state == 1 && !odd_cycle)                             dmc_state             <= 0;

	if (sprite_trigger) begin sprite_dma_addr <= {data_from_cpu, 8'h00}; spr_state <= 1; end
	if (spr_state == 1 && cpu_read    && odd_cycle)               spr_state             <= 3;
	if (spr_state[1]   && !odd_cycle  && dmc_state == 1)          spr_state             <= 1;
	if (spr_state[1]   && odd_cycle)                              sprite_dma_addr[7:0]  <= new_sprite_dma_addr[7:0];
	if (spr_state[1]   && odd_cycle && new_sprite_dma_addr[8])    spr_state             <= 0;
	if (spr_state[1])                                             sprite_dma_lastval    <= data_from_ram;
end




endmodule
