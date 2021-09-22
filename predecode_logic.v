/*
 *                                            PREDECODE_LOGIC
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 * The Predecode Logic block in the Hanson block diagram of the 6502 cpu.
 *
 * The predecode block has three jobs:
 *   1) indicate if an opcode is one cycle via the implied output
 *   2) indicate if an opcde is two cycles via the tz_pre_n output
 *   3) pass the opcode to the instruction register or pass all zeros if clear_ir is high.
 *
 * clear_ir does not actually clear the instruction register, but instead clears
 * the input to the instruction register which may or may not be latched by the instruction register.
 *
 * Note: the Hanson block diagram shows Assert Interrupt Control as an input to the predecode logic block,
 * but really clear_ir is used.  Assert Interrupt Control shown as ~(res_g | int_g) in the diagram is
 * called b_out_n in our code and is used as an input to clear_ir in the random control logic block.
 *
 */
module predecode_logic(clk_1, aic_n, fetch, pd, ir, tz_pre_n, implied);
  input  clk_1;
  input  aic_n;          //net: 827; assert interrupt control - break in progress
  input  fetch;          //net: 879; fetch instruction
  input  [7:0] pd;       //the data to decode from the predecode register
  output [7:0] ir;       //the opcode to load into the instruction register
  output reg tz_pre_n;   //net: 792; set low when the opcode is a two cycle opcode
  output implied;        //net: 1019; set high when the opcode has implied addressing and therfore no oeprands

  //clear the instruction if either aic_n or clear is active; otherwise pass the predecode register data
  wire clear_ir = ~(aic_n & fetch); //net: 1077
  assign ir = (clear_ir) ? 8'h00 : pd;

 /*
  * implied is active for implied instructions which are equal to the mask xxxxx10x0.
  * Implied instructions have no operands and lasts for two cycles.
  */
  assign implied = ir[3] & ~ir[2] & ~ir[0]; //net: 1019

 /*
  * two_cycle_n is active for two cycle opcodes which are:
  * xxx010x1, 1xx000x0 and xxxx10x0 (implied) except 0xx01000
  */
  wire mask_xxx0_10x1 = ~ir[4] & ir[3] & ~ir[2] & ir[0]; //net: 302
  wire mask_1xx0_00x0 = ir[7] & ~ir[4] & ~ir[3] & ~ir[2] & ~ir[0]; //net; 1294
  wire mask_0xx0_1000 = ~ir[7] & ~ir[4] & ir[3] & ~ir[2] & ~ir[1] & ~ir[0]; //net: 365
  wire two_cycle_n = ~(mask_xxx0_10x1 | mask_1xx0_00x0 | (implied & ~mask_0xx0_1000)); //net: 851

  /*
   * latch signals on clk_1
   */
   always @(two_cycle_n or clk_1)
     if (clk_1)
        tz_pre_n <= two_cycle_n;

endmodule
