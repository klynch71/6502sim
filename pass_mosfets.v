/*
 *                                           PASS_MOSFETS
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 *  A width-parameterized pass mosfet
 *
 * A pass mosfet acts like a tranceiver.
 * When the control signal is high, data is allowed to pass between io1 and io2 bidirectionally
 */
module pass_mosfets(enable, io1, io2);

  parameter WIDTH = 8;

  input enable;
  inout [WIDTH-1: 0] io1;
  inout [WIDTH-1: 0] io2;

  tranif1 t[WIDTH-1:0](io1, io2, enable);

endmodule
