module root_hub_core_split #(
    parameter NUM_FPGAS = 5,
    parameter MAXIMUM_DELAY = 3,
    parameter CHANNEL_WIDTH = 64,
    parameter DEST_WIDTH = 8
) (
    clk,
    reset,

    tx_data,
    tx_valid,
    tx_ready,

    rx_data,
    rx_valid,
    rx_ready,

    local_tx_data,
    local_tx_valid,
    local_tx_ready,

    local_rx_data,
    local_rx_valid,
    local_rx_ready
);

// Idx 0 is upstream rest are downstream in sequential order

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

localparam NUM_CHILDREN = NUM_FPGAS - 1;

input clk;
input reset;

output [64*NUM_CHILDREN-1 : 0] tx_data;
output [NUM_CHILDREN-1 : 0] tx_valid;
input [NUM_CHILDREN-1 : 0] tx_ready;

input [64*NUM_CHILDREN-1 : 0] rx_data;
input [NUM_CHILDREN-1 : 0] rx_valid;
output [NUM_CHILDREN-1 : 0] rx_ready;

output [63 : 0] local_tx_data;
output local_tx_valid;
input local_tx_ready;

input [63 : 0] local_rx_data;
input local_rx_valid;
output local_rx_ready;

wire [64*NUM_FPGAS-1 : 0] rx_data_d;
wire [NUM_FPGAS-1 : 0] rx_valid_d;
wire [NUM_FPGAS-1 : 0] rx_ready_d;

wire [64*NUM_FPGAS-1 : 0] tx_data_d;
wire [NUM_FPGAS-1 : 0] tx_valid_d;
wire [NUM_FPGAS-1 : 0] tx_ready_d;

assign rx_data_d[0+:64] = local_rx_data;
assign rx_valid_d[0] = local_rx_valid;
assign local_rx_ready = rx_ready_d[0];

assign local_tx_data = tx_data_d[0+:64];
assign local_tx_valid = tx_valid_d[0];
assign tx_ready_d[0] = local_tx_ready;

assign rx_data_d[64+:64*NUM_FPGAS] = rx_data;
assign rx_valid_d[1+:NUM_FPGAS] = rx_valid;
assign rx_ready = rx_ready_d[1+:NUM_FPGAS];

assign tx_data = tx_data_d[64+:64*NUM_FPGAS];
assign tx_valid = tx_valid_d[1+:NUM_FPGAS];
assign tx_ready_d[1+:NUM_FPGAS] = tx_ready;

root_hub #(
    .NUM_FPGAS(NUM_FPGAS),
    .CHANNEL_WIDTH(64),
    .DEST_WIDTH(8)
) root_hub (
    .clk(clk),
    .reset(reset),

    .rx_data(rx_data_d),
    .rx_valid(rx_valid_d),
    .rx_ready(rx_ready_d),

    .tx_data(tx_data_d),
    .tx_valid(tx_valid_d),
    .tx_ready(tx_ready_d)
);

endmodule


