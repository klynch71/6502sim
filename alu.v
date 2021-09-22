/*
 *                                                 ALU
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 * Represents the arithmetic logic unit (ALU)
 * The ALU peforms arithmetic on two inputs, a and b, and puts the results in result_n.
 * result_n holds the inverted results of the final answer.  Example 1 + 2 = 3 = 0000 0011 so
 * result_n would be 1111 1100. The result_n will be flipped to the proper answer in the Adder Hold Register.
 *
 * The arithetic to perform is determined by the inputs:
 *   sums = a + b  (plus)
 *   ands = a & b  (and)
 *   eors = a ^ b  (exclusive or)
 *    ors = a | b  (or)
 *    srs = logical shift right
 *
 * The 6502 can perform decimal addition and subtraction, but this is not accomplished by the ALU. Instead,
 * the output of the ALU is modified by the Decimal Adjust Adders outside the ALU when doing decimal operations.
 */
module alu(clk_2, sums, ands, eors, ors, srs, a, b, alu_cin_n, daa_n, dsa_n, overflow_n, half_carry, alu_cout_n, result_n);
    input clk_2;
    input sums;            //net: 921
    input ands;            //net: 574
    input eors;            //net: 1666
    input ors;             //net: 59
    input srs;             //net: 362
    input [7:0] a;         //a side input
    input [7:0] b;         //b side input
    input alu_cin_n;       //net: 1165; alu carry in (active low)
    input daa_n;           //net: 1201; decimal add adjust
    input dsa_n;           //net: 725; decimal subtract adjust
    output overflow_n;     //net: 1308; overflow out (active low)
    output half_carry;     //net: 78; half carry between bits 3 and 4 (active high)
    output alu_cout_n;     //net: 412
    output [7:0] result_n;

    assign half_carry = ~carry_out[3];  //carry out from lower nibble

    //partial results
    wire [7:0] a_nor_b = ~(a | b);
    wire [7:0] a_nand_b = ~(a & b);
    wire [7:0] a_neor_b = ~(a_nand_b & ~a_nor_b);   //not exclusive or
    //for shift right, the cpu will load the data to shift into both the a and b side registers and then shift a_nand_b
    //Zero is put into the high bit, but remember our result_n in the ALU has opposite polarity so shift in 1
    wire [7:0] shifted = {1'b1, a_nand_b[7], a_nand_b[6], a_nand_b[5], a_nand_b[4], a_nand_b[3], a_nand_b[2], a_nand_b[1]};

    /*************************************************************************************************
    *
    *                                        decimal carry
    * dc34 = decimal half carry from bit 3 to 4
    * dc78 = decimal full carry from bit 7
    *
    *************************************************************************************************/
    //dc34 decimal half carry
    wire da_c01 = ~(a_nor_b[0] | (a_nand_b[0] & alu_cin_n)); //net: 623; decimal adjust carry bit 0 to 1
    wire net_388 = ~(~a_neor_b[2] | ~a_neor_b[1] | ~a_nand_b[1] | da_c01); //net: 388
    wire not_da_or_and1 = ~(da_c01 & ~a_nand_b[1]); //net: 319
    wire not_da_or_and1_or_nor2 = not_da_or_and1 | a_nor_b[2]; //net: 972
    wire neor3_and_nand2 = a_neor_b[3] & a_nand_b[2]; //net: 1610
    wire dc34 = ~(daa_n | (net_388 & not_da_or_and1_or_nor2) | (neor3_and_nand2 & not_da_or_and1_or_nor2)); //net: 1372

    //dc78 decimal full carry
    wire a_nand_b_or_c_45 = a_nand_b[5] | carry_out[4]; //net 757
    wire possible_dec_adjust = a_nand_b_or_c_45 | a_neor_b[6]; //net: 1030
    wire nand6_and_neors7 = a_nand_b[6] & a_neor_b[7]; //net: 269
    wire net_570 = a_nand_b[5] & a_neor_b[5] & a_neor_b[6] & ~carry_out[4];
    wire dc78 = ~(daa_n | (nand6_and_neors7 & possible_dec_adjust) | (possible_dec_adjust & net_570)); //net: 333

    /*************************************************************************************************
    *
    *                                       carry chain
    *
    *************************************************************************************************/
    wire [7:0] carry_out;
    assign carry_out[0] = ~(a_nor_b[0] | (alu_cin_n & a_nand_b[0]));  //net: 1285; aka c01
    assign carry_out[1] = ~(~a_nand_b[1] | (carry_out[0] & ~a_nor_b[1])); //net: 1112; aka ~c12
    assign carry_out[2] = ~(a_nor_b[2] | (carry_out[1] & a_nand_b[2]));  //net: 1023; aka c23
    assign carry_out[3] = ~(dc34 | ~a_nand_b[3] | (carry_out[2] & ~a_nor_b[3])); //net: 1424; aka ~c34, aka half_carry_n
    assign carry_out[4] = ~(a_nor_b[4] | (carry_out[3] & a_nand_b[4]));  //net: 142; aka c45
    assign carry_out[5] = ~(~a_nand_b[5] | (carry_out[4] & ~a_nor_b[5])); //net: 427; aka c56_n
    assign carry_out[6] = ~(a_nor_b[6] | (carry_out[5] & a_nand_b[6]));  //net: 1314; aka c67
    assign carry_out[7] = ~(~a_nand_b[7] | (carry_out[6] & ~a_nor_b[7])); //net: 1327; aka ~c78

    //the final alu carry output depends on both the decimal and binary carries
    reg dc78_c2; //net: 164; decimal carry
    reg c78_c2;  //net: 560; binary carry
    assign alu_cout_n = ~(dc78_c2 | c78_c2);  //net: 412

    /*************************************************************************************************
    *
    *                                        a_plus_b (plus carry in)
    *
    *************************************************************************************************/
    wire [7:0] a_plus_b;
    assign a_plus_b[0] = a_neor_b[0] ^ ~alu_cin_n;      //net: 371;
    assign a_plus_b[1] = ~a_neor_b[1] ^ ~carry_out[0];  //net: 965;
    assign a_plus_b[2] = a_neor_b[2] ^ ~carry_out[1];   //net: 22;
    assign a_plus_b[3] = ~a_neor_b[3] ^ ~carry_out[2];  //net: 274;
    assign a_plus_b[4] = a_neor_b[4] ^ ~carry_out[3];   //net: 651;
    assign a_plus_b[5] = ~a_neor_b[5] ^ ~carry_out[4];  //net: 486;
    assign a_plus_b[6] = a_neor_b[6] ^ ~carry_out[5];   //net: 1197;
    assign a_plus_b[7] = ~a_neor_b[7] ^ ~carry_out[6];  //net: 532;

    /*************************************************************************************************
    *
    *                                     result_n
    * result_n will be inverted after being clocked by clk_2 in the adder hold reg
    *
    *************************************************************************************************/
    assign result_n = (sums) ? a_plus_b :
                      (ands) ? a_nand_b :
                      (eors) ? a_neor_b :
                      (ors)  ? a_nor_b :
                      (srs)  ? shifted :
                      1'bx;

  /*************************************************************************************************
   *
   *                                  overflow_out_n
   * Overflow occurs when an operation on two signed numbers results in an overflow.
   *
   *************************************************************************************************/
   //carry_out[6] is the carry from bit 6 of the alu to bit 7 of the alu
   assign overflow_n = ~(~(a_nand_b[7] | carry_out[6]) | (a_nor_b[7] & carry_out[6])); //net: 1308

   /*************************************************************************************************
    *
    *                                  latch signals on clk_2
    *
    *************************************************************************************************/
    always @(*)
      if (clk_2)
        begin
          dc78_c2 <= dc78;
          c78_c2 <= ~carry_out[7];
        end


 endmodule
