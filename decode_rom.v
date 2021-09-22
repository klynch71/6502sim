/*
 *                                           DECODE_ROM
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 * The decode_rom is really more of a programmable logic arary.
 * The block diagram has 21 inputs and 130 outputs.  The inputs
 * were: ir[7:0], ~ir[7:0], and timing_n[5:0]. ir[1] & ir[0] were replaced
 * with (ir[1] or ir[0]).  If ir[0] were not used alone then we could
 * replace ir0 and ir1 with just the ir1_or_ir0 signal and we would have
 * 21 inputs per the block diagram.  However, ir[0] is used by itself in
 * PLA[129] so it seems we need 22 signal inputs.  Regardless, we are just
 * inputting the ir[7:0] bits into this module and creating the negatives
 * and the ir1_or_ir0 within this module.
 *
 * Of further note: in the visual6502.org source code name listing nodenames.js,
 * they have 131 pla entries but two of them are dupiicates: their pla97 and
 * pla121 have identical inputs.  The real 6502 probably needed to buffer
 * the signal due to layout.  Here we do not duplicate the signals so our
 * pla numbers after pla[96] will be one off from visual6502.org but the names
 * and net numbers are the same.
 *
 */
module decode_rom(ir, t_n, pla);
  input [7:0] ir;      //instruction register
  input [5:0] t_n;     //timing signals (active low)
  output [129:0] pla;  //Programmalble Logic Array outputs (active high)

  wire ir10;
  or(ir10, ir[1], ir[0]);  //ir10 = ir1 or ir0

  /*
   * 130 pla outputs.
   * Visual6502.org net numbers and names for each are in the comments.
   */
  nor(pla[0], ~ir[7], ir[6], ir[5], ~ir[2], ir10);  //1601: op-sty/cpy-mem
  nor(pla[1], t_n[3], ~ir[4], ir[3], ir[2], ~ir[0]);  //60: op-T3-ind-y
  nor(pla[2], t_n[2], ~ir[4], ~ir[3], ir[2], ~ir[0]);  //1512: op-T2-abs-y
  nor(pla[3], t_n[0], ~ir[7], ir[5], ir[4], ~ir[3], ir[2], ir10); //382: op-T0-iny/de
  nor(pla[4], t_n[0], ~ir[7], ir[6], ir[5], ~ir[4], ~ir[3], ir[2], ir10); //1173: x-op-T0-tya
  nor(pla[5], t_n[0], ~ir[7], ~ir[6], ir[5], ir[4], ir10); //1233: op-T0-cpy/iny
  nor(pla[6], t_n[2], ~ir[4], ~ir[2]); //258: op-T2-idx-x-xy
  nor(pla[7], ~ir[7], ir[6], ~ir[1]); //1562: op-xy
  nor(pla[8], t_n[2], ir[4], ir[3], ir[2], ~ir[0]); //84: op-T2-ind-x
  nor(pla[9], t_n[0], ~ir[7], ir[6], ir[5], ir[4], ~ir[3], ir[2], ~ir[1]); //1543: x-op-T0-txa
  nor(pla[10], t_n[0], ~ir[7], ~ir[6], ir[5], ir[4], ~ir[3], ir[2], ~ir[1]); //76: op-T0-dex
  nor(pla[11], t_n[0], ~ir[7], ~ir[6], ~ir[5], ir[4], ir10); //1658: op-T0-cpx/inx
  nor(pla[12], ~ir[7], ir[6], ir[5], ~ir[1]); //1540: op-from-x
  nor(pla[13], t_n[0], ~ir[7], ir[6], ir[5], ~ir[4], ~ir[3], ir[2], ~ir[1]); //245: op-T0-tsx
  nor(pla[14], t_n[0], ~ir[7], ir[6], ~ir[5], ~ir[1]); //985: op-T0-ldx/tax/tsx
  nor(pla[15], t_n[1], ~ir[7], ~ir[6], ir[5], ir[4], ~ir[3], ir[2], ~ir[1]); //786: op-T+-dex
  nor(pla[16], t_n[1], ~ir[7], ~ir[6], ~ir[5], ir[4], ~ir[3], ir[2], ir10); //1664: op-T+-inx
  nor(pla[17], t_n[0], ~ir[7], ir[6], ~ir[5], ~ir[4], ~ir[3], ir[2], ~ir[1]); //682: op-T0-tsx
  nor(pla[18], t_n[1], ~ir[7], ir[5], ir[4], ~ir[3], ir[2], ir10); //1482: op-T+-iny/dey
  nor(pla[19], t_n[0], ~ir[7], ir[6], ~ir[5], ~ir[2], ir10); //665: op-T0-ldy-mem
  nor(pla[20], t_n[0], ~ir[7], ir[6], ~ir[5], ir[4], ir10); //286:op-T0-tay/ldy-not-idx
  nor(pla[21], t_n[0], ir[7], ir[6], ~ir[5], ir[4], ir[3], ir[2], ir10);   //271: op-T0-jsr
  nor(pla[22], t_n[5], ir[7], ir[6], ir[5], ir[4], ir[3], ir[2], ir10);  //370: op-T5-brk
  nor(pla[23], t_n[0], ir[7], ir[5], ir[4], ~ir[3], ir[2], ir10); //net: 552); op-T0-php/pha
  nor(pla[24], t_n[4], ir[7], ~ir[6], ~ir[5], ir[4], ir[3], ir[2], ir10); //net: 1612); op-T4-rts
  nor(pla[25], t_n[3], ir[7], ~ir[5], ir[4], ~ir[3], ir[2], ir10); //net: 1487); op-T3-plp/pla
  nor(pla[26], t_n[5], ir[7], ~ir[6], ir[5], ir[4], ir[3], ir[2], ir10); //net: 784); op-T5-rti
  nor(pla[27], ir[7], ~ir[6], ~ir[5], ~ir[1]); //net: 244); op-ror
  nor(pla[28], t_n[2]); //net: 788); op-T2
  nor(pla[29], t_n[0], ir[7], ~ir[6], ir[5], ~ir[0]); //net: 1623); op-T0-eor
  nor(pla[30], ir[7], ~ir[6], ir[4], ~ir[3], ~ir[2], ir10); //net: 764); op-jmp
  nor(pla[31], t_n[2], ir[4], ~ir[3], ~ir[2]); //net: 1057); op-T2-abs
  nor(pla[32], t_n[0], ir[7], ir[6], ir[5], ~ir[0]); //net: 403); op-T0-ora
  nor(pla[33], t_n[2], ir[3]); //net: 204); op-T2-ADL/ADD
  nor(pla[34], t_n[0]); //net: 1273); op-T0
  nor(pla[35], t_n[2], ir[7], ir[4], ir[2], ir10); //net: 1582); op-T2-stack
  nor(pla[36], t_n[3], ir[7], ir[4], ir10); //net: 1031); op-T3-stack/bit/jmp
  nor(pla[37], t_n[4], ir[7], ir[6], ir[4], ir[3], ir[2], ir10); //net: 1031); op-T4-brk/jsr
  nor(pla[38], t_n[4], ir[7], ~ir[6], ir[5], ir[4], ir[3], ir[2], ir10); //net: 1031); op-T4-rti
  nor(pla[39], t_n[3], ir[4], ir[3], ir[2], ~ir[0]); //net: 1428); op-T3-ind-x
  nor(pla[40], t_n[4], ~ir[4], ir[3], ir[2], ~ir[0]); //net: 492); op-T4-ind-y
  nor(pla[41], t_n[2], ~ir[4], ir[3], ir[2], ~ir[0]); //net: 1204); op-T2-ind-y
  nor(pla[42], t_n[3], ~ir[4], ~ir[3]); //net: 58); op-T3-abs-idx
  nor(pla[43], ir[7], ~ir[5], ir[4], ~ir[3], ir[2], ir10); //net: 1520); op-plp/pla
  nor(pla[44], ~ir[7], ~ir[6], ~ir[5], ~ir[1]); //net: 324); op-inc/nop
  nor(pla[45], t_n[4], ir[4], ir[3], ir[2], ~ir[0]); //net: 1259); op-T4-ind-x
  nor(pla[46], t_n[3], ~ir[4], ir[3], ir[2], ~ir[0]); //net: 342); x-op-T3-ind-y
  nor(pla[47], ir[7], ~ir[6], ir[4], ir[3], ir[2], ir10); //net: 857); op-rti/rts
  nor(pla[48], t_n[2], ir[7], ir[6], ~ir[5], ir[4], ir[3], ir[2],  ir10); //net: 712); op-T2-jsr
  nor(pla[49], t_n[0], ~ir[7], ~ir[6], ir[4], ir10); //net: 1337); op-T0-cpx/cpy/inx/iny
  nor(pla[50], t_n[0], ~ir[7], ~ir[6], ir[5], ~ir[0]); //net: 1355); op-T0-cmp
  nor(pla[51], t_n[0], ~ir[7], ~ir[6], ~ir[5], ~ir[0]);//net: 787); op-T0-sbc
  nor(pla[52], t_n[0], ~ir[6], ~ir[5], ~ir[0]);//net: 575); op-T0-adc/sbc
  nor(pla[53], ir[7], ir[6], ~ir[5], ~ir[1]);//net: 1466); op-rol/ror
  nor(pla[54], t_n[3], ir[7], ~ir[6], ir[4], ~ir[3], ~ir[2], ir10);//net: 1381); op-T3-jmp
  nor(pla[55], ir[7], ir[6], ~ir[1]); //net: 546); op-shift
  nor(pla[56], t_n[5], ir[7], ir[6], ~ir[5], ir[4], ir[3], ir[2], ir10); //net: 776/1002);op-T5-jsr
  nor(pla[57], t_n[2], ir[7], ir[4], ir[2], ir10); //net: 157); op-T2-stack-access
  nor(pla[58], t_n[0], ~ir[7], ir[6], ir[5], ~ir[4], ~ir[3], ir[2], ir10); //net: 257); op-T0-tya
  nor(pla[59], t_n[1], ir[7], ~ir[0]); //net: 1243); op-T+-ora/and/eor/adc
  nor(pla[60], t_n[1], ~ir[6], ~ir[5], ~ir[0]); //net: 822); op-T+-adc/sbc
  nor(pla[61], t_n[1], ir[7], ir[4], ~ir[3], ir[2], ~ir[1]); //net: 1324); op-T+-shift-a
  nor(pla[62], t_n[0], ~ir[7], ir[6], ir[5], ir[4], ~ir[3], ir[2], ~ir[1]); //net: 179); op-T0-txa
  nor(pla[63], t_n[0], ir[7], ~ir[6], ~ir[5], ir[4], ~ir[3], ir[2], ir10); //net: 131); op-T0-pla
  nor(pla[64], t_n[0], ~ir[7], ir[6], ~ir[5], ~ir[0]); //net: 1420); op-T0-lda
  nor(pla[65], t_n[0], ~ir[0]); //net: 1342); op-T0-acc
  nor(pla[66], t_n[0], ~ir[7], ir[6], ~ir[5], ir[4], ~ir[3], ir[2], ir10); //net: 4; op-T0-tay
  nor(pla[67], t_n[0], ir[7], ir[4], ~ir[3], ir[2], ~ir[1]); //net: 1396; op-T0-shift-a
  nor(pla[68], t_n[0], ~ir[7], ir[6], ~ir[5], ir[4], ~ir[3], ir[2], ~ir[1]); //net: 167; op-T0-tax
  nor(pla[69], t_n[0], ir[7], ir[6], ~ir[5], ir[4], ~ir[2], ir10); //net: 303; op-T0-bit
  nor(pla[70], t_n[0], ir[7], ir[6], ~ir[5], ~ir[0]);  //net: 1504; op-T0-and
  nor(pla[71], t_n[4], ~ir[4], ~ir[3]); //net: 354; op-T4-abs-idx
  nor(pla[72], t_n[5], ~ir[4], ir[3], ir[2], ~ir[0]); //net: 1168; op-T5-ind-y
  nor(pla[73], t_n[0], ~ir[4], ir[3], ir[2], ir10); //net: 1721; op-branch-done
  nor(pla[74], t_n[2], ir[7], ~ir[6], ir[5], ir[4], ~ir[3], ir[2], ir10); //net: 1086; op-T2-pha
  nor(pla[75], t_n[0], ir[7], ~ir[6], ir[4], ~ir[3], ir[2], ~ir[1]); //net: 1074; op-T0-shift-right-a
  nor(pla[76], ir[7], ~ir[6], ~ir[1]); //net: 1246); op-shift-right
  nor(pla[77], t_n[2], ir[7], ir[6], ir[5], ir[4], ir[3], ir[2], ir10); //net: 487; op-T2-brk
  nor(pla[78], t_n[3], ir[7], ir[6], ~ir[5], ir[4], ir[3], ir[2], ir10); //net: 579; op-T3-jsr
  nor(pla[79], ~ir[7], ir[6], ir[5], ~ir[0]); //net: 145; op-sta/cmp
  nor(pla[80], t_n[2], ~ir[4], ir[3], ir[2], ir10);  //net: 1239; op-T2-branch; also net 967 doubly inverted
  nor(pla[81], t_n[2], ir[3], ~ir[2]); //net: 285; op-T2-zp/zp-idx
  nor(pla[82], t_n[2], ir[3], ir[2], ~ir[0]); //net: 1524); op-T2-ind
  nor(pla[83], pla[129], t_n[2], ~ir[3]); //net: 273); op-T2-abs-access
  nor(pla[84], t_n[5], ir[7], ~ir[6], ~ir[5], ir[4], ir[3], ir[2], ir10); //net: 0); op-T5-rts
  nor(pla[85], t_n[4]); //net: 341); op-T4
  nor(pla[86], t_n[3]); //net: 120); op-T3
  nor(pla[87], t_n[0], ir[7], ir[5], ir[4], ir[3], ir[2], ir10); //net: 1478); op-T0-brk/rti
  nor(pla[88], t_n[0], ir[7], ~ir[6], ir[4], ~ir[3], ~ir[2], ir10); //net: 594); op-T0-jmp
  nor(pla[89], t_n[5], ir[4], ir[3], ir[2], ~ir[0]); //net: 1210); op-T5-ind-x
  nor(pla[90], pla[129], t_n[3], ~ir[3]); //net: 677); op-T3-abs/idx/ind
  nor(pla[91], t_n[4], ~ir[4], ir[3], ir[2], ~ir[0]); //net: 461); x-op-T4-ind-y
  nor(pla[92], t_n[3], ~ir[4], ~ir[3]); //net: 447); x-op-T3-abs-idx
  nor(pla[93], t_n[3], ~ir[4], ir[3], ir[2], ir10); //net: 660); op-t3-branch
  nor(pla[94], ir[7], ir[5], ir[4], ir[3], ir[2], ir10); //net: 1557); op-brk/rti
  nor(pla[95], ir[7], ir[6], ~ir[5], ir[4], ir[3], ir[2], ir10); //net: 259); op-jsr
  nor(pla[96], ir[7], ~ir[6], ir[4], ~ir[3], ~ir[2], ir10); //net: 1052); x-op-jmp
  nor(pla[97], ~ir[7], ir[6], ir[5]); //net: 517); op-store
  nor(pla[98], t_n[4], ir[7], ir[6], ir[5], ir[4], ir[3], ir[2], ir10); //net: 352); op-T4-brk
  nor(pla[99], t_n[2], ir[7], ir[6], ir[5], ir[4], ~ir[3], ir[2], ir10); //net: 750); op-T2-php
  nor(pla[100], t_n[2], ir[7], ir[5], ir[4], ~ir[3], ir[2], ir10); //net: 932); op-T2-php/pha
  nor(pla[101], t_n[5], ir[7], ~ir[6], ir[4], ir[3], ir[2], ir10); //net: 446); op-T4-jmp
  nor(pla[102], t_n[4], ir[7], ~ir[6], ir[4], ~ir[3], ~ir[2], ir10); //net: 1589); op-T5-rti/rts
  nor(pla[103], t_n[5], ir[7], ir[6], ~ir[5], ir[4], ir[3], ir[2], ir10); //net: 528); xx-op-T5-jsr
  nor(pla[104], t_n[2], ir[7], ~ir[6], ir[5], ir[4], ~ir[3], ~ir[2], ir10); //net 309); op-T2-jmp-abs
  nor(pla[105], t_n[3], ir[7], ~ir[5], ir[4], ~ir[3], ir[2], ir10); //net 1430); x-op-T3-plp/pla
  nor(pla[106], ~ir[6], ~ir[1]); //net 53); op-lsr/ror/dec/inc
  nor(pla[107], ir[7], ir[6], ~ir[1]); //net: 691); op-asl/rol
  nor(pla[108], t_n[0], ir[7], ~ir[6], ~ir[4], ~ir[3], ir[2], ir10); //net: 1292); op-T0-cli/sei
  nor(pla[109], t_n[1], ir[7], ir[6], ~ir[5], ir[4], ~ir[2], ir10); //net: 1646); op-T+-bit
  nor(pla[110], t_n[0], ir[7], ir[6], ~ir[4], ~ir[3], ir[2], ir10); //net: 1114); op-T0-clc/sec
  nor(pla[111], t_n[3], ~ir[4], ir[3], ~ir[2]); //net: 904); op-T3-mem-zp-idx
  nor(pla[112], t_n[1], ~ir[6], ~ir[5], ~ir[0]); //net: 1155); x-op-T+-adc/sbc
  nor(pla[113], t_n[0], ir[7], ir[6], ~ir[5], ir[4], ~ir[2], ir10); //net: 1476); x-op-T0-bit
  nor(pla[114], t_n[0], ir[7], ir[6], ~ir[5], ir[4], ~ir[3], ir[2], ir10); //net: 1226); op-T0-plp
  nor(pla[115], t_n[4], ir[7], ~ir[6], ir[5], ir[4], ir[3], ir[2], ir10); //net: 1569); x-op-T4-rti
  nor(pla[116], t_n[1], ~ir[7], ~ir[6], ir[5], ~ir[0]); //net: 301); op-T+-cmp
  nor(pla[117], t_n[1], ~ir[7], ~ir[6], ir[4], ~ir[3], ~ir[2], ir10); //net: 950); op-T+-cpx/cpy-abs
  nor(pla[118], t_n[1], ir[7], ir[6], ir[4], ~ir[3], ir[2], ~ir[1]); //net: 1665); op-T+-asl/rol-a
  nor(pla[119], t_n[1], ~ir[7], ~ir[6], ir[4], ir[3], ir10); //net: 1710); op-T+-cpx/cpy-imm/zp
  nor(pla[120], t_n[0], ~ir[7], ~ir[6], ~ir[4], ~ir[3], ir[2], ir10); //net: 1419); op-T0-cld/sed
  nor(pla[121], ir[6]); //net: 840); ~op-branch-bit6
  nor(pla[122], t_n[3], ir[4], ~ir[3], ~ir[2]); //net: 607); op-T3-mem-abs
  nor(pla[123], t_n[2], ir[4], ir[3], ~ir[2]); //net: 219); op-T2-mem-zp
  nor(pla[124], t_n[5], ir[3], ir[2], ~ir[0]); //net: 1385); op-T5-mem-ind-idx
  nor(pla[125], t_n[4], ~ir[4], ~ir[3]); //net: 281); op-T4-mem-abs-idx
  nor(pla[126], ir[7]); //net: 1174); ~op-branch-bit7
  nor(pla[127], ~ir[7], ir[6], ~ir[5], ~ir[4], ~ir[3], ir[2], ir10); //net: 1164); op-clv
  nor(pla[128], pla[129], ~ir[3], ir[2], ir[0]); //net: 1006); op-implied); has extra pulldowns pla[129]
  nor(pla[129], ir[7], ir[4], ~ir[3], ir[2], ir10 ); //net: 791); op-push/pull (aka net: 1050)

endmodule
