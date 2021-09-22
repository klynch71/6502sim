/*
 *                                  LATCH
 *
 *                        Copyright (c) 2021 Kevin Lynch
 *                This file is licensed under the MIT license
 *
 *  A width-parameterized latch
 *
 * data is loaded when the load input is 1.
 */
module latch(load, in, out);

  parameter WIDTH = 8;

  input load;
  input [WIDTH-1: 0] in;
  output reg [WIDTH-1: 0] out;

  always @(load or in)
    if (load)
      out <= in;

endmodule
