module interonncetion_model_wrapper #(
    parameter WIDTH = 128,
    parameter CHANNELS = 4,
    parameter LATENCY = 1
) (
    clk,
    reset,

    upstream_fifo_out_data,
    upstream_fifo_out_valid,
    upstream_fifo_out_ready,
    upstream_fifo_in_data,
    upstream_fifo_in_valid,
    upstream_fifo_in_ready,

    downstream_fifo_out_data,
    downstream_fifo_out_valid,
    downstream_fifo_out_ready,
    downstream_fifo_in_data,
    downstream_fifo_in_valid,
    downstream_fifo_in_ready,

    upstream_has_message_flying,
    upstream_has_odd_clusters,

    downstream_has_message_flying,
    downstream_has_odd_clusters,
);

`include "../../parameters/parameters.sv"


input clk;
input reset;

output [WIDTH*CHANNELS - 1 :0] upstream_fifo_out_data;
output [CHANNELS - 1 :0] upstream_fifo_out_valid;
input [CHANNELS - 1 :0] upstream_fifo_out_ready;
input [WIDTH*CHANNEL - 1 :0] upstream_fifo_in_data;
input [CHANNELS - 1 :0] upstream_fifo_in_valid;
output [CHANNELS - 1 :0]upstream_fifo_in_ready;

output [WIDTH*CHANNELS - 1 :0] downstream_fifo_out_data;
output [CHANNELS - 1 :0] downstream_fifo_out_valid;
input [CHANNELS - 1 :0] downstream_fifo_out_ready;
input [WIDTH*CHANNELS - 1 :0] downstream_fifo_in_data;
input [CHANNELS - 1 :0] downstream_fifo_in_valid;
output [CHANNELS - 1 :0] downstream_fifo_in_ready;

output reg [CHANNELS - 1 :0] upstream_has_message_flying;
output reg [CHANNELS - 1 :0] upstream_has_odd_clusters;

input [CHANNELS - 1 :0] downstream_has_message_flying;
input [CHANNELS - 1 :0] downstream_has_odd_clusters;

assign upstream_fifo_out_data = downstream_fifo_in_data;
assign upstream_fifo_out_valid = downstream_fifo_in_valid;
assign upstream_fifo_out_ready = downstream_fifo_in_ready;
assign downstream_fifo_out_data = upstream_fifo_in_data;
assign downstream_fifo_out_valid = upstream_fifo_in_valid;
assign downstream_fifo_out_ready = upstream_fifo_in_ready;

assign upstream_has_message_flying = downstream_has_message_flying;
assign upstream_has_odd_clusters = downstream_has_odd_clusters;

endmodule