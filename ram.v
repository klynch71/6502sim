/*
*                                              RAM
*
*                                   Copyright (c) 2021 Kevin Lynch
*                             This file is licensed under the MIT license
*
* A RAM module that loads its contents from the memory.vmem file
*/
module ram (address, data, cs_n, rw_n, oe_n);

parameter WIDTH = 8;
parameter DEPTH = 16; //64k
parameter SOURCE = "memory.vmem";

input [DEPTH-1:0] address;
inout [WIDTH-1:0] data;
input cs_n; //chip select (active low)
input rw_n; //read/write (low = write)
input oe_n; //output enable (active low)

reg [WIDTH-1:0] memory [0:(1<<DEPTH)-1];

assign data = (!cs_n && !oe_n) ? memory[address] : {WIDTH{1'bz}};

initial
    $readmemh(SOURCE, memory);

always @(cs_n or rw_n or data or address)
  if (!cs_n && !rw_n)
    begin
      memory[address] = data;
      //$display("data: %h written at address: %h at time: %t", data, address, $time);
    end

endmodule
