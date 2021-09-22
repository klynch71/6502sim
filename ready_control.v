/*
*
*                                          READY_CONTROL
*
*                                   Copyright (c) 2021 Kevin Lynch
*                             This file is licensed under the MIT license
*
 * the ready control block of the 6502 CPU.
 * the rdy output takes on the value of the ready input unless rw_n is low in which
 * case rdy is set high so that a write is not interrupted.
 */
module ready_control(clk_2, READY, rw_n, rdy);
  input clk_2;
  input READY;     //input pin ready; pad: 89
  input rw_n;      //read not write input pin (active low); pad: 1156
  output reg rdy;  //phi2 clocked version of ready or not writing; net 1718 (active high verson of net: 248)

  always @(*)
    if (clk_2)
      rdy <= (READY | ~rw_n); //ignore ready pin if we are writing

endmodule
