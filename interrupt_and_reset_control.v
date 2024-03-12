/*
 *                                    INTERRUPT_AND_RESET_CONTROL
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 *
 * The primary job of the interrupt and reset control block is to drive the address low data bus
 * with the break vectors using the zero_adl[2:0] outputs.  The address for the break vectors are:
 *         NMI_N:  FFFA, FFFB    non-maskable interrupt vector
 *         RES_N:  FFFC, FFFD    reset vector
 *         IRQ_N:  FFFE, FFFF    maskable interrupt vector
 *
 * So if your code starts at memory location 0400 you would have 00 in FFFC and 04 in FFFD.
 */
module interrupt_and_reset_control(clk_1, clk_2, NMI_N, IRQ_N, RES_N, rdy, t0_n,
                                   op_t2_branch, op_t5_brk, interrupt_flag, res_p, res_g,
                                   int_g, brk_done, aic_n, zero_adl);

  input clk_1;                //net: 710
  input clk_2;                //net: 943
  input NMI_N;                //pad: 1297; non-maskable interrupt input pin
  input IRQ_N;                //pad: 103; interrupt request input pin
  input RES_N;                // pad: 159; reset input pin
  input rdy;                  //ready.  opposite polarity version of net: 248
  input t0_n;                 //net: 646; timing_n[0]
  input op_t2_branch;         //net: 967; two cycle branch (aka pla[80]); (or net: 1239 inverted twice)
  input op_t5_brk;            //net: 370: fifth cycle of a break instruction (aka pla[22])
  input interrupt_flag;       //net: 1553; interrupt mask flag
  output res_p;               //net: 67; retimed reset (active high);
  output res_g;               //net: 926; reset in progress
  output int_g;               //net: 1350; interrupt in progress
  output brk_done;            //net: 1382; break is done (aka brk_6e);
  output aic_n;               //net: 827; assert interrupt control - break in progress; aka: b_out_n
  output reg [2:0] zero_adl;  //zero lower bits of address low bus (for break vectors); nets: 1193, 686, 217

  /*
   * Internal Flip-flops shown on the Hanson diagram.
   * The *_p flip-flops are positive and latched versions of their respective inputs
   */
  wire nmi_g;  //net: 264;  non-maskable interrupt in progress
  wire nmi_l;  //net: 1374; NMI_N has gone low
  reg  nmi_p;  //net: 1032; positive latched version of NMI_N
  reg  irq_p;  //net: 675;  positive latched version of IRQ_N
  reg  res_p;  //net: 67;   positive latched of RESET_N
  wire int_g;  //net: 1350; interrupt in progress from IRQ_N
  wire res_g;  //net: 926;  reset in progress

  /*************************************************************************************************
  *
  *                                     res_g
  * indicates that a reset is in progress.
  *
  *************************************************************************************************/
  reg res_c2;             //net: 975; inverted and latched version of RES_N on clk_2
  reg res_p_c2;           //net: 1036
  wire res_g_not_done = res_g & ~brk_done; //net: 1087
  assign res_g = res_p_c2 | res_g_not_done_c1;


  /*************************************************************************************************
  *
  *                                     nmi_l and nmi_g
  * Non-maskable interrupt handling.
  *
  *************************************************************************************************/
  reg [1:0] vec_c2;       //nets: 1452 and 1126 (vec_c2[0] and vec_c2[1] respectively)
  reg set_vec_1_c1;       //net: 1481 same as vec[1]
  reg brk_done_c1;        //net: 1382
  reg res_g_not_done_c1;  //net: 1132

  reg nmi_g_c2;           //net: 1693
  reg nmi_g_c2_c1;        //oppostive polarity of net: 597
  reg nmi_l_c2;           //net: 1252
  reg nmi_l_or_vec_n_c1;  //net; 1149
  reg nmi_c2_c1;          //net: 562
  reg vec_n_c2;           //net: 1431

  wire [1:0] vec;     //nets: 1481 (vec1) and 1465 (vec0)
  assign vec[0] = op_t5_brk & rdy; //net: 1465
  assign vec[1] = set_vec_1_c1; //net: 1481
  wire vec_n = ~(vec[0] | vec[1]); //net: 1134; active low if vectoring
  wire set_vec_1_n = ~(vec_c2[0] | (~rdy & vec[1])); //net: 1290
  wire nmi_l_or_vec_n = ~(nmi_l | ~vec_n_c2 | ~nmi_p); //net: 1368
  assign nmi_l = ~nmi_c2_c1 & (~nmi_g_c2_c1 | nmi_l_c2);      //net: 1374
  assign nmi_g = ~nmi_l_or_vec_n_c1 & (nmi_g_c2 | brk_done_c1); //net: 264

  /*************************************************************************************************
  *
  *                                     int_g
  * Maskable interrupt handling.
  *
  *************************************************************************************************/
  reg irq_c2;         //net: 330; positive and clocked version of IRQ_N
  reg int_g_c1;       //net: 50
  reg clear_int_g_c2; //net: 760

  wire t0_or_t2_br = ~t0_n | op_t2_branch; //net: 202
  wire int_flag_or_brk_done = interrupt_flag | brk_done; //net: 118
  wire int_in_progress = ~(nmi_g & (int_flag_or_brk_done | ~irq_p)); //net: 480
  wire clear_int_g = ~(int_g_c1 | (t0_or_t2_br & int_in_progress));  //net: 629
  assign int_g = ~(brk_done | clear_int_g_c2);

  /*************************************************************************************************
  *
  *                                     aic_n and brk_done
  * aic_n indicates a break is in progress (reset or either type of interrupt)
  * brk_done indicates that the break is finished
  *
  *************************************************************************************************/
  assign aic_n = ~(res_g | int_g); //net: 827; assert interrupt control
  assign brk_done = rdy & vec_c2[1]; //net: 1382

  /*************************************************************************************************
  *
  *                                     zero_adl[2:0]
  * zero address data low (adl) bus bits 2, 1, and 0.  The adl is pulled high so driving bits 2,1, and 0
  * in combination get you the address of the program counter for the break vectors:
  *         NMI_N:  FFFA, FFFB
  *         RES_N:  FFFC, FFFD
  *         IRQ_N:  FFFE, FFFF
  *
  *************************************************************************************************/
  wire [2:0] pre_zero_adl;  //before being clocked on clk_2
  assign pre_zero_adl[2] = ~(nmi_g | vec_n | res_g);
  assign pre_zero_adl[1] = ~vec_n & res_g;
  assign pre_zero_adl[0] = vec[0];

  /*************************************************************************************************
   *
   *                                     latched signals
   *
   *************************************************************************************************/
   /*
    * latch signals on clk_1
    */
  always @(*)
    if (clk_1)
      begin
        res_p <= res_c2;
        irq_p <= irq_c2;
        set_vec_1_c1 <= ~set_vec_1_n;
        brk_done_c1 <= brk_done;
        res_g_not_done_c1 <= res_g_not_done;
        nmi_g_c2_c1 <= nmi_g_c2;
        nmi_l_or_vec_n_c1 <= nmi_l_or_vec_n;
        int_g_c1 <= int_g;
      end

  /*
   * latch signals on clk_2
   */
  always @(*)
    if (clk_2)
      begin
        res_c2 <= ~RES_N;
        irq_c2 <= ~IRQ_N;
        nmi_p <= ~NMI_N;
        res_p_c2 <= res_p;
        vec_c2 <= vec;
        nmi_g_c2 <= nmi_g;
        clear_int_g_c2 <= clear_int_g;
        nmi_l_c2 <= nmi_l;
        nmi_c2_c1 <= ~nmi_p;
        vec_n_c2 <= vec_n;
        zero_adl <= pre_zero_adl;
      end

endmodule
