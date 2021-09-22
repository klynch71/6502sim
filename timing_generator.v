/*
 *                                      TIMING_GENERATOR
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 * The timing generator block generates timing cycles for each opcode.
 * Each timing signal, timing_n[0] through timing_n[5], indicates which cycle of
 * the operation the cpu is currently in.  The timing_n[5:0] signals map to the
 * Hanson block diagram names as follows:
 *    timing_n[0] = T0_
 *    timing_n[1] = T1X_
 *    timing_N[2] = T2_
 *    timing_n[3] = T3_
 *    timing_n[4] = T4_
 *    timing-n[5] = T5_
 *
 * The timing signals indicate which cycle of ther operation the cpu is performing:
 *   T0_     : opcode prefetch
 *   T1X_    : operand prefetch
 *   T2_     : opcode is loaded in instruction register and is executed
 *   T3 - T5 : additional execution cycles for opcodes that take more than two cycles
 *
 *  Prefetch (T0_) for the next opcode can occur at the same time the current opcodes
 * is finishing execution.  Thus for a two cycle opcode T0_ + T2_ will both be active
 * on the last cycle.
 */
module timing_generator(clk_1, clk_2, rdy, tz_pre_n, t_res_x, t_res_1, timing_n, fetch, sync);

  input clk_1;
  input clk_2;
  input rdy;              //active high version of ready signal (opposite of net: 248)
  input tz_pre_n;         //net: 792; set low when the opcode is a two cycle opcode
  input t_res_x;          //net: 1215; reset timing registers
  input t_res_1;          //net: 109; pre-latched version of sync
  output [5:0] timing_n;  //the main timing signals 0-5 (active low); nets: 1536, 156, 971, 1567, 690, & 909 (t5)
  output fetch;           //net: 879;  fetch instruction
  output reg sync;        //net: 862; goes high when an insstruction fetch is in progress

  assign timing_n[0] = ~t0;                       //t0_n = net; 1536
  assign timing_n[1] = ~fire_t[1];                //t1_n = net: 156
  assign timing_n[2] = ~t_res_x_c1 | ~fire_t[2];  //t2_n = net: 971
  assign timing_n[3] = ~t_res_x_c1 | ~fire_t[3];  //t3_n = net: 1567
  assign timing_n[4] = ~t_res_x_c1 | ~fire_t[4];  //t4_n = net: 690
  assign timing_n[5] = ~t_res_x_c1 | ~fire_t[5];  //t5_n = net: 909

  assign fetch = rdy & sync_c2; //net: 879

  /*
   * Internal latches
   */
  reg t_res_x_c1;          //net: 1357; reset timimg registers
  reg [5:0] timing_c2;     //latched  value of timing signals on clk2 with opposite sign
  reg [5:0] fire_t;        //indicates we should fire the given timing signal (active high)
  reg sync_c2;             //net: 537

  /*************************************************************************************************
  *
  *                                       t0
  * The prefetch timing signal
  *
  *************************************************************************************************/
  wire t0_c2_rdy = timing_c2[0] & rdy;
  wire reset_t0 = ~(sync | (t_res_x_c1 & tz_pre_n)); //net: 732
  wire t0 = reset_t0 | (timing_c2[0] & ~t0_c2_rdy);  //net: 646

  /*
   * latched signals on clk1
   */
   always @(*)
      if (clk_1)
        begin
          t_res_x_c1 <= t_res_x;

          //hold if not ready, otherwise act more or less like a shift register
          //except t2 uses sync and not t1 as input
          fire_t[0] <= 0; //not used
          fire_t[1] <= timing_c2[0] & rdy;
          fire_t[2] <= (timing_c2[2] & ~rdy) | (sync_c2 & rdy);
          fire_t[3] <= (timing_c2[3] & ~rdy) | (timing_c2[2] & rdy);
          fire_t[4] <= (timing_c2[4] & ~rdy) | (timing_c2[3] & rdy);
          fire_t[5] <= (timing_c2[5] & ~rdy) | (timing_c2[4] & rdy);

          sync <= t_res_1;
        end

  /*
   * latch timing signals on clk2
   */
  always @(clk_2 or timing_n)
    if (clk_2)
      begin
        timing_c2 <= ~timing_n;
        sync_c2 <= sync;
      end

endmodule
