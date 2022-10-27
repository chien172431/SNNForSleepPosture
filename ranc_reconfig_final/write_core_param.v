module write_core_param #(
  parameter NUM_CORES_NEW = 9,
  parameter CSRAM_WIDTH = 368,
  parameter NUM_NEURONS = 256
  )(
  input clk,    // Clock
  input rst_n,  // Asynchronous reset active low
  input                             param_wen,
  input   [$clog2(NUM_NEURONS)-1:0] param_addr,
  input   [CSRAM_WIDTH-1:0]         param_data_in,
  output  [CSRAM_WIDTH-1:0]         param_data_out
);

endmodule