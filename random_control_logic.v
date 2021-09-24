/*
 *
 *                                      RANDOM_CONTROL_LOGIC
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 * The random control logic block creates almost all of the signals used to control the workings of the 6502.
 * While the Hanson block diagram shows six control flip-flops there are actually many more.  Most of the output
 * signals are latched and there are several additional latches throughout the logic in order to align timing of
 * certain signals.
 *
 * Signal naming convention:
 *        signal          use the names on the Hanson block diagram or as close as possible
 *        signal_n:       active low
 *        signal_c1:      signal latched on clk_1
 *        signal_c2:      signal latched on clk_2
 *        signal_c2_c1:   signal latched on clk_2 and then that signal latched on clk_1. etc
 *        pre_signal:     rather than have a latched output be named signal_c2, feed the output latch pre_signal so that
 *                        when latched the output does not have the c2 (or c1) suffix.
 *
 */
module random_control_logic(
  input clk_1,            //net: 710
  input clk_2,            //net: 943
  input SO_N,             //net: 1672; set overflow input pin
  input [129:0] pla,      //from rom_decode module
  input rdy,              //opposite polarity of net:248
  input res_p,            //net: 67;   clocked and inverted version of RESET_N input pin
  input res_g,            //net: 926;  reset in progress;
  input b_out_n,          //net: 827;  break in progress
  input implied,          //net: 1019; op code with implied addressing
  input tz_pre_n,         //net: 792;  indicates a two cycle opcode
  input t0,               //net: 646;  positive version of timing signal timing_n[0]
  input ir5,              //net: 1329; instruction register[5]
  input db7,              //net: 493;  data bus bit 7 used to test negativity
  input alu_cout_n,       //net: 206;  alu carry out (active low);
  input break_done,       //net: 1382; from interrupt and reset control;
  input zero_adl0,        //net: 217;  zero address low register bit 0;
  input carry_flag,       //net: 32;   processor status flag for carry
  input zero_flag,        //net: 627;  processor status flag for zero
  input negative_flag,    //net: 69;   processor status flag for negative
  input overflow_flag,    //net: 625;  processor status flag for negative
  input dmode_flag,       //net: 348;  processor status flag decimal mode
  output reg dl_db,       //net: 863;  drive data latch (dl) contents onto internal data bus (db)
  output reg dl_adl,      //net: 1564; drive data latch (dl) contents onto address data low (adl) bus
  output reg dl_adh,      //net: 41;   drive data latch (dl) contents onto address data high (adh) bus
  output reg zero_adh0,   //net: 229;  drive bit 0 of the address data high (adh) bus low
  output reg zero_adh17,  //net: 203   drive bits 1-7 of address dta high (adh) bus low
  output reg adh_abh,     //net: 821;  load address data high (adh) bus into address bus high reg (abh)
  output reg adl_abl,     //net: 639;  load address data low (adl) bus into address bus low reg (abl)
  output pcl_pcl,         //net: 898;  load program counter low select reg from program counter low reg
  output adl_pcl,         //net: 414;  load the program counter low select reg from the adl
  output inc_pc_n,        //net: 379;  increment the program counter (active low)
  output reg pcl_db,      //net: 283;  drive program counter low (pdcl) reg on to internal data bus (db);
  output reg pcl_adl,     //net: 438;  drive program counter low (pcl) register onto address data low (adl) bus
  output pch_pch,         //net: 741;  load program counter high select reg from program counter high reg
  output adh_pch,         //net: 48;   load program counter high select reg from address data high (adh) bus
  output reg pch_db,      //net: 247;  drive program counter high reg on to internal data bus;
  output reg pch_adh,     //net: 1235; driver program counter high (pch) reg onto address data high (adh) bus
  output reg sb_adh,      //net: 140;  connect speical bus (sb) to address data high (adh) bus with pass mossfets
  output reg sb_db,       //net: 1060; connect special bus (sb) to internal data bus (db) with pass mosfets
  output reg s_adl,       //net: 1468; drive stack pointer register onto address data low bus.
  output sb_s,            //net: 874;  load stack pointer register with contents of special bus.
  output s_s,             //net: 654;  immeidately pass stack pointer register input to stack pointer register output
  output reg s_sb,        //net: 1700; drive stack pointer register contents onto special bus
  output sb_ac,           //net: 534;  load the accumulator from the special bus decimal adjust adders
  output ac_db,           //net: 1331; drive accumulator contents onto internal data bus
  output ac_sb,           //net: 1698; drive accumulator contents onto special bus
  output sb_x,            //net: 1186; load special bus into x index register
  output x_sb,            //net: 1263; drive x index register contents onto special bus
  output sb_y,            //net: 325;  load special bus into y index register
  output y_sb,            //net: 801;  drive y index register contents onto special bus
  output not_db_add,      //net: 1068; load the negative value of the internal data bus into the b-side alu register
  output db_add,          //net: 859;  load internal data bus into b-side alu register
  output adl_add,         //net: 437;  load address data low bus into b-side alu register
  output reg daa_n,       //net: 1201; decimal add adjust
  output reg dsa_n,       //net: 725;  decimal subtract adjust
  output reg alu_cin_n,   //net: 1165; alu carry input
  output reg alu_sums,    //net: 921;  alu: a + b
  output reg alu_ands,    //net: 574   alu: a & b
  output reg alu_eors,    //net: 1666  alu: a ^ b; exclusive or
  output reg alu_ors,     //net: 59    alu: a | b
  output reg alu_srs,     //net: 362   alu: shift right
  output reg add_adl,     //net: 1015; load the address data low bus contents into the a-side alu register.
  output reg add_sb06,    //net: 129;  drive bits 0-6 of the adder hold register onto bits 0-6 of the special bus.
  output reg add_sb7,     //net: 214;  drive bit 7 of the adder hold register onto bit 7 of the special bus.
  output zero_add,        //net: 984;  load zero into a-side register of alu
  output sb_add,          //net: 549;  load special bus (sb) into b-side register of alu
  output reg p_db,        //net: 1042; drive processor status register (p) contents onto internal data bus (db).
  output reg db0_c_flag,  //net: 507;  set the carry flag according to bit 0 of the databus.
  output reg ir5_c_flag,  //net: 253;  set the carry flag according to instruction register bit 5.
  output reg acr_c_flag,  //net: 954;  set the carry flag according to alu carry out
  output db7_n_flag,      //net: 754;  set the negative_flag according to bit 7 of the databus
  output reg dbz_z_flag,  //net: 755;  set the zero flag if internal data bus equals zero, otherwise clear it
  output reg ir5_i_flag,  //net: 1662; set the interrupt mask flag according to instruction register bit 5.
  output reg ir5_d_flag,  //net: 1492; set the dmode_flag (decimal mode flag) according to instruction register bit 5.
  output db6_v_flag,      //net: 1111; set the overflow_flag according to bit 6 of the databus.
  output reg avr_v_flag,  //net: 1436; set the overflow flag according to the alu overflow output
  output reg set_v_flag,  //net: 1177; set overflow flag
  output reg clr_v_flag,  //net: 587;  clear overflow flag
  output db_p,            //net: 781;  load internal databus into processor status register
  output t_zero,          //net: 1357; reset timing registers
  output t_res_1,         //net: 109;  reset timing register 1 (aka sync when latched on c1)
  output reg RW_N         //net: 1156; read/write (low = write);
  );
  /*************************************************************************************************
   *
   *                                   t_zero
   *
   * t_zero is used to reset the timing signals
   *
   *************************************************************************************************/
   reg t_res_x_c1;   //net: 1528; same as net: 223
   assign t_zero = ~t_res_x_c1; //net: 1357

  /*
   * alu_cout_held_if_not_rdy (aka ACRL2); net: 916
   * alu_cout value held when rdy_c1_c2 goes low.  If rdy_c1_c2 is high,
   * then alu_cout_held_if_not_rdy just takes on the value of ~alu__cout_n
   */
  reg rdy_c1;       //net: 608 (net 1262 is the same)
  reg rdy_c1_c2;    //net: 853
  reg alu_cout_held_if_not_rdy_c1; //net: 1409
  reg alu_cout_held_if_not_rdy_c1_c2; ////net: 572 (aka ACRL1)
  wire alu_cout_held_if_not_rdy = ~(alu_cout_n & rdy_c1_c2) & (rdy_c1_c2 | alu_cout_held_if_not_rdy_c1_c2); //net: 916

 /*
  * short_circuit_idx_add; net: 1185
  * short_circuit_idx_add is used to short-cirucit the timing cycle (via t_res_x)
  * for indexed addressing.
  */
  reg ind_y_or_abs_idx;  //net: 729; pla[91:92]: x-op-T4-ind-y, x-op-T3-abs-idx
  //pla[97,106,107]: op-store, op-lsr/ror/dec/inc, op-asl/rol
  wire op_shift_or_store = pla[97] | pla[106] | pla[107]; //net: 1137
  wire short_circuit_idx_add = rdy & ~alu_cout_held_if_not_rdy & ~ind_y_or_abs_idx & ~op_shift_or_store; //net: 1185

  /*
  * op_mem_no_shift_inc_dec; net: 510
  * determines if the current opcode is doing a memory operation but not a memory shift, increment or decrement
  */
  //pla[111, 122-125]: op-T3-mem-zp-idx, op-T3-mem-abs, op-T2-mem-zp, op-T5-mem-ind-idx, op-T4-mem-abs-idx
  wire op_mem_n = ~(pla[111] | pla[122] | pla[123] | pla[124] | pla[125]); //net: 347
  wire op_shift_inc_dec_n = ~(pla[106] | pla[107]); //net: 790; pla[106,107]: op-lsr/ror/dec/inc, op-asl/rol
  wire op_mem_no_shift_inc_dec = ~op_mem_n & op_shift_inc_dec_n & ~pla[96]; //net: 510;  pla[96]: x-op-jmp

  /*
  * shift_inc_dec_mem_c1; net: 440
  * clocked versions of op_shift_inc_dec_n & op_mem_n combined with rdy
  * if high, cpu is doing a shift or increment or decrement in memory and rdy is high
  * if rdy is low, hold the current value
  */
  reg shift_inc_dec_mem_c1; //net: 440 (aka t5)
  reg shift_inc_dec_mem_c1_c2; //net: 151
  reg op_shift_inc_dec_mem_c2; //net: 456
  wire op_shift_inc_dec_mem = rdy & ~op_shift_inc_dec_n & ~op_mem_n; //net: 191
  wire shift_inc_dec_mem = op_shift_inc_dec_mem_c2 | (~rdy & shift_inc_dec_mem_c1_c2);  //opposite polarity of net: 1039

  /*
  * shift_inc_dec_mem_rdy_c2_c1: net 1258
  * a further check with rdy and then gated on clk_2 then clk_1
  */
  reg shift_inc_dec_mem_rdy_c2; //net: 1497
  reg shift_inc_dec_mem_rdy_c2_c1; //net: 1258 (aka t6)
  wire shift_inc_dec_mem_rdy = shift_inc_dec_mem_c1 & rdy; //opposite polarity of net: 504

  /*
  * force_t_res_x_c2: net 238
  */
  reg force_t_res_x_c2; //net 238
  //op_stack is high when doing an opcode that requires pushing or pulling from the stack;
  //pla[100:105]: op-T2-php/pha, op-T4-jmp, op-T5-rti/rts, xx-op-T5-jsr, op-T2-jmp-abs, x-op-T3-plp/pla
  wire op_stack = pla[100] | pla[101] | pla[102] | pla[103] | pla[104] | pla[105]; //net; 218
  wire end_x = ~(op_stack | shift_inc_dec_mem_rdy_c2_c1 | op_mem_no_shift_inc_dec | pla[93]); //net: 1716; pla[93]: op-t3-branch
  wire end_x_rdy = rdy & ~end_x; //net: 180
  wire force_t_res_x = res_p  | pre_fetch_rdy | end_x_rdy; //opposite polarity of net: 501

  /*
  * t_res_x; net: 1215
  * t_res_x is captured on clk_1 to genrate t_res_x_c1 (aka ~T_ZERO)
  * t_res_x_c1 has the opposite polarity of net:1357 used to clear the timing registers.
  */
  wire t_res_x = ~(short_circuit_idx_add | force_t_res_x_c2 | break_done); //net: 1215


  /*************************************************************************************************
  *
  *                          logic for t_res_1_c1 (same as SYNC)
  *
  *************************************************************************************************/
  reg t_res_1_c1;   //net: 1161;  same as sync; same as net: 862

  /*
  * br_taken_n; net: 1544
  * Logic that determines whether a branch will be taken or not.
  */
  //pla[121, 126]: ir[6], ir[7]
  wire br_carry_met = ~(~pla[121] | pla[126] | ~carry_flag);       //net: 307
  wire br_zero_met = ~(pla[121] | pla[126] | ~zero_flag);          //net: 1293
  wire br_negative_met = ~(~pla[121] | ~pla[126] | ~negative_flag); //net: 1371
  wire br_overflow_met = ~(pla[121] | ~pla[126] | ~overflow_flag); //net: 1433
  wire br_cond_met_n =  ~(br_carry_met | br_zero_met | br_overflow_met | br_negative_met); //net: 620
  wire br_taken_n = ~ir5 ^ br_cond_met_n;  //branch taken; net: 1544

  /*
  * pre_fetch_rdy; net: 819
  * Logic that determines whether the cpu should fetch on the next C1 cycle or not.
  */
  reg res_p_c2; //net: 449
  reg pre_fetch_n_c2; //net: 596
  wire t2_br_taken_n = br_taken_n & pla[80]; //net: 1172; (pla[80] aka nnT2br)
  wire hold_sync = ~rdy & t_res_1_c1;
  wire pre_fetch_n = ~(hold_sync | (rdy & (t0 | t2_br_taken_n))); //net: 1085
  wire pre_fetch_rdy = ~pre_fetch_n_c2 & ~res_p_c2; //net: 819

  /*
  * short_circuit_branch_add; net: 430
  * deterimines if we need to short circuit the timing cycle and force a SYNC due to
  * a branch add.
  */
  reg t2_br_c2; //c2 latched version of pla[80]; net: 1269
  reg branch_back_c1; //net: 756; same as net: 771 which is 756 doubly negated
  reg branch_back_c1_c2; //net 1198
  //since branch_back depends on a circular path with branch_back_c1_c2 we need a few clock cycles to stabilize
  wire branch_back = (branch_back_c1_c2 === 1'bx) ? 1'b1 : (db7 | ~t2_br_c2) & (branch_back_c1_c2 | t2_br_c2); //net: 626
  reg op_t3_branch_rdy_c2; //net: 899; opposite polarity of net: 850
  wire op_t3_branch_rdy = pla[93] & rdy_c1_c2; //net: 19
  wire branch_back_or_carry = alu_cout_n | branch_back_c1;
  wire branch_back_and_carry = alu_cout_n & branch_back_c1;
  wire short_circuit_branch_add = op_t3_branch_rdy_c2 & branch_back_or_carry & ~branch_back_and_carry; //net: 430

  /*
  * t_res_1; net: 109
  * Essentially SYNC but before being captured on C1.
  */
  reg short_circuit_n_c1;   //net: 323
  reg short_circuit_hold_c2; //net: 294
  wire short_circuit_hold = ~(rdy_c1 | res_p | short_circuit_n_c1); //net: 14
  wire short_circuit_n = ~(short_circuit_branch_add | short_circuit_hold_c2); //net: 959
  wire short_circuit_rdy = rdy & ~short_circuit_n; //net: 1154
  assign t_res_1 = pre_fetch_rdy | short_circuit_rdy; //net: 109

  /*************************************************************************************************
  *
  *                          dl_db
  *  Drive input data latch contents onto internal data bus.
  *  There are several cases where we need to load the data onto the internal data bus:
  *     - a break needs to load a vector into the program counters
  *     - we are pulling from the stack into the accumulator or the status register
  *     - we need to store the offset of a relative branch into the stack pointer
  *     - we are doing an indexed operation and need to load the oeprand into the alu
  *     - we are doing a compare and need to load the operand into the alu
  *     - we are doing a math operation and need to load the operand into the alu
  *     - we are loading the x or y registers
  *
  *************************************************************************************************/
  //pla[39-43]: op-T3-ind-x, op-T4-ind-y, op-T2-ind-y, op-T3-abs-idx, op-plp/pla
  wire op_indexed_or_stack_pull = pla[39] | pla[40] | pla[41] | pla[42] | pla[43];
  wire inc_sb = op_indexed_or_stack_pull | (pla[44] & shift_inc_dec_mem_c1); //net: 389; increment special bus; pla[44] = op-inc/nop
  //pla[45]-pla[48]: op-T4-ind-x, x-op-T3-ind-y, op-rti/rts, op-T2-jsr
  wire dl_db_input1 = break_done | inc_sb | pla[45] | pla[46] | pla[47] | pla[48]; //net: 847
  //pla[128] = op-implied, pla[84] = op-T2-abs-access
  wire t0_or_t2_abs = ~pla[128] & (t0 | pla[83]); //net: 275; pla[128] is net: 1006 (twice negated to get net: 1697)
  //pla[80] = op-T2-branch, pla[102] = op-T5-rti/rts
  wire pre_dlb_db_n = ~(pla[80] | pla[102] | shift_inc_dec_mem_c1 | dl_db_input1 | t0_or_t2_abs); //net: 104

  /*************************************************************************************************
  *
  *                          dl_adl & dl_adh
  *  dl_adl = Drive data latch contents onto internal address low bus
  *  dl_adh = Drive data latch contents onto internal address high bus
  *
  *  dl_adl is used when we are doing a zero page operation and need to load the address low bus
  *
  *  dl_adh is used in the following cases:
  *     - we are returning from a break or jsr and the stack has placed the return address on the data bus
  *     - we are doing an indrect address instruction and the operand holds the address of the address we need
  *
  *************************************************************************************************/
  //dl_adl; net: 1564 (buffer of net 291)
  //pla[81-82]: op-T2-zp/zp-idx, op-T2-ind
  wire pre_dl_adl_n = ~(pla[81] | pla[82]); //net: 1225; zero page, zero page indexed or indirect

  //dl_adh; net: 41 (buffer of net 1277)
  //pla[94-96]: op-brk/rti, op-jsr, x-op-jmp
  wire jump_break_n = ~(pla[94] | pla[95] | pla[96]); //net: 134
  wire dl_pch = t0 & ~jump_break_n; //net: 467; //stack has placed return address on data bus
  //pla[84], pla[89-90]: op-T5-rts, op-T5-ind-x, op-T3-abs/idx/ind, x-op-T4-ind-y
  wire indirect = (pla[84] | pla[89] | pla[90] | pla[91]); //net: 630
  wire pre_dl_adh_n = ~(dl_pch | indirect); //net: 1705

 /*************************************************************************************************
 *
 *                          zero_adh0 & zero_adh17
 * zero-adh0  = Set address high bus bit 0 to zero
 * zero_adh17 = set address high bus bits 1 through 7 to zero.
 *
 * Used for the following cases:
 *   - to clear the entire address high bus when doing a zero page operation (ie; dl_adl)
 *   - we are accessing the stack and need to zero out bits 1 through 7 of the address high bus
 *
 *************************************************************************************************/
 //zero_adh0 is the same as dl_adl so no extra logic required for zero_adh0
 wire pre_zero_adh17_n = ~(pla[57] | ~pre_dl_adl_n); //net: 1090; pla[57] is opt-t2-stack-access

 /*************************************************************************************************
 *
 *                                      sb_adh
 * Enable pass mosfets to connect the special bus with the address data high bus.
 *
 * Used in the following cases:
 *  - we are doing an absolute indexed operation and need to to math on the address (pla[71])
 *  - we are doing an indirect, y operation and need to do math on the address (pla[72])
 *  - we are doing a relative branch and need to add the offset to the current address (pla[93])
 *  - we are doing a relative branch and need to load the final address from the alu (pla[73])
 *
 *************************************************************************************************/
 //sb_adh: net: 140 (buffer of net 1596)
 //adh_math = op-T4-abs-idx | op-T5-ind-y | op-branch-done;
 wire adh_math = (pla[71] | pla[72] | pla[73]); //net: 192
 //pla[93] is net:660 and twice inverted is net: 236; opt-t3-branch aka br_3
 wire pre_sb_adh_n = ~(adh_math | pla[93]); //net: 506;

 /*************************************************************************************************
 *
 *                                  adh_pch & pch_pch
 * adh_pch = Drive address high bus into program counter high select register.
 * pch_pch = Drive program counter high register into program counter high select register.
 *
 * adh_pch loads the program counter high select register so it can be incremented:
 *   - after a prefetch cycle (t0)
 *   - after a fetch cycle (t_res_1_c1 aka sync)
 *   - after a t2 branch cycle (pla[80])
 *   - after a t2 absolute access cycle (pla[83]) to lead the new address
 *   - after a t5 rts cycle in order to load the return address (pla[84])
 *   - after a t3 branch cycle to lead the new address (pla[93])
 *
 * pch_pch loads the program counter high select register from the program counter high register
 * and occurs on cycles where we are not loading the select register from the address high data bus (adh_pch)
 *
 *************************************************************************************************/
 //adh_pch: net: 48 (buffer of net 21)
 reg pre_adh_pch_n_c2; //net: 1162
 //pla[80, 83, 84, 93]: op-T2-branch, op-T2-abs-access, op-T5-rts, op_t3_branch
 wire pre_adh_pch_n = ~(t0 | t_res_1_c1 | pla[80] | pla[83] | pla[84] | pla[93]); //net: 272
 assign adh_pch = (~pre_adh_pch_n_c2 & clk_1); //net: 21 (then buffered to become net: 48)

 //pch_pch; net: 741 (buffer of net 611)
 assign pch_pch = (pre_adh_pch_n_c2 & clk_1);  //net: 611 (then buffered to become net: 741)

 /*************************************************************************************************
 *
 *                                  adh_abh
 * load address data high bus into address bus high register.
 *
 * We usually load the address bus high (abh) register with the address data high (adh) bus unless we are
 * using the adh for break, stack pull, jsr, or math operations on the address needed by indexed operations
 *
 *************************************************************************************************/
 //adh_abh; net: 821 (buffer of net 582)
 //pla[28] = net 788 = t2; pla[56] = net 776 and twice inverted to give 1002 as equivalent as op-t5-jsr
 wire using_adh_n = ~(pla[28] | pla[56] | indirect | ~pre_adh_pch_n); //net: 152; using adh for math, stack, etc
 wire using_adh_rdy = ~using_adh_n & rdy; //net: 1343
 wire hold_cout_n = ~(rdy_c1 & alu_cout_held_if_not_rdy_c1_c2);  //net: 933
 wire hold_cout_or_sb_adh = ~(hold_cout_n | pre_sb_adh_n); //net: 877
 wire adh_in_use = using_adh_rdy | hold_cout_or_sb_adh;
 wire pre_adh_abh_n = ~((adh_in_use & ~pla[93]) |  zero_adl0); //net: 696; pla[93] is opt-t3-branch

 /*************************************************************************************************
 *
 *                                  adl_abl
 * load address data low bus into address bus low register.
 *
 * We almost always load the address bus low (abl) register with the  address data low (adl) bus
 * on every cycle.  The exceptions are:
 *    - do not load when calculating absolute indexed address
 *    - do not load when calculating indirect, y address
 *    - do not load during a shift in memory operation which takes a few cycles
 *
 *************************************************************************************************/
 //adl_abl; net: 639 (buffer of net 220)
 wire t4_abs_idx_or_t5_ind_y_n = ~(pla[71] | pla[72] | ~rdy); //net: 46; pla[71,71]: t4-abs-idx, t5-ind-y
 wire t5_t6_n = ~(shift_inc_dec_mem_c1 | shift_inc_dec_mem_rdy_c2_c1);
 wire pre_adl_abl_n = ~(t4_abs_idx_or_t5_ind_y_n & t5_t6_n); //net: 190

 /*************************************************************************************************
 *
 *                                  adl_pcl & pcl_pcl
 * adl_pcl = load program counter low select register from address data low bus
 * pcl_pcl = load program counter low select register from program counter low register
 *
 * We load the program counter low (pcl) select register from the address data low (adl) bus when:
 *   - we are prefetching (t0)
 *   - we are calculating a branch offset
 *   - we are returning form a subroutine and the stack pointer register is driving the adl bus
 *   - we are driving the address low data bus from the program counter low register
 *
 * Anytime a cycle is not loading the pcl select register from the adl bus, we load it from the
 * program counter low (pcl) bus.
 *
 *************************************************************************************************/
 //adl_pcl; net: 414 (buffer of net 818)
 reg pre_adl_pcl_n_c2; //net: 265
 wire br_3_rdy = pla[93] & rdy_c1; //pla[93] = op-t3-branch
 wire pre_adl_pcl_n = ~(br_3_rdy | pla[84] | t0 | ~pre_pcl_adl_n); //net: 182; pla[84] = op-T5-rts
 assign adl_pcl = (~pre_adl_pcl_n_c2 & clk_1); //net: 818 which is then buffered to drive net: 414

 //pcl_pcl; net: 127 (buffer of 1270)
 reg pre_pcl_pcl_n_c2; //net: 509
 wire pre_pcl_pcl_n = ~pre_adl_pcl_n;  //net: 442; opposite polarity of pre_adl_pcl_n
 assign pcl_pcl = (~pre_pcl_pcl_n_c2 & clk_1); //net: 127 wich is then buffered t odrive net: 898

 /*************************************************************************************************
 *
 *                                  pcl_adl
 * Drive contents of program counter low register onto address data low bus.
 *
 * pcl_adl is active for the following conditions:
 *   - during a jsr command in order to load the current program counter onto the stack
 *   - during a branch command in order to lad the current progam counter onto the stack
 *   - during t0 as long as it's not a branch,jump, or break so that pcl can be loaded into the low address bus
 *   - during sync so that the pcl can be loaded into the low address bus
 *
 *************************************************************************************************/
 wire jump_break_rdy = rdy_c1 & ~jump_break_n; //net: 930
 wire t0_no_jump = t0 & ~jump_break_rdy; //net: 1286
 //pla[56, 80, 83]: op-T5-jsr, op-T2-branch, op-T2-abs-access
 wire pre_pcl_adl_n = ~(pla[56] | pla[80] | pla[83] | t0_no_jump | t_res_1_c1); //net: 1211

 /*************************************************************************************************
  *
  *                                  pch_adh
  *  Drive contents of program counter high register onto address data high bus
  *
  * pch_adh is active for the following conditions:
  *   - during a branch relative in order to load the program counter high register into the alu a-side
  *     register in case we cross a page boundary and need to increment it for forward branch or decrement
  *     for backward branch.  pla[93] indicates this condition.
  *   - anytime the porgram counter low is being driven onto the address low data bus (pcl_adl) and
  *     the stack is not being used (dl_pch is low) and we are not in the first cycle of a branch (br_0 is low)
  *
  *************************************************************************************************/
  //pch_adh: net: 1235 (buffer of net 598)
  reg rdy_c2; //net: 865
  reg rdy_c2_c1; //opposite polarity of net: 603
  wire br_0 = rdy_c2_c1 & pla[73]; //net: 1721; pla[73] = op-branch-done;
  wire fire_pch_adh = ~(pre_pcl_adl_n | dl_pch | br_0); //net: 10
  wire pre_pch_adh_n = ~(pla[93] | fire_pch_adh); //net: 176; pla[93] = op-t3-branch

 /*************************************************************************************************
 *
 *                                  inc_pc_n
 * Increment program counter when low. aka program counter carry in.
 *
 * The program counter increments on almost every cycle except for the following cases:
 *  - do not increment pc during breaks (reset or interrupts)
 *  - do not increment pc during relative jumps when we are calculating the jump address
 *  - do not increment the pc when we are loading the program counter for a non-branch instruction
 * - do not increment the pc during the first cycle of an impled instruction (which takes two cycles)
 *
 *************************************************************************************************/
 reg b_out_n_c1;  //net: 1472; b_out_n captured on c1; break in progress
 reg short_circuit_branch_add_c1;  //net: 1570; short_circuit_branch_add captured on c1
 reg inc_pc_c_c1;  //net: 1581; inc_pc_c (net 1275) captured on c1
 reg next_pc_n_c2;   //net: 832; net 586 captured on c2
 wire br_2_or_3 = pla[80] | pla[93]; //net: 1448; pla[80, 93]: op-T2-branch, op-t3-branch
 wire loading_pc_and_not_branching = ~(br_2_or_3 | pre_adl_pcl_n); //net: 1619
 wire br_2_not_taken = br_taken_n & pla[80]; //pla[80] = op-T2-branch
 wire next_pc_n = ~(loading_pc_and_not_branching | br_2_not_taken); //net: 586

 wire inc_pc_c = rdy & ~implied & ~next_pc_n_c2; //net: 1275

 assign inc_pc_n = ~((inc_pc_c_c1 & b_out_n_c1) | (b_out_n_c1 & short_circuit_branch_add_c1));  //net: 379

/*************************************************************************************************
 *
 *                          pch_db & pcl_db
 *  pch_db = drive program counter high (pch) onto internal data bus (db)
 *  pcl_db = drive program counter low (pcl) onto internal data bus (db)
 *
 *  The program counter high (pch) address is put on the internal data bus:
 *      - during a branch so the alu can add (forward branch) or subtract one (backwards branch) in
 *        case the branch crosses a page boundary.
 *      - during a jsr in order to put the current address on the stack
 *
 *  The program counter low (pcl) address is put on the internal data bus whenever the program counter
 *  high address is not being put on the internal data bus.
 *
 *************************************************************************************************/
 //pch_db
 reg pre_pch_db_n_c2; //net: 56
 wire pre_pch_db_n = ~(pla[77] | pla[78]); //op_t2_br or op_t3_jsr; net: 824

 //pcl_db
 reg pre_pcl_db_n_c1; //net: 462
 wire pre_pcl_db = ~(pre_pch_db_n_c2 | ~rdy); //net: 720

 /*************************************************************************************************
 *
 *                                  sb_ac
 * Drive special bus contents (decimal adjusted if need be) into accumulator.
 *
 * The special bus is loaded into the accumulator during the following operations:
 *   - loading the accumulator with LDA
 *   - transfer of x or y register to accumulator with TXA or TYA
 *   - pulling stack into accumulator with PLA
 *   - an accumulator shift operation: ASL A, LSR A, ROL A, or ROR A
 *   - a math operation: ADC, SBC, ORA, AND, or EOR
 *
 *************************************************************************************************/
 reg pre_sb_ac_n_c2; //net: 1505
 //pla[58-64]: op-T0-tya, op-T+-ora/and/eor/adc, op-T+-adc/sbc, op-T+-shift-a, op-T0-txa, op-T0-pla, op-T0-lda
 wire pre_sb_ac_n = ~(pla[58] | pla[59] | pla[60] | pla[61] | pla[62] | pla[63] | pla[64]); //net 1455
 assign sb_ac = (~pre_sb_ac_n_c2 & clk_1);  //net: 534

 /*************************************************************************************************
 *
 *                                  ac_db
 * Drive accumulator contents onto internal data bus.
 *
 * The accumulator contents is driven onto the internal data bus:
 *    - when storing accumulator on the stack (PLA)
 *    - when storing the accumulator in memory (STA)
 *    - when comparing the accumulator with memory (CMP) so that the accumulator can be loaded
 *      into the b-side alu register while the memory contents is loaded into the a-side alu register
 *
 *************************************************************************************************/
 reg pre_ac_db_n_c2; //net: 266
 wire store_accumulator = pla[79] & store; //pla79 =  op-sta/cmp
 wire pre_ac_db_n = ~(store_accumulator | pla[74]); //net: 1037; pla74 = op-T2-pha
 assign ac_db = (~pre_ac_db_n_c2 & clk_1);  //net: 1331

 /*************************************************************************************************
 *
 *                                  ac_sb
 * Drive accumulator contents onto special bus.
 *
 * The accumulator contents are driven onto the special bus during all operations that involve the
 * accumulator except LDA, PLA, or TXA which load the accumulator from the special bus.
 *
 *************************************************************************************************/
 reg pre_ac_sb_n_c2; //net: 55
 wire op_t0_accumulator = ~pla[64] & pla[65]; //pla[64,65]: op-T0-lda, op-T0-acc
 //pla[66-68]: op-T0-tay, op-T0-shift-a, op-T0-tax
 wire pre_ac_sb_n = ~(op_ands | op_t0_accumulator | pla[66] | pla[67] | pla[68]); //net: 11
 assign ac_sb = (~pre_ac_sb_n_c2 & clk_1); //net: 1698

 /*************************************************************************************************
 *
 *                                  sb_x & x_sb
 * sb_x = load special bus into x register
 * x_sb = drive x register contents onto special bus
 *
 * The special bus contents are loaded into the x register using sb_x for the following operations:
 *    - LDX: load X
 *    - TAX: transfer accumulator to X
 *    - TSX: transfer stack pointer to X
 *    - DEX: decrement X
 *    - INX: increment X
 *
 * THe x register contents are loaded onto the special bus using x_sb for the following operations:
 *    - STX: store X
 *    - TXA: transfer X to accumulator
 *    - TSX: transfer stack to accumulator
 *    - INX: increment X
 *    - DEX: drecrement X
 *    - CPX: compare with X
 *    - operations that use one of the following addressing modes:
 *          - absolute, X-indexed operations
 *          - X-indexed, indirect operations
 *          - zeropage, X-indexed
 *
 *************************************************************************************************/
 //sb_x
 reg pre_sb_x_n_c2; //net: 459
 //pla[14-16]: op-T0-ldx/tax/tsx, op-T+-dex, op-T+-inx
 wire pre_sb_x_n = ~(pla[14] | pla[15] | pla[16]); //net: 844
 assign sb_x = (~pre_sb_x_n_c2 & clk_1); //net: 1186

 //x_sb
 reg pre_x_sb_n_c2; //net: 1404
 wire store_x = store & pla[12]; //pla[12]: op-from-x
 wire op_t2_idx_x = pla[6] & ~pla[7]; //pla[6,7]: op-T2-idx-x-xy, op-xy
 //pla[8-11,13]: op-T2-ind-x, x-op-T0-txa, op-T0-dex, op-T0-cpx/inx, op-T0-tsx
 wire pre_x_sb_n = ~(store_x | op_t2_idx_x | pla[8] | pla[9] | pla[10] | pla[11] | pla[13]); //net: 1106
 assign x_sb = (~pre_x_sb_n_c2 & clk_1); //net: 1263

 /*************************************************************************************************
 *
 *                                  sb_y & y_sb
 * sb_y = load special bus into y register
 * y_sb = drive y register contents onto special bus
 *
 * The special bus contents are loaded into the y register using sb_y for the following operations:
 *    - LDY: load Y
 *    - TAY: transfer accumulator to Y
 *    - DEY: decrement Y
 *    - INY: increment Y
 *
 * THe y register contents are loaded onto the special bus using y_sb for the following operations:
 *    - STY: store Y
 *    - TYA: transfer Y to accumulator
 *    - INY: increment Y
 *    - DEY: drecrement Y
 *    - CPY: compare with Y
 *    - operations that use one of the following addressing modes:
 *          - absolute, Y-indexed operations
 *          - indirect, Y-indexed operations
 *          - zeropage, Y-indexed
 *
 *************************************************************************************************/
 //sb_y
 reg pre_sb_y_n_c2; //net: 460
 //pla[18-20]: op-T+-iny/dey, op-T0-ldy-mem, op-T0-tay/ldy-not-idx
 wire pre_sb_y_n = ~(pla[18] | pla[19] | pla[20]); //net: 616
 assign sb_y = (~pre_sb_y_n_c2 & clk_1); //net: 325

 //y_sb
 reg pre_y_sb_n_c2; //net: 1113
 wire store_y = store & pla[0]; //pla[0]: op-sty/cpy-mem
 wire opt_t2_idx_y = pla[6] & pla[7]; //pla[6,7]: op-T2-idx-x-xy, op-xy
 //pla[1-5]: op-T3-ind-y, op-T2-abs-y, op-T0-iny/de, x-op-T0-tya, op-T0-cpy/iny
 wire pre_y_sb_n = ~(store_y | opt_t2_idx_y | pla[1] | pla[2] | pla[3] | pla[4] | pla[5]); //net: 1717
 assign y_sb = (~pre_y_sb_n_c2 & clk_1); //net: 801

 /*************************************************************************************************
 *
 *                                  sb_db
 * Enable pass mosfets to connect the special bus with the internal data bus.
 *
 * The special bus (sb) is connected to the internal data bus (db) using sb_db for the following:
 *   - when storing the x or y registers in memory
 *   - when doing a jump to subroutine (jsr) in order to store the low address of the jsr into the
 *     stack pointer register so that it can be driven onto the adl bus.
 *   - when doing an accumulator shift so that the accumulator can be put into the b-side register of the alu.
 *   - when doing a memory shift, increment or decrement so that the memory contents can be put into the
 *     b-side register of the alu.
 *   - when doing an AND or BIT operation so that the memory contents can be put into the b-side register of the alu.
 *   - when driving the accumulator contents onto the special bus so that it can be loaded in the b-side register.
 *   - when doing a relative branch so the adl can be put into the b-side register fo the alu.
 *   - during the sync cycle in case the operand needs to be put into the adl, x, or y registers.
 *
 *************************************************************************************************/
 //sb_db: 1060 (buffer of net 1295)
 wire store = pla[97] & ~op_mem_n; //net: 335; pla[97]: op-store; store in memory
 //pla[0,12]: op-sty/cpy-mem, op-from-x
 wire stxy_n = ~((store & pla[0]) | (store & pla[12])); //net: 1303; store x or y in memory
 wire jsxy = pla[48] | ~stxy_n; //net: 782; jsr or store xy; pla[48]: op-T2-jsr

 wire shift_in_mem = shift_inc_dec_mem_c1 & pla[55];  //net: 979; pla[55]: op-shift
 wire sb_xy = ~(pre_sb_x_n & pre_sb_y_n); //net: 946
 wire op_ands = pla[69] | pla[70]; //net: 1228; pla[69,70]: op-T0-bit, op-T0-and
 wire z_test_n = ~(sb_xy | ~pre_sb_ac_n | op_ands | shift_inc_dec_mem_rdy_c2_c1); //net: 384; z_test_n
 wire z_test_not_ands = ~(z_test_n | op_ands); //net: 550
 //pla[67, 80]: op-T0-shift-a, op-T2-branch; t_res_1_c1 = sync
 wire pre_sb_db_n = ~(jsxy | pla[67] | pla[80] | shift_in_mem | z_test_not_ands | t_res_1_c1); //net: 1347

 /*************************************************************************************************
 *
 *                                  s_adl
 * Drive stack pointer contents onto address data low bus.
 *
 * The stack pointer (s) is driven on the address data low (adl) via s_adl:
 *    - during any stack operations (PHP, PHA, PLP, PLA)
 *    - during a jump to subroutine (JSR)
 *
 *************************************************************************************************/
 //pla[35] = op_t2_stack; pla[21] = op_t0_jsr
 wire pre_s_adl_n = ~(pla[35] | (rdy_c1 & pla[21])); //net: 632

 /*************************************************************************************************
 *
 *                                  sb_s & s_s & s_sb
 * sb_s = Load special bus contents into stack pointer.
 * s_s = immediately pass stack pointer input to stack pointer output
 * s_sb = drive stack pointer onto special bus
 *
 * The special bus (sb) contents are loaded into the stack pointer (s) during stack operations vis sb_s:
 *    - storing to the stack during PHP or PHA
 *    - retreiving from the stack during PLP, PLA, or TSX
 *    - storing or retreiving addresses for JSR and RTS
 *    - storing or reteiving addresses for breaks (reset, interrupts) and RTI
 *
 * s_s is used to immediately pass the stack pointer intput to the stack pointer output anytime
 * sb_s is not asserted.  When sb_s is asserted, the stack pointer output will reflect the input on clk_2
 *
 * s_sb is used to place the stack pointer on the special to load into the X register during TSX commands
 *
 *
 *
 *************************************************************************************************/
 //sb_s net:874
 reg pre_sb_s_n_c2; //net: 521
 //pla[21-26]: op-T0-jsr, op-T5-brk, op-T0-php/pha, op-T4-rts, op-T3-plp/pla, op-T5-rti
 wire stack_op_n = ~(pla[21] | pla[22] | pla[23] | pla[24] | pla[25] | pla[26]); //net: 1464
 wire stack_op_rdy = rdy_c1 & ~stack_op_n; //net: 1109
 wire jsr_rdy = rdy & pla[48]; //pla[48]: op-T2-jsr
 wire pre_sb_s_n = ~(pla[13] | jsr_rdy | stack_op_rdy); //net: 1358; pla[13]: op-T0-tsx
 assign sb_s = (~pre_sb_s_n_c2 & clk_1); //net: 874

 //s_s net:654
 assign s_s = (pre_sb_s_n_c2 & clk_1); //net: 654

 //s_sb net:1700
wire pre_s_sb_n = ~pla[17]; //net: 1586; pla17 = op-T0-tsx

 /*************************************************************************************************
  *
  *                                       Decimal Mode Adjust
  *                                          daa_n & dsa_n
  * daa_n = decimal add adjust
  * dsa_n = decimal subtract adjust
  *
  * daa_n goes low when we are doing an ADC when the decimal mode flag is set and we might need
  * to adjust the alu output.
  *
  * dsa_n goes low when we are doing an SBC when the decimal mode flag is set and we might need
  * to adjust the alu output.
  *
  *************************************************************************************************/
  //daa_n
  reg pre_daa_n_c2;  //net: 680
  wire dmode_adc_sbc_n = ~(pla[52] & dmode_flag); //net: 673; pla[52]: op-T0-adc/sbc
  wire pre_daa_n = (dmode_adc_sbc_n | pla[51]); //net: 1688; pla[51]: op-T0-sbc

  //dsa_n
  reg pre_dsa_n_c2; //net: 561
  wire pre_dsa_n = ~(dmode_flag & pla[51]); //net: 29; pla[51]: op-T0-sbc

 /*************************************************************************************************
  *
  *                                       adl_add
  * alu b-side load: load address data low bus into alu b-side register
  *
  * the alub-side register gets loades with the address data low (adl) bus via adl_add when:
  *     - pulling from the stack so we can increment the stack pointer register using the alu
  *     - pushing data on the stack so we can drecrement the stack pointer register using the alu
  *
  *************************************************************************************************/
  reg pre_adl_add_n_c2; //net: 1477
  wire adl_add_not_t0 = pla[33] & ~pla[34]; //pla[33,45]: op-T2-ADL/ADD, op-T0
  //pla[35-39]: op-T2-stack, op-T3-stack/bit/jmp, op-T4-brk/jsr, op-T4-rti, op-T3-ind-x
  wire pre_adl_add_n = ~(adl_add_not_t0 | pla[35] | pla[36] | pla[37] | pla[38] | pla[39] | ~rdy); //net: 604
  assign adl_add = (~pre_adl_add_n_c2 & clk_1);  //net: 437


/*************************************************************************************************
 *
 *                                    not_db_add & db_add
 * not_db_add = alu b-side load: load inverted version of the internal data bus into alu b-side register.
 * db_add = alu b-side load: load internal data bus into alu b-side register
 *
 * not_db_add is active when:
 *    - doing a subtract operation (SBC)
 *    - doing a relative branch backwards
 *    - doing a compare with the x or y registers
 *    - incrementing the x or y registers
 *    - doing a jump to subroutine so we can load FF (-1) into b-side register to decrement the stack pointer
 *
 * db_add is active whenver neither adl_add nor not_db_add is active.
 *
 *************************************************************************************************/
 reg pre_not_db_add_n_c2; //net: 805
 wire t3_branch_back = ~(branch_back_c1 | ~pla[93]); //net: 1055; pla[93]: op-t3-branch
 //pla[49, 50]: op-T0-cpx/cpy/inx/iny, op-T0-cmp
 wire bb_or_cpxy_or_inxy = pla[49] | pla[50] | t3_branch_back; //net: 1081
 //pla[51,56]: op-T0-sbc, op-T5-jsr
 wire pre_not_db_add_n = ~(rdy & (pla[51] | pla[56] | bb_or_cpxy_or_inxy)); //net: 779
 assign not_db_add = (~pre_not_db_add_n_c2 & clk_1);  //net: 1068

 //db_add
 reg pre_db_add_n_c2; //net: 688
 wire pre_db_add_n = ~(pre_adl_add_n & pre_not_db_add_n); //net: 1594
 assign db_add = (~pre_db_add_n_c2 & clk_1); //net: 859

 /*************************************************************************************************
 *
 *                                       alu_cin_n
 * Carry input to alu
 *
 * alu_cin_n is high except when set to low for any of the following:
 *   - return from an interrupt (RTI) or JSR (RTS) in order to decrement the stack pointer
 *   - incrementing contents on the special bus
 *   - branching backwards
 *   - comparing with the x or y registers
 *   - incrementing the x or y registers
 *   - if the carry flag is set during a ADC, SBC, ROL, or ROR operation
 *
 *************************************************************************************************/
 reg return_and_adl_add_c2; //net: 1652
 reg inc_sb_c2; //net: 614
 reg bb_or_cpxy_or_inxy_c2; //net: 960
 reg c_set_c2; //net: 848
 wire return_and_adl_add = pla[47] & ~pre_adl_add_n; //net: 385; pla[47]: op-rti/rts
 wire shift_inc_dec_mem_or_t0_n = ~(shift_inc_dec_mem_c1 | t0); //net: 812
 wire cflag_shift_inc_dec_mem_or_t0 = carry_flag & ~shift_inc_dec_mem_or_t0_n; //net: 1044
 wire should_set_carry_n = ~(cflag_shift_inc_dec_mem_or_t0 & (pla[52] | pla[53])); //pla[52,53]: op-T0-adc/sbc, op-rol/ror
 wire c_set = ~(~pla[54] & should_set_carry_n);  //net: 473; pla[54]: op-T3-jmp
 wire pre_alu_cin_n = ~(return_and_adl_add_c2 | inc_sb_c2 | bb_or_cpxy_or_inxy_c2 | c_set_c2); //net: 1178

 /*************************************************************************************************
 *
 *                                      zero_add & sb_add
 * zero_add = load zero into alu_input_a register
 * sb_add  = load special bus into alu_input_a_register
 *
 * One or the other of these will fire on every cycle to load the a-side alu register.
 * zero_add will fire when a zero needs to be loaded into the a-side alu register, otherwise the
 * contents of the special bus will be loaded via sb_add.  Zero is often loaded into the ALU in order
 * to increment the b-side alu value by setting the carry in bit and doing a sum operation.
 *
 *************************************************************************************************/
 reg pre_zero_add_n_c2; //net: 1027
 //pla[30,31,45,47,48]: op-jmp, op-T2-abs, op-T4-ind-x, op-rti/rts, op-T2-jsr
 wire pre_zero_add_n = ~(stack_op_rdy | break_done | inc_sb | ~rdy | pla[30] | pla[31] | pla[45] | pla[47] | pla[48]); //net: 1649
 assign zero_add = (~pre_zero_add_n_c2 & clk_1);  //net: 984

 assign sb_add = (pre_zero_add_n_c2 & clk_1); //net: 549; opposite of zero_add

/*************************************************************************************************
 *
 *                                       ALU commands:
 *  alu_sums = A + B
 *  alu_ands = A & B
 *  alu_xors = A ^ B = exclusive or
 *  alu_ors = A | B
 *  alu_srs = shift right
 *
 *  The ALU always does one of these commands on every cycle as alu_sums is the default command if
 *  none of the other commands is active.
 *
 *************************************************************************************************/
 reg op_ands_c2; //net: 1574
 reg op_eors_c2; //net: 982
 reg op_ors_c2;  //net: 88
 reg op_srs_c2;  //net: 73
 reg op_sums_c2; //net: 1216
 wire op_eors = pla[29]; //net: 1689 (1623 twice negated); pla[29]: op-T0-eor (exclusive or)
 wire op_ors = pla[32] | ~rdy; //net: 1145; pla[32]: op-T0-ora
 wire op_srs = pla[75] | (pla[76] & shift_inc_dec_mem_c1); //net: 934; shift right; pla[75,76]: op-T0-shift-right-a, op-shift-right
 wire op_sums = ~(op_ands | op_eors | op_ors | op_srs); //net: 1196

 /*************************************************************************************************
 *
 *                                      add_adl
 * Drive the contents of the adder hold register onto the address data low bus
 *
 *************************************************************************************************/
 //pla[16,84-89]: op-T5-rti, op-T5-rts, op-T4, op-T3, op-T0-brk/rti, op-T0-jmp, op-T5-ind-x
 wire no_adl = ~(pla[26] | pla[84] | pla[85] | pla[86] | pla[87] | pla[88] | pla[89]); //net: 256
 wire pre_add_adl = ~(adh_math | no_adl); //net: 25

 /*************************************************************************************************
 *
 *                                      add_sb06 & add_sb7
 * add_sb06 = Drive the contents of the adder hold register bits 0-6 onto the special bus bits 0-6
 * add_sb7  = Drive the contens of the adder hold register bit 7 on the special bus bit 7
 *
 * Most of the time add_sb06 and add_sb7 work in unison to load the alu results onto the special bus.
 * However if the carry flag is set and we are doing a rotate right (ROR) operation, add_sb7 will stay
 * low so bit 7 of the special bus remains pulled up to reflect a 1.
 *
 *************************************************************************************************/
 //add_sb06
 //pla[56]: op-T5-jsr
 wire pre_add_sb06_n = ~(adh_math | t_res_1_c1 | shift_inc_dec_mem_rdy_c2_c1 | pla[56] | stack_op_rdy); //net: 1130

 //add_sb7
 /*
 * need_sb7_c1; net: 1175 needed for add_sb7
 */
 reg need_sb7_c1; //net: 1175
 reg need_sb7_c1_c2; // net: 685
 reg carry_flag_c2; //net: 1714
 reg rdy_srs_c2; //net: 1008
 wire rdy_srs = rdy_c1 & srs; //net: 169
 wire carry_srs = ~carry_flag_c2 & rdy_srs_c2;
 //since need_sb7_n depends on a circular path with need_sb7_c1_c2 we need a few clock cycles to stabilize
 wire need_sb7_n = (need_sb7_c1_c2 === 1'bx) ? 1'b1 : ~(carry_srs | (~rdy_srs_c2 & need_sb7_c1_c2)); //net: 262

 //add_sb7
 reg srs_c2;  //net: 73
 reg srs_c2_c1_n; //net: 785
 //pla[75,76]: op-T0-shift-right-a, op-shift-right
 wire srs = pla[75] | (shift_inc_dec_mem_c1 & pla[76]);  //net: 934; shift right
 wire drive_sb7 = ~(need_sb7_c1 | srs_c2_c1_n | ~pla[27]); //net: 267; pla[27] = op-ror
 wire pre_add_sb7 = ~(pre_add_sb06_n | drive_sb7); //net: 80

 /*************************************************************************************************
 *
 *                                       p_db & db_p
 * p_db = Drive contents of status register onto internal data bus.
 * db_p = Set the carry, zero, and interrupt flags to bits 0, 1, and 2 of the internal databus respectively.
 *   NOTE: The Hanson block diagram has individual signals: DB0_C, DB1_C, and DB2_I but they are all driven by the
 *   same signal, net: 781, so we combine them all and name the common signal: db_p.
 *
 * p_db is asserted during breaks (rest and interrupts) and when pushing the staus on the stack (php)
 * db_p is asserted when returning from an interrupt and when pulling status from the stack (plp)
 *
 *************************************************************************************************/
 //p_db net: 1042
 wire pre_p_db_n = ~(pla[98] | pla[99]); //net: 1391;  pla[98,99]: op-T4-brk, op-T2-php

 //db_p net: 781
 reg pd_load_n_c2; //net: 199
 wire pd_load_n = ~(pla[114] | pla[115]); //net: 327; pla[114,115]: op-T0-plp, x-op-T4-rti
 assign db_p = ~(~rdy | pd_load_n_c2); //net: 781

 /*************************************************************************************************
 *
 *                                       db7_n_flag
 * Set the negative_flag according to bit 7 of the internal databus
 *
 *************************************************************************************************/
 reg pla_109_c2; //net: 1673; pla[109] = op-T+-bit
 assign db7_n_flag = ~(pla_109_c2 | (~dbz_z_flag & pd_load_n_c2)); //net: 754

 /*************************************************************************************************
 *
 *                                       dbz_z_flag
 * Set Z flag if internal data bus equals zero, otherwise clear it.
 *
 *************************************************************************************************/
 wire z_test = ~z_test_n; //net: 885
 wire pre_dbz_z_n = ~(z_test | pla[109] | acr_c_flag); //net: 513; pla[109] = op-T+-bit

 /*************************************************************************************************
 *
 *                                       ir5_i_flag
 * Set the interrupt_flag according to instruction register bit 5. net: 1662
 * Active for CLI and SEI instructions which clear and set the interrupt disable flag.
 *
 *************************************************************************************************/
 wire pre_ir5_i_flag_n = ~pla[108]; //net: 1065; pla[108] = op-T0-cli/sei

 /*************************************************************************************************
 *
 *                                        carry flag:
 *                              db0_c_flag & ir5_c_flag & acr_c_flag
 * db0_c_flag = Set carry flag according to bit 0 of internal data bus: net 507
 * ir5_c_flag = Set carry flag according it instruction register 5 bit. net: 253
 * acr_c_flag = Set carry_flag according to alu carry_out. net: 954
 *
 *************************************************************************************************/
 //db0_c_flag
 wire pre_db0_c_flag_n = ~(db_p | op_srs); //net: 1601
 //ir5_c_flag
 wire pre_ir5_c_flag_n = ~pla[110];  //net: 889; pla[110] = op-T0-clc/sec

//acr_c_flag
//pla[112,116-119, 107]: x-op-T+-adc/sbc, op-T+-cmp, op-T+-cpx/cpy-abs, op-T+-asl/rol-a, op-T+-cpx/cpy-imm/zp, op-asl/rol
 wire pre_acr_c_flag_n = ~(pla[112] | pla[116] | pla[117] | pla[118] | pla[119] | (pla[107] & shift_inc_dec_mem_rdy_c2_c1)); //net: 252


 /*************************************************************************************************
 *
 *                                       ir5_d_flag
 * Set the dmode_flag (decimal mode flag) according to instruction register bit 5. net: 1492
 * Active for CLD and SED instructions which clear and set the decimal mode flag.
 *
 *************************************************************************************************/
 wire pre_ir5_d_flag_n = ~pla[120]; //net: 774; pla120 = op-T0-cld/sed

 /*************************************************************************************************
 *
 *                                      Overflow flag
 *
 * db6_v_flag = Set the overflow_flag according to bit 6 of the internal databus.
 * avr_v_flag = Set the overflow flag according to the alu overflow output
 * set_v_flag = Set the overflow flag
 * clr_v_flag = Clear the overflow flag
 *
 *************************************************************************************************/
 //db6_v_flag; net: 1111
 reg pla113_c2;
 assign db6_v_flag = ~(pd_load_n_c2 & ~pla113_c2); //net: 1111

 //avr_v_flag; net: 1436
 wire pre_avr_v_flag = pla[112]; //net: 1155; pla[112] = x-op-T+-adc/sbc

 //set_v_flag
 reg so_n_c1; //net: 1024
 reg so_n_c1_c2; //net: 1699
 reg so_n_c1_c2_c1_n; //net: 1274
 wire pre_set_v_flag = ~(so_n_c1 | so_n_c1_c2_c1_n); //net: 1069

 //clr_v_flag
 wire pre_clr_v_flag = pla[127]; //net: 1164; pla[127] = op-clv

/*************************************************************************************************
 *
 *                          RW_N
 * read memory if high, write memory if low.
 *
 * we write if we are doing any of the following:
 *  - a memory store operation
 *  - a memory shift operation
 *  - writing to the stack due to a stack push or interrupt
 *  - saving the current program counter (due to jsr, branch, etc)
 *
 *************************************************************************************************/
 //RW_N; net: 1156 (buffer of 834)
 reg mem_write_n_c2; //net: 1131
 wire pch_or_pcl_db = ~(pre_pch_db_n & pre_pcl_db_n_c1); //net: 1642; driving db bus with pch or pcl
 //pla[98, 100]: op-T4-brk, op-T2-php/pha
 wire mem_write_n = ~(shift_inc_dec_mem_c1 | shift_inc_dec_mem_rdy_c2_c1 | pla[98] | pla[100] | store | pch_or_pcl_db); //net: 1352
 wire mem_write_rdy = ~mem_write_n_c2 & rdy & ~res_g; //net: 187

 /*************************************************************************************************
  *
  *                          latched signals on clk_1 or clk_2
  *
  *************************************************************************************************/

  /*
   * latch signals on clk_1
   */
  always @(*)
  if (clk_1)
    begin
      rdy_c1 <= rdy;
      rdy_c2_c1 <= rdy_c2;
      t_res_1_c1 <= t_res_1;
      t_res_x_c1 <= t_res_x;
      alu_cout_held_if_not_rdy_c1 <= alu_cout_held_if_not_rdy;
      shift_inc_dec_mem_c1 <= shift_inc_dec_mem;
      shift_inc_dec_mem_rdy_c2_c1 <= shift_inc_dec_mem_rdy_c2;
      short_circuit_n_c1 <= short_circuit_n;
      branch_back_c1 <= branch_back;
      RW_N <= ~mem_write_rdy;
      b_out_n_c1 <= b_out_n;
      short_circuit_branch_add_c1 <= short_circuit_branch_add;
      inc_pc_c_c1 <= inc_pc_c;
      pre_pcl_db_n_c1 <= ~pre_pcl_db;
      alu_cin_n <= pre_alu_cin_n;
      alu_ands <= op_ands_c2;
      alu_eors <= op_eors_c2;
      alu_ors <= op_ors_c2;
      alu_srs <= op_srs_c2;
      alu_sums <= op_sums_c2;
      srs_c2_c1_n <= ~srs_c2;
      need_sb7_c1 <= ~need_sb7_n;
      so_n_c1 <= SO_N;
      so_n_c1_c2_c1_n <= ~so_n_c1_c2;
      daa_n <= pre_daa_n_c2;
      dsa_n <= pre_dsa_n_c2;
    end

  /*
   * latch signals on clk_2
   */
  always @(*)
  if (clk_2)
    begin
      rdy_c2 <= rdy;
      rdy_c1_c2 <= rdy_c1;
      res_p_c2 <= res_p;
      ind_y_or_abs_idx <= ~(pla[91] | pla[92]);
      alu_cout_held_if_not_rdy_c1_c2 <= alu_cout_held_if_not_rdy_c1;
      op_shift_inc_dec_mem_c2 <= op_shift_inc_dec_mem;
      shift_inc_dec_mem_rdy_c2 <= shift_inc_dec_mem_rdy;
      shift_inc_dec_mem_c1_c2 <= shift_inc_dec_mem_c1;
      pre_fetch_n_c2 <= pre_fetch_n;
      force_t_res_x_c2 <= force_t_res_x;
      t2_br_c2 <= pla[80]; //pla[80] is the same as net 967 (aka nnT2BR)
      op_t3_branch_rdy_c2 <= op_t3_branch_rdy;
      branch_back_c1_c2 <= branch_back_c1;
      short_circuit_hold_c2 <= short_circuit_hold;
      dl_db <= ~pre_dlb_db_n;
      dl_adl <= ~pre_dl_adl_n;
      dl_adh <= ~pre_dl_adh_n;
      zero_adh0 <= ~pre_dl_adl_n;  //same as dl_adl
      zero_adh17 <= ~pre_zero_adh17_n;
      pre_pch_db_n_c2 <= pre_pch_db_n;
      pch_db <= ~pre_pch_db_n;
      pcl_db <= ~pre_pcl_db_n_c1;
      sb_adh <= ~pre_sb_adh_n;
      pre_adh_pch_n_c2 <= pre_adh_pch_n;
      adh_abh <= ~pre_adh_abh_n;
      adl_abl <= ~pre_adl_abl_n;
      pcl_adl <= ~pre_pcl_adl_n;
      pre_adl_pcl_n_c2 <= pre_adl_pcl_n;
      pre_pcl_pcl_n_c2 <= pre_pcl_pcl_n;
      pre_sb_ac_n_c2 <= pre_sb_ac_n;
      pre_ac_db_n_c2 <= pre_ac_db_n;
      pre_ac_sb_n_c2 <= pre_ac_sb_n;
      pre_sb_x_n_c2 <= pre_sb_x_n;
      pre_x_sb_n_c2 <= pre_x_sb_n;
      pre_sb_y_n_c2 <= pre_sb_y_n;
      pre_y_sb_n_c2 <= pre_y_sb_n;
      next_pc_n_c2 <= next_pc_n;
      pch_adh <= ~pre_pch_adh_n;
      sb_db <= ~pre_sb_db_n;
      s_adl <= ~pre_s_adl_n;
      pre_sb_s_n_c2 <= pre_sb_s_n;
      s_sb <= ~pre_s_sb_n;
      mem_write_n_c2 <= mem_write_n;
      pre_adl_add_n_c2 <= pre_adl_add_n;
      pre_not_db_add_n_c2 <= pre_not_db_add_n;
      pre_db_add_n_c2 <= pre_db_add_n;
      bb_or_cpxy_or_inxy_c2 <= bb_or_cpxy_or_inxy;
      inc_sb_c2 <= inc_sb;
      return_and_adl_add_c2 <= return_and_adl_add;
      c_set_c2 <= c_set;
      op_ands_c2 <= op_ands;
      op_eors_c2 <= op_eors;
      op_ors_c2 <= op_ors;
      op_srs_c2 <= op_srs;
      op_sums_c2 <= op_sums;
      add_adl <= pre_add_adl;
      add_sb06 <= ~pre_add_sb06_n;
      add_sb7 <= pre_add_sb7;
      srs_c2 <= srs;
      rdy_srs_c2 <= rdy_srs;
      carry_flag_c2 <= carry_flag;
      need_sb7_c1_c2 <= need_sb7_c1;
      pre_zero_add_n_c2 <= pre_zero_add_n;
      p_db <= ~pre_p_db_n;
      pd_load_n_c2 <= pd_load_n;
      pla_109_c2 <= pla[109];
      ir5_i_flag <= ~pre_ir5_i_flag_n;
      db0_c_flag <= ~pre_db0_c_flag_n;
      ir5_c_flag <= ~pre_ir5_c_flag_n;
      acr_c_flag <= ~pre_acr_c_flag_n;
      dbz_z_flag <= ~pre_dbz_z_n;
      ir5_d_flag <= ~pre_ir5_d_flag_n;
      pla113_c2 <= pla[113];
      avr_v_flag <= pre_avr_v_flag;
      set_v_flag <= pre_set_v_flag;
      clr_v_flag <= pre_clr_v_flag;
      so_n_c1_c2 <= so_n_c1;
      pre_daa_n_c2 <= pre_daa_n;
      pre_dsa_n_c2 <= pre_dsa_n;
    end

endmodule
