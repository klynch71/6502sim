/*
*                                        INCREMENT_LOGIC
*
*                                   Copyright (c) 2021 Kevin Lynch
*                             This file is licensed under the MIT license
*
* Increment logic
* adds carry_in to data_in to create  data_out and carry_out
*/
module increment_logic(carry_in, data_in, data_out, carry_out);
  input carry_in;
  input [7:0] data_in;
  output [7:0] data_out;
  output carry_out;

  assign carry_out = carry_in & (data_in == 8'hFF); //overflow
  assign data_out = (carry_out) ? 0 : (data_in + carry_in);

endmodule
