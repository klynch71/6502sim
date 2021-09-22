/*
*                                 PROGRAM_COUNTER_SELECT_REGISTER
*
*                                   Copyright (c) 2021 Kevin Lynch
*                             This file is licensed under the MIT license
*
* The program counter select register can select to be loaded from either
* the program counter bus or the address data bus.  The output is then
* sent to the increment_logic.
*/
module program_counter_select_register(load_pc, load_adr, pc, adr, data_out);
  input load_pc;            //load register from pc
  input load_adr;           //load register from adr
  input [7:0] pc;           //program counter data
  input [7:0] adr;          //address data
  output reg [7:0] data_out; //register output

  //load register
  always @(load_pc or load_adr or pc or adr)
    if (load_pc)
      data_out <= pc;
    else if (load_adr)
      data_out <= adr;

endmodule
