/*
 *                                          XY_INDEX_REGISTER
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 *  The x and y index registers are tri-state latches similar to a 74LS373
 *
 * Data is loaded when the load input is 1.
 * Loaded data is passed to the output when bus_enable is 1, otherwise the output is z.
 * The reg_value is an output so that it can be renamed outside this module in order to
 * easily distinguish between the x and y register values.
 */
module xy_index_register(load, bus_enable, in, out, reg_value);

  parameter WIDTH = 8;

  input load;
  input bus_enable;
  input [WIDTH-1: 0] in;
  output [WIDTH-1: 0] out;
  output reg [WIDTH-1: 0] reg_value;

  assign out = (bus_enable) ? reg_value : {WIDTH{1'bz}};

  always @(load or in)
    if (load)
      reg_value <= in;

endmodule
