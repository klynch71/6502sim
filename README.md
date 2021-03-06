# 6502 Verilog Gate-Level Simulator

This is a near gate-level simulator of the 6502 microprocesor with all internal control signals represented.  Most of the control signals come from the random_control_logic block. 

Net numbers used correspond to those used by [Visual6502.org](http://visual6502.org/):
https://github.com/trebonian/visual6502/blob/master/nodenames.js

The organization of the simulator is based on the [Hanson block diagram](https://github.com/klynch71/6502sim/blob/main/Hanson_diagram.png).

This model is not intended for synthesis but rather to learn and observe the actual inner workings of the 6502.

To run the simulator using iverilog:\
  \> iverilog -o dsn -c file_list.txt\
  \> vvp dsn
  
  This will output 6502_sim.vcd which can be observed using GTKWave.
  
  You can change the program that is run by modifying 6502_tb.v.

![](waveform.png)

## Dependencies

A Verilog simulation tool such as [Icarus Verilog](http://iverilog.icarus.com/).\
A waveform viewer such as [GTKWave](http://gtkwave.sourceforge.net/).

## Installation

Note the dependencies above, then simply download this package into a directory.

## Usage example

From within your downloaded directory run:\
   \> iverilog -o dsn -c file_list.txt\
   \> vvp dsn\
Then open the 6502_sim.vcd file with GTKWave.

You can change the program that is run by modifying 6502_tb.v.

If you assemble your own program, you may find the vmem program in the util folder helpful in converting the program's binary output to a verilog memory file.

## Author 
Kevin Lynch

## License

Distributed under the MIT license. 


