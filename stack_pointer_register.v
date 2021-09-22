/*
*                                     STACK_POINTER_REGISTER
*
*                                   Copyright (c) 2021 Kevin Lynch
*                             This file is licensed under the MIT license
*
* The stack pointer register has one input from the special bus and
* two outputs: one to the special bus and one to the address data low bus.
* The stack pointer should be initialized as part of the code startup sequence.
*/
module stack_pointer_register(clk_2, load, s_s, s_sb, s_adl, sb_in, sb_out, adl_out);
  input clk_2;
  input load;           //load register from sb_in
  input s_s;            //short cut to immediately deliver input to output
  input s_sb;           //drive sb_out with register contents
  input s_adl;          //drive adl_out with register contents
  input [7:0] sb_in;    //data in from special bus
  output [7:0] sb_out;
  output [7:0] adl_out;

  reg [7:0] stack_reg;
  reg [7:0] output_reg;

  assign sb_out  = (s_sb) ? output_reg : 8'bz;
  assign adl_out = (s_adl) ? output_reg : 8'bz;

  //load stack pointer
  always @(load or sb_in)
    if (load)
      stack_reg <= sb_in;

  //latch output register
  always @(clk_2 or s_s or stack_reg)
    if (clk_2 | s_s)
      output_reg <= stack_reg;

endmodule
