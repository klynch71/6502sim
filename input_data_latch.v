/*
*                                           INPUT_DATA_LATCH
*
*                                   Copyright (c) 2021 Kevin Lynch
*                             This file is licensed under the MIT license
*
*
* a tri-state latch with three outputs each enabled with their own enable
*
* Takes the data bus and distributes to any of;
*     - internal data bus via enable_db
*     - address data bus low via enable_adl
*     - address data bus high via enable_adh
*/
module input_data_latch(clk_1, clk_2, in_data, enable_db, enable_adl, enable_adh, out_db, out_adl, out_adh);
  input clk_1;
  input clk_2;
  input [7:0] in_data;
  input enable_db;
  input enable_adl;
  input enable_adh;
  output [7:0] out_db;
  output [7:0] out_adl;
  output [7:0] out_adh;

  assign out_db = (enable_db) ? dl_register : 8'bz;
  assign out_adl = (enable_adl) ? dl_register: 8'bz;
  assign out_adh = (enable_adh) ? dl_register : 8'bz;

  reg [7:0] in_data_c2;
  reg [7:0] dl_register;

  /*
   * latch input on clk_2 then clk_1
   */
   always @(clk_2 or in_data)
      if (clk_2)
        in_data_c2 <= in_data;

   always @(clk_1 or in_data)
    if (clk_1)
      dl_register <= in_data_c2;

endmodule
