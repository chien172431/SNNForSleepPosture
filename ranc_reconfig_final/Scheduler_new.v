module Scheduler_new #(
    parameter NUM_AXONS = 256,
    parameter NUM_TICKS = 16,
    parameter VOTE_NUM = 1
)(
    input clk,
    input rst,
    input wen,
    input set,
    input clr,
    input [$clog2(NUM_AXONS) + $clog2(NUM_TICKS) - 1:0] packet,
    output reg [NUM_AXONS-1:0] axon_spikes,
    output error,

    input clr_avr,
    input clr_spiked
);

reg [NUM_AXONS-1:0] memory;
reg [NUM_AXONS-1:0] spiked;

assign error = 0;

reg [$clog2(VOTE_NUM):0] packet_cnt[255:0];

integer i;

always @(posedge clk) begin : proc_packet_cnt
    if(rst) begin
        for (i=0; i<256; i=i+1) begin
            packet_cnt[i] <= 3'b0;
            spiked[i] <= 0;
        end
    end 
    else if(clr_avr) begin
        for (i=0; i<256; i=i+1) begin
            packet_cnt[i] <= 3'b0;
            spiked[i] <= 0;
        end
    end 
    if(clr_spiked) begin
        for (i=0; i<256; i=i+1) begin
            spiked[i] <= 0;
        end
    end 
    else begin
        for (i=0; i<256; i=i+1) begin
            if (packet[$clog2(NUM_AXONS) + $clog2(NUM_TICKS)-1:$clog2(NUM_TICKS)]==i && wen) begin
                packet_cnt[i] <= packet_cnt[i] + 1;
            end
            if (packet_cnt[i] >= VOTE_NUM) begin
                spiked[i] <= 1'b1;
            end
        end
    end 
end

always@(posedge clk) begin
    for (i=0; i<256; i=i+1) begin
        if(rst) begin
            memory[i] <= 0;
        end
        else if(packet_cnt[i] >= VOTE_NUM && spiked[i] == 0) begin
            memory[i] <= 1'b1;
        end
        else if(set) begin
            memory[i] <= 0;
        end
    end
end

    // always@(posedge clk) begin
    //     if(rst) begin
    //         memory <= 0;
    //     end
    //     else if(wen) begin
    //         memory[packet[$clog2(NUM_AXONS) + $clog2(NUM_TICKS)-1:$clog2(NUM_TICKS)]] <= 1'b1;
    //     end
    //     else if(set) begin
    //         memory <= 0;
    //     end
    // end

always @(negedge clk) begin
    if (rst) begin
        axon_spikes <= 0;
    end
    else if(set) begin
        axon_spikes <= memory;
    end else if (clr) begin
        axon_spikes <= 0;
    end
end

endmodule