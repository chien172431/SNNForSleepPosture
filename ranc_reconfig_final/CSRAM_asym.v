`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// CSRAM_asym.v
//
// Created for EDABK
// Author: Chien Nguyen
//
// Holds the configuration parameters for the neurons for a core.
//////////////////////////////////////////////////////////////////////////////////

module CSRAM_asym (clkA, clkB, enaA, weA, enaB, weB, addrA, addrB, diA,
doA, diB, doB);
parameter WIDTHB = 32;
parameter SIZEB = 4096;
parameter ADDRWIDTHB = 12;
parameter WIDTHA = 512;
parameter SIZEA = 256;
parameter ADDRWIDTHA = 8;
input clkA;
input clkB;
input weA, weB;
input enaA, enaB;
input [ADDRWIDTHA-1:0] addrA;
input [ADDRWIDTHB-1:0] addrB;
input [WIDTHA-1:0] diA;
input [WIDTHB-1:0] diB;
output [WIDTHA-1:0] doA;
output [WIDTHB-1:0] doB;
`define max(a,b) {(a) > (b) ? (a) : (b)}
`define min(a,b) {(a) < (b) ? (a) : (b)}
function integer log2;
  input integer value;
  reg [31:0] shifted;
  integer res;
  begin
    if (value < 2)
    log2 = value;
    else
      begin
      shifted = value-1;
      for (res=0; shifted>0; res=res+1)
        shifted = shifted>>1;
      log2 = res;
    end
  end
endfunction
localparam maxSIZE = `max(SIZEA, SIZEB);
localparam maxWIDTH = `max(WIDTHA, WIDTHB);
localparam minWIDTH = `min(WIDTHA, WIDTHB);
localparam RATIO = maxWIDTH / minWIDTH;
localparam log2RATIO = log2(RATIO);
reg [minWIDTH-1:0] RAM [0:maxSIZE-1];
reg [WIDTHA-1:0] readA;
reg [WIDTHB-1:0] readB;
initial begin : init
  integer i;
  for (i = 0; i < maxSIZE; i=i+1) begin
    RAM[i] = 0;
  end
end
always @(negedge clkB)
begin
  if (enaB) begin
    readB <= RAM[addrB] ;
    if (weB)
        RAM[addrB] <= diB;
    end
end
always @(negedge clkA)
begin : portA
  integer i;
  reg [log2RATIO-1:0] lsbaddr ;
  for (i=0; i< RATIO; i= i+ 1) begin
    lsbaddr = i;
    if (enaA) begin
      readA[(i+1)*minWIDTH -1 -: minWIDTH] <= RAM[{addrA, lsbaddr}];
      if (weA)
        RAM[{addrA, lsbaddr}] <= diA[(i+1)*minWIDTH-1 -: minWIDTH];
    end
  end
end
assign doA = readA;
assign doB = readB;
endmodule

// module CSRAM_asym #(
//     parameter NUM_NEURONS = 256,
//     parameter WIDTH = 368,
//     parameter WRITE_INDEX = 102,
//     parameter WRITE_WIDTH = 9,

//     parameter WIDTH_B = WIDTH,
//     parameter SIZE_B = NUM_NEURONS,
//     parameter ADDRWIDTH_B = $clog2(SIZE_B),
//     parameter WIDTH_A = 16,
//     parameter SIZE_A = (WIDTH_B*SIZE_B)/16,
//     parameter ADDRWIDTH_A = $clog2(SIZE_A)
// )(
//     input clk_a,
//     input clk_b,
//     input en_a,
//     input en_b,
//     input wen_a,
//     input wen_b,
//     input [ADDRWIDTH_A-1:0] addr_a,
//     input [ADDRWIDTH_B-1:0] addr_b,
//     input [WIDTH_A-1:0] data_in_a,
//     input [WIDTH_B-1:0] data_in_b,
//     output reg [WIDTH_A-1:0] data_out_a,
//     output reg [WIDTH_B-1:0] data_out_b
// ); 
// `define max(a,b) {(a) > (b) ? (a) : (b)}
// `define min(a,b) {(a) < (b) ? (a) : (b)}

// localparam MAX_SIZE = `max(SIZE_A, SIZE_B);
// localparam MAX_WIDTH = `max(WIDTH_A, WIDTH_B);
// localparam MIN_WIDTH = `min(WIDTH_A, WIDTH_B);
// localparam RATIO = MAX_WIDTH / MIN_WIDTH;
// localparam LOG2_RATIO = $clog2(RATIO);


//     (* ram_style = "block" *) reg [MIN_WIDTH-1:0] memory [0:MAX_SIZE-1];

//     integer i;
//     reg [LOG2_RATIO-1:0] lsb_addr;

//     always@(negedge clk_a) if (en_a) begin : portA
//         if (wen_a) begin
//             memory[addr_a] <= data_in_a;
//         end
//         data_out_a <= memory[addr_a];
//     end



//     always@(negedge clk_b) begin : portB
//       for (i = 0; i < RATIO; i=i+1) begin
//         lsb_addr = i;
//         if (en_b) begin
//             if (wen_b) begin
//                 memory[addr_b*RATIO + lsb_addr] <= data_in_b[(i+1)*MIN_WIDTH-1 -: MIN_WIDTH];
//             end
//             data_out_b[(i+1)*MIN_WIDTH-1 -: MIN_WIDTH] <= memory[addr_b*RATIO + lsb_addr];
//         end
//       end
//     end

// endmodule





