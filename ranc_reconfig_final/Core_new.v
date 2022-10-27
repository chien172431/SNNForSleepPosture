`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Core_new.v
//
// Created for Dr. Akoglu's Reconfigurable Computing Lab
//  at the University of Arizona
// 
// Contains all the modules for a single RANC core.
//////////////////////////////////////////////////////////////////////////////////

module Core_new #(
    parameter PACKET_WIDTH = 30,
    parameter NUM_NEURONS = 256,
    parameter NUM_AXONS = 256,
    parameter NUM_TICKS = 16,
    parameter NUM_WEIGHTS = 4,
    parameter NUM_RESET_MODES = 2,
    parameter POTENTIAL_WIDTH = 9,
    parameter WEIGHT_WIDTH = 9,
    parameter LEAK_WIDTH = 9,
    parameter THRESHOLD_WIDTH = 9,
    parameter DX_MSB = 29,
    parameter DX_LSB = 21,
    parameter DY_MSB = 20,
    parameter DY_LSB = 12,
    parameter ROUTER_BUFFER_DEPTH = 4,
    parameter CSRAM_FILE = "csram_000.mem",  
    parameter TC_FILE = "tc_000.mem",
    parameter CSRAM_WIDTH = 368,

    parameter VOTE_NUM = 1,

    parameter WIDTHB = 32,
    parameter SIZEB = 4096,
    parameter ADDRWIDTHB = $clog2(SIZEB)
)(
    input clk,
    input tick,
    input rst,
    input ren_in_west,
    input ren_in_east,
    input ren_in_north,
    input ren_in_south,
    input empty_in_west,
    input empty_in_east,
    input empty_in_north,
    input empty_in_south,
    input [PACKET_WIDTH-1:0] east_in,
    input [PACKET_WIDTH-1:0] west_in,
    input [PACKET_WIDTH-(DX_MSB-DX_LSB+1)-1:0] north_in,
    input [PACKET_WIDTH-(DX_MSB-DX_LSB+1)-1:0] south_in,

    input                         param_wen,
    input   [ADDRWIDTHB-1:0]     param_addr,
    input   [WIDTHB-1:0]         param_data_in,
    output  [WIDTHB-1:0]         param_data_out,

    input                     clr_avr,
    input                     clr_spiked,
    
    output ren_out_west,
    output ren_out_east,
    output ren_out_north,
    output ren_out_south,
    output empty_out_west,
    output empty_out_east,
    output empty_out_north,
    output empty_out_south,
    output [PACKET_WIDTH-1:0] east_out,
    output [PACKET_WIDTH-1:0] west_out,
    output [PACKET_WIDTH-(DX_MSB-DX_LSB+1)-1:0] north_out,
    output [PACKET_WIDTH-(DX_MSB-DX_LSB+1)-1:0] south_out,
    output token_controller_error,
    output scheduler_error
);
    
    localparam DX_WIDTH = (DX_MSB-DX_LSB+1);
    localparam DY_WIDTH = (DY_MSB-DY_LSB+1);
    localparam CSRAM_SYNAPTIC_CONNECTIONS_BOTTOM_INDEX = CSRAM_WIDTH - NUM_AXONS;
    localparam CSRAM_CURRENT_POTENTIAL_BOTTOM_INDEX = CSRAM_SYNAPTIC_CONNECTIONS_BOTTOM_INDEX - POTENTIAL_WIDTH;
    localparam CSRAM_RESET_POTENTIAL_BOTTOM_INDEX = CSRAM_CURRENT_POTENTIAL_BOTTOM_INDEX - POTENTIAL_WIDTH;
    localparam CSRAM_WEIGHTS_BOTTOM_INDEX = CSRAM_RESET_POTENTIAL_BOTTOM_INDEX - WEIGHT_WIDTH*NUM_WEIGHTS;
    localparam CSRAM_LEAK_BOTTOM_INDEX = CSRAM_WEIGHTS_BOTTOM_INDEX - LEAK_WIDTH;
    localparam CSRAM_THRESHOLD_BOTTOM_INDEX = CSRAM_LEAK_BOTTOM_INDEX - THRESHOLD_WIDTH;
    localparam CSRAM_FLOOR_BOTTOM_INDEX = CSRAM_THRESHOLD_BOTTOM_INDEX - THRESHOLD_WIDTH;
    localparam CSRAM_RESET_MODE_BOTTOM_INDEX = CSRAM_FLOOR_BOTTOM_INDEX - $clog2(NUM_RESET_MODES);
    localparam CSRAM_DX_BOTTOM_INDEX = CSRAM_RESET_MODE_BOTTOM_INDEX - DX_WIDTH;
    localparam CSRAM_DY_BOTTOM_INDEX = CSRAM_DX_BOTTOM_INDEX - DY_WIDTH;
    localparam CSRAM_AXON_DESTINATION_BOTTOM_INDEX = CSRAM_DY_BOTTOM_INDEX - $clog2(NUM_AXONS);
    localparam CSRAM_SPIKE_DELIVERY_TICK_BOTTOM_INDEX = CSRAM_AXON_DESTINATION_BOTTOM_INDEX - $clog2(NUM_AXONS);
    

    localparam CSRAM_ASYM_WIDTH = 512;
    // Scheduler
    wire [NUM_AXONS-1:0] axon_spikes;
    
    // // CSRAM
    wire [CSRAM_WIDTH-1:0] CSRAM_data;
    wire CSRAM_complete;
    wire [$clog2(NUM_NEURONS)-1:0] CSRAM_addr;

    wire [CSRAM_ASYM_WIDTH-1:0] CSRAM_asym_write_data;
    wire [CSRAM_ASYM_WIDTH-1:0] CSRAM_asym_data;
    
    // Token Controller
    wire CSRAM_write, CSRAM_set, CSRAM_init;
    wire scheduler_set, scheduler_clr, router_spike;
    wire neuron_block_en, neuron_block_next_neuron;
    wire neuron_block_write_current_potential;
    wire [$clog2(NUM_WEIGHTS)-1:0] neuron_instruction;
    
    // Nueron Block
    wire [POTENTIAL_WIDTH-1:0] neuron_potential;
    wire neuron_block_spike;

    // Router -> Scheduler
    wire [$clog2(NUM_AXONS) + $clog2(NUM_TICKS) - 1:0] scheduler_packet;
    wire scheduler_wen;
    
    // Router -> Token Controller
    wire local_buffers_full;
    

// Scheduler #(
//     .NUM_AXONS(NUM_AXONS),
//     .NUM_TICKS(NUM_TICKS)
// ) Scheduler (
//     .clk(clk),
//     .rst(rst),
//     .wen(scheduler_wen),
//     .set(scheduler_set),
//     .clr(scheduler_clr),
//     .packet(scheduler_packet),
//     .axon_spikes(axon_spikes),
//     .error(scheduler_error)
// );

Scheduler_new #(
    .NUM_AXONS(NUM_AXONS),
    .NUM_TICKS(NUM_TICKS),
    .VOTE_NUM(VOTE_NUM)
) Scheduler_new (
    .clk(clk),
    .rst(rst),
    .wen(scheduler_wen),
    .set(scheduler_set),
    .clr(scheduler_clr),
    .packet(scheduler_packet),
    .axon_spikes(axon_spikes),
    .error(scheduler_error),
    .clr_avr(clr_avr),
    .clr_spiked(clr_spiked)
);

/* Addressing:
    ~ NUM_AXONS - Synaptic Connections
    ~ POTENTIAL_WIDTH - Current Potential
    ~ POTENTIAL_WIDTH - Reset Potential
    ~ WEIGHT_WIDTH*NUM_WEIGHTS - Weights
    ~ LEAK_WIDTH - Leak
    ~ THRESHOLD_WIDTH - Positive Threshold
    ~ THRESHOLD_WIDTH - Negative Threshold
    ~ $clog2(NUM_RESET_MODES) - Reset Mode
    ~ DX_WIDTH - Destination X
    ~ DY_WIDTH - Destination Y
    ~ $clog2(NUM_AXONS) - Axon Destination
    ~ $clog2(NUM_TICKS) - Spike Delivery Tick */
// CSRAM_new #(
//     .FILENAME   (CSRAM_FILE),
//     .NUM_NEURONS(NUM_NEURONS),
//     .WIDTH(CSRAM_WIDTH),
//     .WRITE_INDEX(CSRAM_CURRENT_POTENTIAL_BOTTOM_INDEX),
//     .WRITE_WIDTH(POTENTIAL_WIDTH)
// ) CSRAM_new (
//     .clk_0     (clk),
//     .en_0      (1'b1),
//     .wen_0     (CSRAM_write),
//     .address_0 (CSRAM_addr),
//     .data_in_0 ({CSRAM_data[CSRAM_WIDTH-1:CSRAM_SYNAPTIC_CONNECTIONS_BOTTOM_INDEX], neuron_potential, CSRAM_data[CSRAM_CURRENT_POTENTIAL_BOTTOM_INDEX-1:0]}),
//     .data_out_0(CSRAM_data),

// // reconfig
//     .clk_1     (clk),
//     .en_1      (1'b1),
//     .wen_1     (param_wen),
//     .address_1 (param_addr),
//     .data_in_1 (param_data_in),
//     .data_out_1(param_data_out)
// );

assign CSRAM_asym_write_data = {CSRAM_data[CSRAM_WIDTH-1:CSRAM_SYNAPTIC_CONNECTIONS_BOTTOM_INDEX], neuron_potential, CSRAM_data[CSRAM_CURRENT_POTENTIAL_BOTTOM_INDEX-1:0]};
assign CSRAM_data = CSRAM_asym_data[CSRAM_WIDTH-1:0];

CSRAM_asym #(
    .WIDTHB    (32),
    .SIZEB     (4096),
    .ADDRWIDTHB(12),
    .WIDTHA    (512),
    .SIZEA     (256),
    .ADDRWIDTHA(8)
) CSRAM_asym (
    // port B
    .clkB     (clk),
    .enaB      (1'b1),
    .weB     (param_wen),
    .addrB    (param_addr),
    .diB (param_data_in),
    .doB(param_data_out),
    // port A
    .clkA     (clk),
    .enaA      (1'b1),
    .weA     (CSRAM_write),
    .addrA    (CSRAM_addr),
    .diA (CSRAM_asym_write_data),
    .doA  (CSRAM_asym_data)

);

TokenController #(
    .NUM_AXONS(NUM_AXONS),
    .NUM_NEURONS(NUM_NEURONS),
    .NUM_WEIGHTS(NUM_WEIGHTS),
    .FILENAME(TC_FILE)
) TokenController (
    .clk(clk), 
    .rst(rst),
    .tick(tick),
    .axon_spikes(axon_spikes), 
    .synapses(CSRAM_data[CSRAM_SYNAPTIC_CONNECTIONS_BOTTOM_INDEX +: NUM_AXONS]), 
    .spike_in(neuron_block_spike),
    .local_buffers_full(local_buffers_full),
    .error(token_controller_error),
    .scheduler_set(scheduler_set), 
    .scheduler_clr(scheduler_clr),
    .CSRAM_write(CSRAM_write),
    .CSRAM_addr(CSRAM_addr),
    .neuron_instruction(neuron_instruction), 
    .spike_out(router_spike),
    .neuron_reg_en(neuron_block_en), 
    .next_neuron(neuron_block_next_neuron),
    .write_current_potential(neuron_block_write_current_potential)
);

NeuronBlock #(
    .LEAK_WIDTH(LEAK_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .THRESHOLD_WIDTH(THRESHOLD_WIDTH),
    .POTENTIAL_WIDTH(POTENTIAL_WIDTH),
    .NUM_WEIGHTS(NUM_WEIGHTS),
    .NUM_RESET_MODES(NUM_RESET_MODES)
) NeuronBlock (
    .leak(CSRAM_data[CSRAM_LEAK_BOTTOM_INDEX +: LEAK_WIDTH]),
    .weights(CSRAM_data[CSRAM_WEIGHTS_BOTTOM_INDEX +: WEIGHT_WIDTH*NUM_WEIGHTS]),
    .positive_threshold(CSRAM_data[CSRAM_THRESHOLD_BOTTOM_INDEX +: THRESHOLD_WIDTH]),
    .negative_threshold(CSRAM_data[CSRAM_FLOOR_BOTTOM_INDEX +: THRESHOLD_WIDTH]),
    .reset_potential(CSRAM_data[CSRAM_RESET_POTENTIAL_BOTTOM_INDEX +: POTENTIAL_WIDTH]),
    .current_potential(CSRAM_data[CSRAM_CURRENT_POTENTIAL_BOTTOM_INDEX +: POTENTIAL_WIDTH]),
    .neuron_instruction(neuron_instruction),
    .reset_mode(CSRAM_data[CSRAM_RESET_MODE_BOTTOM_INDEX +: $clog2(NUM_RESET_MODES)]),
    .clk(clk),
    .next_neuron(neuron_block_next_neuron),
    .integrator_reg_en(neuron_block_en),
    .write_current_potential(neuron_block_write_current_potential),
    .write_potential(neuron_potential),
    .spike_out(neuron_block_spike)
);

Router #(
    .PACKET_WIDTH(PACKET_WIDTH),
    .DX_MSB(DX_MSB), 
    .DX_LSB(DX_LSB),
    .DY_MSB(DY_MSB),
    .DY_LSB(DY_LSB),
    .BUFFER_DEPTH(ROUTER_BUFFER_DEPTH)
) Router (
    .clk(clk),
    .rst(rst),
    .din_local(CSRAM_data[PACKET_WIDTH-1:0]),
    .din_local_wen(router_spike),
    .din_west(west_in),
    .din_east(east_in),
    .din_north(north_in),
    .din_south(south_in),
    .ren_in_west(ren_in_west),
    .ren_in_east(ren_in_east),
    .ren_in_north(ren_in_north),
    .ren_in_south(ren_in_south),
    .empty_in_west(empty_in_west),
    .empty_in_east(empty_in_east),
    .empty_in_north(empty_in_north),
    .empty_in_south(empty_in_south),
    .dout_west(west_out),
    .dout_east(east_out),
    .dout_north(north_out),
    .dout_south(south_out),
    .dout_local(scheduler_packet),
    .dout_wen_local(scheduler_wen),
    .ren_out_west(ren_out_west),
    .ren_out_east(ren_out_east),
    .ren_out_north(ren_out_north),
    .ren_out_south(ren_out_south),
    .empty_out_west(empty_out_west),
    .empty_out_east(empty_out_east),
    .empty_out_north(empty_out_north),
    .empty_out_south(empty_out_south),
    .local_buffers_full(local_buffers_full)
);

endmodule
