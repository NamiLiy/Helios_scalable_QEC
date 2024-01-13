// Verilog source distributing single channel to correct destination.
module simple_splitter #(
    parameter NUM_CHANNELS = 2,
    parameter CHANNEL_WIDTH_IN = 64,
    parameter CHANNEL_WIDTH_OUT = 32,
    parameter TAG_MSB = 55,
    parameter TAG_LSB = 48
) (
    clk,
    reset,

    in_data,
    in_valid,
    in_ready,

    out_data,
    out_valid,
    out_ready
);

    input clk;
    input reset;

    input [CHANNEL_WIDTH_IN-1 : 0] in_data;
    input in_valid;
    output in_ready;

    output reg [CHANNEL_WIDTH_OUT*NUM_CHANNELS-1 : 0] out_data;
    output reg [NUM_CHANNELS-1 : 0] out_valid;
    input [NUM_CHANNELS-1 : 0] out_ready;

    wire [TAG_MSB-TAG_LSB : 0] dest;
    wire dest_ready;

    assign dest = in_data[TAG_MSB : TAG_LSB];
    assign in_ready = in_valid & out_ready[dest];

    integer i;

    always @(*) begin
        for (i=0; i<NUM_CHANNELS; i=i+1) begin
            out_data[CHANNEL_WIDTH_OUT*i +: CHANNEL_WIDTH_OUT] = in_data;
            out_valid[i] = in_valid & (dest == i);
        end
    end

endmodule

