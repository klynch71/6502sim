/*
 *                                            M6502
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 * represents a 6502 microprocessor.
 * This is a near gate-level description with all internal control signals represented.
 * Most of the control signals come from the random_control_logic block.
 * Net numbers of the signals correspond to those used by Visual6502.org:
 * https://github.com/trebonian/visual6502/blob/master/nodenames.js
 *
 * The organization of the module is based on the Hanson block diagram:
 * http://visual6502.org/wiki/index.php?title=Hanson%27s_Block_Diagram
 *
 * This model is not intended for synthesis, but rather to learn and observe the actual
 * inner workings of the 6502.
 *
 * To run the simulation using iverilog:
 *   >iverilog -o dsn -c file_list.txt
 *   >vvp dsn
 *
 * This will output 6502_sim.vcd which can be observed using GTKWave.
 */
module M6502(CLK_IN, RES_N, READY, IRQ_N, NMI_N, SO_N, DATA, CLK_1_OUT, CLK_2_OUT, RW_N, ADDRESS, SYNC);

  input CLK_IN;           // CPU clock
  input RES_N;            // reset signal (active low)
  input READY;            // pauses CPU when low
  input IRQ_N;            // interrupt request (active low)
  input NMI_N;            // non-maskable interrupt (active low)
  input SO_N;             // set overflow flag bit.
  inout [7:0] DATA;       // 8-bit data buses
  output CLK_1_OUT;       // inverted signal of clk
  output CLK_2_OUT;       // same as clk
  output RW_N;            // read/write.  low = write.
  output [15:0] ADDRESS;  // address buses
  output SYNC;            // indicates an op-code fetch in progress when high

  /*************************************************************************************************
  *
  *                                         major internal buses
  *
  *************************************************************************************************/
  wire [7:0] db;   //internal data bus
  wire [7:0] adh;  //address data high bus
  wire [7:0] adl;  //address data low bus
  wire [7:0] sb;   //special bus

  //the main internal buses are pulled up with precharge mosfets
  precharge_mosfets precharge_mosfets_db(db);
  precharge_mosfets precharge_mosfets_adh(adh);
  precharge_mosfets precharge_mosfets_adl(adl);
  precharge_mosfets precharge_mosfets_sb(sb);

  //the special bus connects to the internal data bus and address data bus through pass mosfets.
  //the control signals sb_adh and sb_db are supplied by the random control logic
  pass_mosfets pass_mosfets_sb_adh(sb_adh, sb, adh);
  pass_mosfets pass_mosfets_sb_db(sb_db, sb, db);

  //open drain mosfets pulldown when enabled.  These are used on ADH when accessing the
  //stack (which is on the zero page), and on ADL during reset and interrupts.
  tristate_buffer #(.WIDTH(7)) open_drain_mosfets17(zero_adh17, 7'b0, adh[7:1]);  //controlled by zero_adh17
  bufif1 (adh[0], 1'b0, zero_adh0);

  bufif1 (adl[2], 1'b0, zero_adl[2]);
  bufif1 (adl[1], 1'b0, zero_adl[1]);
  bufif1 (adl[0], 1'b0, zero_adl[0]);

  /*************************************************************************************************
  *
  *                                         data path
  *
  *************************************************************************************************/
  //DATA io
  wire [7:0] dor_data; //data out register data
  input_data_latch input_data_latch_ins(clk_1, clk_2, DATA, dl_db, dl_adl, dl_adh, db, adl, adh);
  latch data_output_register(clk_1, db, dor_data);
  //in the real 6502, the data out tri-state enable has a slight delay by putting clk2 through a few transistors.
  //Here we just model it with a simple delay of one time unit.
  wire #1 write_enable = ~RW_N & clk_2;
  tristate_buffer data_bus_tristate_buffers(write_enable, dor_data, DATA);

  //ADDRESS registers
  wire load_abh = adh_abh & clk_1;
  wire load_abl = adl_abl & clk_1;
  latch address_bus_high_register(load_abh, adh, ADDRESS[15:8]);
  latch address_bus_low_register(load_abl, adl, ADDRESS[7:0]);

  //Program counter low
  wire [7:0] pcl; //program counter low bus
  wire [7:0] to_pcl_inc;
  wire [7:0] to_pcl_reg;  //data from low increment logic to low program counter register
  wire pcl_carry;
  program_counter_select_register program_counter_low_select_register(pcl_pcl, adl_pcl, pcl, adl, to_pcl_inc);
  increment_logic increment_logic_low(~inc_pc_n, to_pcl_inc, to_pcl_reg, pcl_carry);
  program_counter_register program_counter_low_register(clk_2, to_pcl_reg, pcl_adl, pcl_db, pcl, adl, db);

  //Program counter high
  wire [7:0] pch; //program counter high bus
  wire [7:0] to_pch_inc;
  wire [7:0] to_pch_reg;  //data from high increment logic to high program counter register
  wire pch_carry;
  program_counter_select_register program_counter_high_select_register(pch_pch, adh_pch, pch, adh, to_pch_inc);
  increment_logic increment_logic_high(pcl_carry, to_pch_inc, to_pch_reg, pch_carry);
  program_counter_register program_counter_high_register(clk_2, to_pch_reg, pch_adh, pch_db, pch, adh, db);

  //ALU
  wire [7:0] alu_a_input;
  wire [7:0] alu_b_input;
  wire [7:0] not_db = ~db; //b-side inverters
  wire [7:0] alu_result_n;
  wire alu_overflow_n;
  wire alu_half_carry;
  wire alu_carry_out_n;
  a_input_register a_input_register_ins(zero_add, sb_add, 8'b0, sb, alu_a_input);
  b_input_register b_input_register_ins(not_db_add, db_add, adl_add, not_db, db, adl, alu_b_input);
  alu alu_ins(clk_2, alu_sums, alu_ands, alu_eors, alu_ors, alu_srs, alu_a_input, alu_b_input, alu_carry_in_n,
              daa_n, dsa_n, alu_overflow_n, alu_half_carry, alu_carry_out_n, alu_result_n);

  //Adder hold register
  wire [7:0] alu_result_c2; //delivered to decimal adjust adders
  adder_hold_register adder_hold_register_ins(clk_2, add_adl, add_sb06, add_sb7, alu_result_n, adl, sb, alu_result_c2);

  //Decimal adjust adders
  wire [7:0] dec_adjust_out;
  decimal_adjust_adder decimal_adjust_adder_ins(clk_2, daa_n, dsa_n, alu_half_carry, alu_carry_out_n,
                                                alu_result_c2, sb, dec_adjust_out);

  //accumulator
  accumulator accumulator_ins(sb_ac, ac_db, ac_sb, dec_adjust_out, db, sb);

  //stack pointer
  stack_pointer_register stack_pointer_register_ins(clk_2, sb_s, s_s, s_sb, s_adl, sb, sb, adl);

  //status register
  wire negative_flag;
  wire overflow_flag;
  wire dmode_flag;
  wire interrupt_flag;
  wire zero_flag;
  wire carry_flag;
  processor_status_register processor_status_register_ins(clk_1, clk_2, db, break_done, aic_n, alu_overflow_n, alu_carry_out_n,
                              ~ir[5], db_p, db7_n_flag, db6_v_flag, avr_v_flag, set_v_flag, clr_v_flag, ir5_d_flag,
                              ir5_i_flag, dbz_z_flag, db0_c_flag, ir5_c_flag, acr_c_flag, p_db, db, negative_flag,
                              overflow_flag, dmode_flag, zero_flag, interrupt_flag, carry_flag);

  //x & y registers
  wire[7:0] x_reg; //for display purposes only
  wire[7:0] y_reg; //for display purposes only
  xy_index_register x_index_register(sb_x, x_sb, sb, sb, x_reg);
  xy_index_register y_index_register(sb_y, y_sb, sb, sb, y_reg);

  /*************************************************************************************************
  *
  *                                         control path
  *
  *************************************************************************************************/

  //the clock generator generates two non-overlapping clocks
  clock_generator clock_generator_ins(CLK_IN, clk_1, clk_2, CLK_1_OUT, CLK_2_OUT);

  //ready control
  wire rdy;               //ready.  opposite polarity version of net: 248
  ready_control ready_control_ins(clk_2, READY, RW_N, rdy);

  //predecode register
  wire [7:0] predecode_reg_data;
  latch predecode_register(clk_2, DATA, predecode_reg_data);

  //predecode logic
  wire [7:0] predecode_out;
  wire tz_pre_n;
  wire implied;
  predecode_logic predecode_logic_ins(clk_1, aic_n, fetch, predecode_reg_data, predecode_out, tz_pre_n, implied);

  //instruction register
  wire [7:0] ir;
  wire load_ir = fetch & clk_1;
  latch instruction_register_ins(load_ir, predecode_out, ir);

  //interrupt and reset control
  wire res_p;
  wire res_g;
  wire break_done;
  wire aic_n;
  wire [2:0] zero_adl;
  interrupt_and_reset_control interrupt_and_reset_control_ins(clk_1, clk_2, NMI_N, IRQ_N, RES_N, rdy, timing_n[0],
                                     pla[80], pla[22], interrupt_flag, res_p, res_g,
                                     int_g, break_done, aic_n, zero_adl);

  //decode rom
  wire [129:0] pla;      //decode_rom ouputs (pla = programmable logic array)
  decode_rom decode_rom_ins(ir, timing_n, pla);

  //timing generator
  wire [5:0] timing_n;
  wire fetch;
  timing_generator timing_generator_ins(clk_1, clk_2, rdy, tz_pre_n, t_zero, t_res_1, timing_n, fetch, SYNC);

  //random control logic
  wire dl_db;       //net: 863;  drive data latch (dl) contents onto internal data bus (db)
  wire dl_adl;      //net: 1564; drive data latch (dl) contents onto address data low (adl) bus
  wire dl_adh;      //net: 41;   drive data latch (dl) contents onto address data high (adh) bus
  wire zero_adh0;   //net: 229;  drive bit 0 of the address data high (adh) bus low
  wire zero_adh17;  //net: 203   drive bits 1-7 of address dta high (adh) bus low
  wire adh_abh;     //net: 821;  load address data high (adh) bus into address bus high reg (abh)
  wire adl_abl;     //net: 639;  load address data low (adl) bus into address bus low reg (abl)
  wire pcl_pcl;     //net: 898;  load program counter low select reg from program counter low reg
  wire adl_pcl;     //net: 414;  load the program counter low select reg from the adl
  wire inc_pc_n;    //net: 379;  increment the program counter (active low)
  wire pcl_db;      //net: 283;  drive program counter low (pdcl) reg on to internal data bus (db);
  wire pcl_adl;     //net: 438;  drive program counter low (pcl) register onto address data low (adl) bus
  wire pch_pch;     //net: 741;  load program counter high select reg from program counter high reg
  wire adh_pch;     //net: 48;   load program counter high select reg from address data high (adh) bus
  wire pch_db;      //net: 247;  drive program counter high reg on to internal data bus;
  wire pch_adh;     //net: 1235; driver program counter high (pch) reg onto address data high (adh) bus
  wire sb_adh;      //net: 140;  connect speical bus (sb) to address data high (adh) bus with pass mossfets
  wire sb_db;       //net: 1060; connect special bus (sb) to internal data bus (db) with pass mosfets
  wire s_adl;       //net: 1468; drive stack pointer register onto address data low bus.
  wire sb_s;        //net: 874;  load stack pointer register with contents of special bus.
  wire s_s;         //net: 654;  immeidately pass stack pointer register input to stack pointer register output
  wire s_sb;        //net: 1700; drive stack pointer register contents onto special bus
  wire sb_ac;       //net: 534;  load the accumulator from the special bus decimal adjust adders
  wire ac_db;       //net: 1331; drive accumulator contents onto internal data bus
  wire ac_sb;       //net: 1698; drive accumulator contents onto special bus
  wire sb_x;        //net: 1186; load special bus into x index register
  wire x_sb;        //net: 1263; drive x index register contents onto special bus
  wire sb_y;        //net: 325;  load special bus into y index register
  wire y_sb;        //net: 801;  drive y index register contents onto special bus
  wire not_db_add;  //net: 1068; load the negative value of the internal data bus into the b-side alu register
  wire db_add;      //net: 859;  load internal data bus into b-side alu register
  wire adl_add;     //net: 437;  load address data low bus into b-side alu register
  wire daa_n;       //net: 1201; decimal add adjust
  wire dsa_n;       //net: 725;  decimal subtract adjust
  wire alu_cin_n;   //net: 1165; alu carry input
  wire alu_sums;    //net: 921;  alu: a + b
  wire alu_ands;    //net: 574   alu: a & b
  wire alu_eors;    //net: 1666  alu: a ^ b; exclusive or
  wire alu_ors;     //net: 59    alu: a | b
  wire alu_srs;     //net: 362   alu: shift right
  wire add_adl;     //net: 1015; load the address data low bus contents into the a-side alu register.
  wire add_sb06;    //net: 129;  drive bits 0-6 of the adder hold register onto bits 0-6 of the special bus.
  wire add_sb7;     //net: 214;  drive bit 7 of the adder hold register onto bit 7 of the special bus.
  wire zero_add;    //net: 984;  load zero into a-side register of alu
  wire sb_add;      //net: 549;  load special bus (sb) into b-side register of alu
  wire p_db;        //net: 1042; drive processor status register (p) contents onto internal data bus (db).
  wire db0_c_flag;  //net: 507;  set the carry flag according to bit 0 of the databus.
  wire ir5_c_flag;  //net: 253;  set the carry flag according to instruction register bit 5.
  wire acr_c_flag;  //net: 954;  set the carry flag according to alu carry out
  wire db7_n_flag;  //net: 754;  set the negative_flag according to bit 7 of the databus
  wire dbz_z_flag;  //net: 755;  set the zero flag if internal data bus equals zero, otherwise clear it
  wire ir5_i_flag;  //net: 1662; set the interrupt mask flag according to instruction register bit 5.
  wire ir5_d_flag;  //net: 1492; set the dmode_flag (decimal mode flag) according to instruction register bit 5.
  wire db6_v_flag;  //net: 1111; set the overflow_flag according to bit 6 of the databus.
  wire avr_v_flag;  //net: 1436; set the overflow flag according to the alu overflow output
  wire set_v_flag;  //net: 1177; set overflow flag
  wire clr_v_flag;  //net: 587;  clear overflow flag
  wire db_p;        //net: 781;  load internal databus into processor status register
  wire t_zero;     //net: 1215; reset timing registers
  wire t_res_1;     //net: 109;  reset timing register 1 (aka sync when latched on c1)


  random_control_logic random_control_logic_ins(clk_1, clk_2, SO_N, pla, rdy, res_p, res_g, aic_n, implied, tz_pre_n,
    ~timing_n[0], ir[5], db[7], alu_carry_out_n, break_done, zero_adl[0], carry_flag, zero_flag, negative_flag,
    overflow_flag, dmode_flag, dl_db, dl_adl, dl_adh, zero_adh0, zero_adh17, adh_abh, adl_abl, pcl_pcl, adl_pcl,
    inc_pc_n, pcl_db, pcl_adl, pch_pch, adh_pch, pch_db, pch_adh, sb_adh, sb_db, s_adl, sb_s, s_s, s_sb, sb_ac, ac_db,
    ac_sb, sb_x, x_sb, sb_y, y_sb, not_db_add, db_add, adl_add, daa_n, dsa_n, alu_carry_in_n, alu_sums, alu_ands,
    alu_eors, alu_ors, alu_srs, add_adl, add_sb06, add_sb7, zero_add, sb_add, p_db, db0_c_flag, ir5_c_flag, acr_c_flag,
    db7_n_flag, dbz_z_flag, ir5_i_flag, ir5_d_flag, db6_v_flag, avr_v_flag, set_v_flag, clr_v_flag, db_p, t_zero, t_res_1,
    RW_N);

endmodule
