/*
 *                                            M6502_TB
 *
 *                                   Copyright (c) 2021 Kevin Lynch
 *                             This file is licensed under the MIT license
 *
 * A test bench for the 6502 microprocessor
 *.
 * The test bench instantiates a M6502 module and a memory module (ram64k).
 * The ram will load itself with the contents of "memory.vmem" which should contain your program.
 * Remember to set the break vectors within memory.list:
 *     FFFA, FFFB: non-maskable interrupt address
 *     FFFC, FFFD: reset vector (program start address)
 *     FFFE, FFFF: maskable interrupt address
 *
 * You can use a different name than "memory.list" to laod the ram by using:
 *    defparam ram64k.SOURCE = "your_program"
 *
 * This model is not intended for synthesis, but rather to learn and observe the actual
 * inner workings of the 6502.
 *
 * You should always reset the 6502 at the beginning of every simulation by setting reset_n low
 * for at least two clock cycles.
 *
 * To run the simulation using iverilog:
 *   >iverilog -o dsn -c file_list.txt
 *   >vvp dsn
 *
 * This will output 6502_sim.vcd which can then be observed using GTKWave.
 */
module M6502_tb();

reg clk;
reg reset_n;
reg ready;
reg irq_n;
reg nmi_n;
reg set_overflow_n;
wire [7:0] data;
wire clk_out1;
wire clk_out2;
wire rw;
wire [15:0] address;
wire sync;

M6502 M6502_ins(clk, reset_n, ready, irq_n, nmi_n, set_overflow_n, data, clk_out1, clk_out2, rw, address, sync);

reg ram_cs_n = 0;
wire ram_oe = ~rw;
ram ram64k(address, data, ram_cs_n, rw, ram_oe);

//initialzie inputs
initial begin
  clk = 0;
  reset_n = 1;
  ready = 1;
  irq_n = 1;
  nmi_n = 1;
  set_overflow_n = 1;
end

always #10 clk = ~clk;

/*************************************************************************************************
 *
 *                          choose program to run and simulate
 *
 *************************************************************************************************/
 //after uncommenting and commenting, remember to run:
 //   >iverilog -o dsn -c file_list.txt
 //   > vvp dsn
 //   then open "6502_sim.vcd" with GTKWave to view the wavefiles (or reload waveform if already open)

/*
 * a simple loop with a subroutine that increments x, increments a memory location, and decrements y
 * based on the default program that runs at visual6502.org
 * The program starts at address 0x0000
 */
defparam ram64k.SOURCE = "sim/visual6502.vmem";  //simple increment x, memory location, and dec y subroutine
integer sim_duration = 40000;

/*
 * a simple program to clear 16 consecutive bytes of memory.
 * The subroutine algorithm is from Michael Pointer and you can learn more about it here:
 * http://6502.org/source/general/clearmem.htm
 * The program starts at address 0x0000
 */
 //defparam ram64k.SOURCE = "sim/clear_mem.vmem";
 //integer sim_duration = 6000;

/*
 * Full functional test for the 6502 written by Klaus Dorman.  His source code can be found on github:
 * https://github.com/Klaus2m5/6502_65C02_functional_tests
 * the program starts at address 0x0400 and it uses an INT vector of 0x366D
 *
 * Note: the test is exhaustive and even running for 900000 time durations, it's not enough time to finish.
 * However it is long enough to run through several tests and get to the beginning of the full binary
 * add/subtract test.  A 900000 sim duration with this program, creates an 82MB 6502_sim.vcd file.
*/
//defparam ram64k.SOURCE = "sim/6502_functional_test.vmem";
//integer sim_duration = 900000;

/*
 * Decimal mode test for the 6502 written by Bruce Clark.
 * see: http://www.6502.org/tutorials/decimal_mode.html for info and source.
 * The program starts at address 0x0200
*/
//defparam ram64k.SOURCE = "sim/6502_decimal_test.vmem";
//integer sim_duration = 3600000; //enough for one loop

/*************************************************************************************************
 *
 *                             simulation and dumpfile
 *
 *************************************************************************************************/
initial begin
    #115 reset_n = 0;
    #140 reset_n = 1;
    #sim_duration $finish;
end

initial
   begin
      $dumpfile("6502_sim.vcd");
      $dumpvars(0, M6502_ins);
   end

endmodule

