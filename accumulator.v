/*
*                                            ACCUMULATOR
*
*                                   Copyright (c) 2021 Kevin Lynch
*                             This file is licensed under the MIT license
*
* the accumulator receives (optionally decimal adjusted) output from the special bus.
* The AC has one input from the special bus and two controlled outputs: one to the internal
* databus and one to the special bus
*/
module accumulator(load, ac_db, ac_sb, data_in, db_out, sb_out);
  input load; //net: 534; aka sb_ac; load special bus into Accumulator
  input ac_db; //net: 1331; drive internal data bus with accumulator contents
  input ac_sb; //net: 169; drive special bus with accumulator cotents.
  input [7:0] data_in; //special bus input
  output [7:0] db_out; //internal data bus output
  output [7:0] sb_out; //special bus output

  reg [7:0] accumulator_reg;

  assign db_out = (ac_db) ? accumulator_reg : 8'bz;
  assign sb_out = (ac_sb) ? accumulator_reg : 8'bz;

  always @(load or data_in)
    if (load)
      accumulator_reg <= data_in;
endmodule
