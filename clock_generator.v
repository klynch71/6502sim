/*
 *                                            CLOCK_GENERATOR
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 * generate two, non-overlapping clocks from the input clock.
 * lower case versions (clk_1 and clk_2) are used internally by the cpu.
 * CLK_1_OUT and CLK_2_OUT are output pins on the 6502
 */
module clock_generator(CLK_IN, clk_1, clk_2, CLK_1_OUT, CLK_2_OUT);
  input CLK_IN;
  output clk_1;  //net: 710; opposite of clk_in
  output clk_2;  //net: 943; same as clk_in
  output CLK_1_OUT; //pad: 1163
  output CLK_2_OUT; //pad: 421

  assign clk_1 = (clk_2 == 1'bz) ? ~CLK_IN : ~CLK_IN & ~clk_2; //clk1 is opposite of clk_in
  assign clk_2 = (clk_1 == 1'bz) ? CLK_IN : CLK_IN & ~clk_1;   //clk2 is the same as clk_n

  assign CLK_1_OUT = clk_1;
  assign CLK_2_OUT = clk_2;

endmodule
