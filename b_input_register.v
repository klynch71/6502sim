/*
 *                                                 B_INPUT_REGISTER
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 *  The b-side register has three input sources and one always-on output.
 *  The three input sources are: a) the inverted internal data bus, b) the internal data bus,
 *  and c) the address low data bus.
 */
module b_input_register(load_not_db, load_db, load_adr, not_db, db, adr, b_out);
  input load_not_db;      //net: 1068; not_db_add
  input load_db;          //net: 859; db_add
  input load_adr;         //net: 910; adl_add
  input [7:0] not_db;     //inverted values of db
  input [7:0] db;         //internal data bus
  input [7:0] adr;        //address data low bus
  output reg [7:0] b_out; //goes to the alu

  always @(*)
    begin
      if (load_not_db)
        b_out <= not_db;
      else if (load_db)
        b_out <= db;
      else if (load_adr)
        b_out <= adr;
    end
endmodule
