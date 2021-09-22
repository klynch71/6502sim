/*
*                                    PROGRAM_COUNTER_REGISTER
*
*                                   Copyright (c) 2021 Kevin Lynch
*                             This file is licensed under the MIT license
*
* Program counter register
* The program counter register loads data from the increment logic
* on clk_2.  It's contents are always output on pc_out.
* The contents can optionally be sent to the addr bus and sb bus.
*/
module program_counter_register(load, data_in, enable_addr, enable_db, pc_out, addr_out, db_out);
  input load;                //load register from data_in
  input [7:0] data_in;       //data from increment logic
  input enable_addr;         //place contents onto address data bus
  input enable_db;           //place contents onto internal data bus
  output reg [7:0] pc_out;   //driven with register contents
  output [7:0] addr_out;     //driven with register contents when enable_addr is high
  output [7:0] db_out;       //driven with register contents when enable_db is high

  assign addr_out = (enable_addr) ? pc_out : 8'bz;
  assign db_out = (enable_db) ? pc_out : 8'bz;

  //load register if load is address_bus_high_register
  always @(load or data_in)
    if (load)
      pc_out <= data_in;

endmodule
