/*
 *                                        A_INPUT_REGISTER
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 *  The a-side input register to the ALU.
 *  The a-side register has two input sources and one always-on output.
 *  The two input sources are: a) all zeros or b) special bus.
 */
module a_input_register(load_zero, load_sb, zero, sb, a_out);
  input load_zero;        //net: 984; aka zero_add
  input load_sb;          //net: 549; aka sb_add
  input [7:0] zero;       //all zeros
  input [7:0] sb;         //special data bus
  output reg [7:0] a_out; //goes to the alu

  always @(*)
    begin
      if (load_zero)
        a_out <= zero;
      else if (load_sb)
        a_out <= sb;
    end
endmodule
