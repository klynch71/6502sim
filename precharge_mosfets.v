/*
 *                                           PRECHARGE_MOSFETS
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 *  A width-parameterized precharge mosfet
 *
 * A precharge mosfet essentially acts like a pullup.
 */
module precharge_mosfets(data);

  parameter WIDTH = 8;

  inout [WIDTH-1: 0] data;

  pullup p[WIDTH-1:0](data);

endmodule
