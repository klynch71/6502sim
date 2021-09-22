/*
*                                     PROCESSOR_STATUS_REGISTER
*
*                                   Copyright (c) 2021 Kevin Lynch
*                             This file is licensed under the MIT license
*
* The processor status register holds processor status and outputs the status flags to
* the random control logic.
*
* Note: the Hanson block diagram has DB0/C, DB1/Z, and DB2/I coming into the status register
* to set the corresponding flags acoording to db bits 0, 1, & 2.  Since the random_control_logic
* doesn't need the entire db bus, we just receive db_pd from the random control logic which indicates
* that we should set the carry, zero, and interrupt flags according the the proper db bits (0-2).
*
* The status bits are as follows:
* bit 7: N = Negative (1 = negative)
* bit 6: V = Overflow (1 = overflow)
* bit 5: 1 (not used - always 1)
* bit 4: B = Break command (1 = break)
* bit 3: D = Decimal mode (1 = true)
* bit 2: I = IRQ disable (1 = disable)
* bit 1: Z = Zero (1 = result is zero)
* bit 0: C = Carry (1 = true)
*/
module processor_status_register(
  input clk_1,
  input clk_2,
  input [7:0] db_in,    //internal data bus
  input break_done,     //break is done (aka brk_6e); net: 1382
  input b_out_n,        //net: 827; break in progress
  input alu_overflow_n, //net: 1308
  input alu_carry_n,    //net: 206
  input ir5_n,          //net: 270 (or 1394); opposite polarity of instruction register bit 5
  input db_p,           //net: 781; set Z, I, and D bit according to bits 1, 2, and 3 of db_in
  input db7_n_flag,     //net: 754; set the negative_flag according to bit 7 of db_in
  input db6_v_flag,     //net: 1111; set the overflow_flag accofding to bit 6 of db_in
  input avr_v_flag,     //net: 1436; set overflow flag according to alu overflow bit
  input set_v_flag,     //net: 1177; set the overflow flag
  input clr_v_flag,     //net: 587; clear the overflow flag
  input ir5_d_flag,     //net: 1492; set the decimal mode flag according to ir[5] bit.
  input ir5_i_flag,     //net: 1662; set interrupt_flag according to ir[5] bit.
  input dbz_z_flag,     //net: 755; set zero_flag according to db_in equalling zero or not
  input db0_c_flag,     //net: 507; set carry flag according to db_in 0 bit.
  input ir5_c_flag,     //net: 253; set carry flag according to ir[5] bit
  input acr_c_flag,     //net: 954: set carry flag according to alu carry bit
  input p_db,           //net: 1042; drive status onto internal databus.
  output [7:0] db_out,       //internal data bus
  output reg negative_flag,  //net: 69
  output reg overflow_flag,  //net: 1625
  output reg dmode_flag,     //net: 348
  output reg zero_flag,      //net: 627
  output reg interrupt_flag, //net: 1553
  output reg carry_flag      //net: 32
  );

  //status register out to internal databus
  assign db_out[7] = (p_db) ? negative_flag  : 1'bz;
  assign db_out[6] = (p_db) ? overflow_flag  : 1'bz;
  assign db_out[5] = (p_db) ? 1'b1           : 1'bz; //not used, always 1
  assign db_out[4] = (p_db) ? b_out_n        : 1'bz;
  assign db_out[3] = (p_db) ? dmode_flag     : 1'bz;
  assign db_out[2] = (p_db) ? interrupt_flag : 1'bz;
  assign db_out[1] = (p_db) ? zero_flag      : 1'bz;
  assign db_out[0] = (p_db) ? carry_flag     : 1'bz;

  /*************************************************************************************************
   *
   *                                    negative_flag
   *
   *************************************************************************************************/
   reg negative_flag_n_c2; //net: 1442
   wire db_neg_n = ~db_in[7]; //net: 1200; internal data bus is negative (ie; bit 7 set)
   wire set_neg_per_db7 = db_neg_n & db7_n_flag;
   wire hold_neg_value_n = negative_flag_n_c2 & ~db7_n_flag;
   wire pre_negative_flag = ~(set_neg_per_db7 | hold_neg_value_n); //net: 1181


   /*************************************************************************************************
    *
    *                                    overflow_flag
    *
    *************************************************************************************************/
    reg alu_overflow_n_c2; //net: 1245
    reg overflow_flag_n_c2; //net: 44
    wire set_v_flag_per_db6 = ~db_in[6] & db6_v_flag;    //set flag according to bit 6 of db_in
    wire set_v_flag_per_avr = avr_v_flag & alu_overflow_n_c2;
    wire hold_v_flag = ~(avr_v_flag | set_v_flag | db6_v_flag); //net: 1614
    wire holf_v_flag_value_n = hold_v_flag & overflow_flag_n_c2;
    wire pre_overflow_flag = ~(set_v_flag_per_db6 | set_v_flag_per_avr | holf_v_flag_value_n | clr_v_flag); //net: 299

   /*************************************************************************************************
    *
    *                                    dmode_flag
    * decimal mode flag
    *
    *************************************************************************************************/
    reg dmode_flag_n_c2; //net: 99
    wire set_dmode_per_db3 = ~db_in[3] & db_p;    //set flag according to bit 3 of db_in
    wire set_dmode_per_ir5 = ir5_d_flag & ir5_n;  //for SED and CLD opcodes
    wire hold_dmode_flag = ~(ir5_d_flag | db_p); //net: 1457
    wire hold_dmode_value_n = hold_dmode_flag & dmode_flag_n_c2;
    wire pre_dmode_flag = ~(set_dmode_per_db3 | set_dmode_per_ir5 | hold_dmode_value_n); //net: 1495

  /*************************************************************************************************
   *
   *                                    interrupt_flag
   * Interrupt mask flag
   *
   *************************************************************************************************/
   reg int_flag_or_brk_done_n_c2; //net: 1078
   wire int_flag_or_brk_done_n = ~(interrupt_flag | break_done); //net :334
   wire set_int_per_db2 = ~db_in[2] & db_p;
   wire set_int_per_ir5 = ir5_i_flag & ir5_n;
   wire hold_int_flag = ~(ir5_i_flag | db_p); //net: 553
   wire hold_int_value_n = hold_int_flag & int_flag_or_brk_done_n_c2;
   wire pre_int_flag = ~(set_int_per_db2 | set_int_per_ir5 | hold_int_value_n); //net: 845

  /*************************************************************************************************
   *
   *                                    zero_flag
   *
   *************************************************************************************************/
   wire db_is_zero = (db_in == 0);
   reg zero_flag_n_c2; //net: 1607
   wire hold_zero_flag = ~(dbz_z_flag | db_p); //net: 1170
   wire hold__zero_value_n = hold_zero_flag & zero_flag_n_c2;
   wire set_zero_if_db_zero = ~db_is_zero & dbz_z_flag;
   wire set_zero_per_db1 = ~db_in[1] & db_p;
   wire pre_zero_flag = ~(set_zero_if_db_zero | hold__zero_value_n | set_zero_per_db1); //net: 566

   /*************************************************************************************************
    *
    *                                    carry_flag
    *
    *************************************************************************************************/
    reg carry_flag_n_c2; //net: 1051
    wire hold_carry_flag = ~(acr_c_flag | ir5_c_flag | db0_c_flag); //net: 279
    wire hold_carry_value_n = hold_carry_flag & carry_flag_n_c2;
    wire set_carry_per_db0 = db0_c_flag & ~db_in[0];
    wire set_carry_per_alu = acr_c_flag & alu_carry_n;
    wire set_carry_per_ir5 = ir5_c_flag & ir5_n;
    wire pre_carry_flag = ~(hold_carry_value_n | set_carry_per_db0 | set_carry_per_alu | set_carry_per_ir5); //net: 1082

   /*************************************************************************************************
    *
    *                                      latched signals
    *
    *************************************************************************************************/

    /*
     * latch signals on clk_1
     */
    always @(*)
      if (clk_1)
        begin
          //the real 6502 will stabilize to either 1 or 0, but we will stay in indefinte x so we check here
          negative_flag <= (pre_negative_flag === 1'bx) ? 1'b0 : pre_negative_flag;
          overflow_flag <= (pre_overflow_flag === 1'bx) ? 1'b0 : pre_overflow_flag;
          dmode_flag <= (pre_dmode_flag === 1'bx) ? 1'b0 : pre_dmode_flag;
          zero_flag <= (pre_zero_flag === 1'bx) ? 1'b0: pre_zero_flag;
          interrupt_flag <= (pre_int_flag === 1'bx) ? 1'b0: pre_int_flag;
          carry_flag <= (pre_carry_flag === 1'bx) ? 1'b0: pre_carry_flag;
        end

    /*
     * latch signals on clk_2
     */
    always @(*)
      if (clk_2)
        begin
          negative_flag_n_c2 <= ~negative_flag;
          alu_overflow_n_c2 <= alu_overflow_n;
          overflow_flag_n_c2 <= ~overflow_flag;
          dmode_flag_n_c2 <= ~dmode_flag;
          zero_flag_n_c2 <= ~zero_flag;
          int_flag_or_brk_done_n_c2 <= int_flag_or_brk_done_n;
          carry_flag_n_c2 <= ~carry_flag;
        end

endmodule
