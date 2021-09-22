/*
 *                                            ADDER_HOLD_REGISTER
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 *  The adder hold register holds the output of the ALU and inverts its value.
 *  It has two output busses: adl & db.
 *  The db bus can be partially driven by two enable lines: enable_sb06 and enable_sb7.
 *  enable_sb06 will drive bits 0-6 of the special bus, while enable_sb7 will drive only bit 7.
 *
 */
module adder_hold_register(clk, enable_adl, enable_sb06, enable_sb7, data_in, adl, sb, adder_hold_reg);
  input clk;           //clk_2
  input enable_adl;    //net: 1015; aka add_adl
  input enable_sb06;   //net: 129; aka add_sb06
  input enable_sb7;    //net: 214; aka add_sb17
  input [7:0] data_in; //data from alu
  output [7:0] adl;    //address data low bus
  output [7:0] sb;     //special bus
  output reg [7:0] adder_hold_reg; //output to decimal adjust adders

  assign adl = (enable_adl) ? adder_hold_reg : 8'bz;
  assign sb[7] = (enable_sb7) ? adder_hold_reg[7] : 1'bz;
  assign sb[6:0] = (enable_sb06) ? adder_hold_reg[6:0] : 7'bz;

  always @(clk or data_in)
    begin
      if (clk)
          adder_hold_reg <= ~data_in;  //alu outputs are opposite value of true result so we invert here
    end
endmodule
