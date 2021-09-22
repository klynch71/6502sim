/*
 *                                          TRISTATE_BUFFER
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 * a width-parameterized tristate buffer.
 * The output equals the input when enable is 1, otherwise the output is high-impedence z.
 */

module tristate_buffer(enable, in, out);
  parameter WIDTH = 8;

  input enable;
  input [WIDTH-1: 0] in;
  output [WIDTH-1: 0] out;

  assign out = (enable) ? in : {WIDTH{1'bz}};

endmodule
