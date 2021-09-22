/*
*  represents the decimal adjust adders
*  The decimal adjust adders modify the output of the ALU when in decimal mode.
*/
module decimal_adjust_adder(clk_2, daa_n, dsa_n, half_carry, alu_cout_n, alu_result, adjust_in, adjust_out);
  input clk_2;
  input daa_n; //net: 1201; decimal add adjust
  input dsa_n; //net: 725; decimal subtract adjust
  input half_carry; //net: 78; carry from bit 3 to 4 in alu; aka c34
  input alu_cout_n;  //net: 412 ; carry out from alu
  input [7:0] alu_result; //latched alu result from adder hold register
  input [7:0] adjust_in;   //special bus
  output [7:0] adjust_out; //to accumulator

  /*
   * Decimally adjusted outputs.
   * Bits 0 & 4 are never adjusted.  The other bits get flipped if their flip_n is low.
   * In the real 6502 this is accomplished through a series of not, nors, and nands as follows for bit 1:
   *  not(not_adjust_in, adjust_in);    //net: 320 for slice 1
   *  nor(flip, not_adjust_in, flip_n);   //net: 735 for bit 1
   *  and(not_adjust_in_and_flip_n, not_adjust_in, flip_n);  //input to nor gate 1009
   *  nor(adjust_out, flip, not_adjust_in_and_flip_n);  //net: 1009 for bit 1
   *
   *  The other bits would be the same, but we will use behavioral modeling here rather than instantiate a slice for each bit.
   *  The heart of the matter is to determine which bits need to flip which is shown below via flip_n.
  */
  wire [7:0] flip_n;
  assign flip_n[0] = 1; //not used
  assign flip_n[4] = 1; //not used
  assign adjust_out[0] = adjust_in[0];
  assign adjust_out[1] = (flip_n[1]) ? adjust_in[1] : ~adjust_in[1];
  assign adjust_out[2] = (flip_n[2]) ? adjust_in[2] : ~adjust_in[2];
  assign adjust_out[3] = (flip_n[3]) ? adjust_in[3] : ~adjust_in[3];
  assign adjust_out[4] = adjust_in[4];
  assign adjust_out[5] = (flip_n[5]) ? adjust_in[5] : ~adjust_in[5];
  assign adjust_out[6] = (flip_n[6]) ? adjust_in[6] : ~adjust_in[6];
  assign adjust_out[7] = (flip_n[7]) ? adjust_in[7] : ~adjust_in[7];

  /*
  * flip_n for bit 1 (bit 0 does not get adjusted)
  */
  reg adjust_for_add_1_c2; //net: 600
  reg adjust_for_sub_1_c2; //net: 8
  wire adjust_for_add_1_n = ~(~daa_n & half_carry); //net: 695
  wire adjust_for_sub_1 = ~(dsa_n | half_carry); //net: 1179
  assign flip_n[1] = ~(adjust_for_sub_1_c2 | adjust_for_add_1_c2);  //net: 36

  /*
  * flip_n for bit 2
  */
  wire adjust_for_add_2 = adjust_for_add_1_c2 & ~alu_result[1];
  wire adjust_for_sub_2 = adjust_for_sub_1_c2 & alu_result[1];
  assign flip_n[2] = ~(adjust_for_add_2 | adjust_for_sub_2); //net: 1613

  /*
  * flip_n for bit 3
  */
  wire alu_1_or_2 = alu_result[1] | alu_result[2]; //net: 986
  wire alu_1_and_2 = alu_result[1] & alu_result[2]; //net: 867
  wire adjust_for_add_3 = adjust_for_add_1_c2 & alu_1_or_2;
  wire adjust_for_sub_3 = adjust_for_sub_1_c2 & ~alu_1_and_2;
  assign flip_n[3] = ~(adjust_for_add_3 | adjust_for_sub_3); //net: 345

  /*
  * flip_n for bit 5 (bit 4 does not get adjusted)
  */
  reg daa_n_c2;  //net: 1218
  reg dsa_n_c2;  //net: 838
  wire adjust_for_add_5 = ~(alu_cout_n | daa_n_c2); //net: 1257
  wire adjust_for_sub_5 = ~(dsa_n_c2 | ~alu_cout_n); //net: 811
  assign flip_n[5] = ~(adjust_for_add_5 | adjust_for_sub_5); //net: 753

  /*
  * flip_n for bit 6
  */
  wire adjust_for_add_6 = adjust_for_add_5 & ~alu_result[5];
  wire adjust_for_sub_6 = adjust_for_sub_5 & alu_result[5];
  assign flip_n[6] = ~(adjust_for_add_6 | adjust_for_sub_6); //net: 739

  /*
  * flip_n for bit 7
  */
  wire alu_5_or_6 = alu_result[5] | alu_result[6]; //net: 233
  wire alu_5_and_6 = alu_result[5] & alu_result[6]; //net: 867
  wire adjust_for_add_7 = adjust_for_add_5 & alu_5_or_6;
  wire adjust_for_sub_7 = adjust_for_sub_5 & ~alu_5_and_6;
  assign flip_n[7] = ~(adjust_for_add_7 | adjust_for_sub_7); //net: 1205

  /*
  * latch signals on clk_out2
  */
  always @(*)
    if (clk_2) begin
      adjust_for_add_1_c2 <= ~adjust_for_add_1_n;
      adjust_for_sub_1_c2 <= adjust_for_sub_1;
      daa_n_c2 <= daa_n;
      dsa_n_c2 <= dsa_n;
    end


endmodule
