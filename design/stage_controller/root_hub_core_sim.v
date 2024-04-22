module root_hub_core_sim #(
    parameter NUM_FPGAS = 5,
    parameter MAXIMUM_DELAY = 3,
    parameter CHANNEL_WIDTH = 64,
    parameter DEST_WIDTH = 8
) (
    clk,
    reset,

    tx_0_dout,
    tx_0_wr_en,
    tx_0_full,

    rx_0_din,
    rx_0_empty,
    rx_0_rd_en,

    tx_1_dout,
    tx_1_wr_en,
    tx_1_full,

    rx_1_din,
    rx_1_empty,
    rx_1_rd_en

    // roots // A debug port. Do not use in the real implementation
);

// Idx 0 is upstream rest are downstream in sequential order

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

localparam NUM_CHILDREN = NUM_FPGAS - 1;

input clk;
input reset;

output [63 : 0] tx_0_dout;
output tx_0_wr_en;
input tx_0_full;

input [63 : 0] rx_0_din;
input rx_0_empty;
output rx_0_rd_en;

output [64*NUM_CHILDREN-1 : 0] tx_1_dout;
output [NUM_CHILDREN -1 : 0] tx_1_wr_en;
input [NUM_CHILDREN -1 : 0] tx_1_full;

input [64*NUM_CHILDREN-1 : 0] rx_1_din;
input [NUM_CHILDREN -1 : 0] rx_1_empty;
output [NUM_CHILDREN -1 : 0] rx_1_rd_en;


wire [64*NUM_FPGAS-1 : 0] rx_data_d;
wire [NUM_FPGAS-1 : 0] rx_valid_d;
wire [NUM_FPGAS-1 : 0] rx_ready_d;

wire [64*NUM_FPGAS-1 : 0] tx_data_d;
wire [NUM_FPGAS-1 : 0] tx_valid_d;
wire [NUM_FPGAS-1 : 0] tx_ready_d;

wire [63:0] data_from_controller;
wire valid_from_controller;
wire ready_from_controller;

wire [63:0] data_to_controller;
wire valid_to_controller;
wire ready_to_controller;

wire router_busy;

root_controller #(
    .ITERATION_COUNTER_WIDTH(8),
    .MAXIMUM_DELAY(MAXIMUM_DELAY),
    .CTRL_FIFO_WIDTH(64),
    .NUM_CHILDREN(NUM_CHILDREN)    
) controller (
    .clk(clk),
    .reset(reset),

    // we can send whatever data coming directly from cpu to controller as it is always externally buffered
    .data_from_cpu(rx_0_din),
    .valid_from_cpu(!rx_0_empty),
    .ready_from_cpu(rx_0_rd_en),
    .data_to_cpu(tx_0_dout),
    .valid_to_cpu(tx_0_wr_en),
    .ready_to_cpu(!tx_0_full),

    .data_to_fpgas(data_from_controller),
    .valid_to_fpgas(valid_from_controller),
    .ready_to_fpgas(ready_from_controller),
    .data_from_fpgas(data_to_controller),
    .valid_from_fpgas(valid_to_controller),
    .ready_from_fpgas(ready_to_controller),

    .router_busy(router_busy)
);

fifo_wrapper #(
    .WIDTH(64),
    .DEPTH(128)
) controller_to_router_fifo(
    .clk(clk),
    .reset(reset),
    .input_data(data_from_controller),
    .input_valid(valid_from_controller),
    .input_ready(ready_from_controller),
    .output_data(rx_data_d[0+:64]),
    .output_valid(rx_valid_d[0]),
    .output_ready(rx_ready_d[0])
);

fifo_wrapper #(
    .WIDTH(64),
    .DEPTH(128)
) router_to_controller_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(tx_data_d[0+:64]),
    .input_valid(tx_valid_d[0]),
    .input_ready(tx_ready_d[0]),
    .output_data(data_to_controller),
    .output_valid(valid_to_controller),
    .output_ready(ready_to_controller)
);

generate
    genvar i;
    for(i=0; i<NUM_CHILDREN; i=i+1) begin
        assign rx_data_d[64*(i+1)+:64] = rx_1_din[64*i+:64];
        assign rx_valid_d[i+1] = !rx_1_empty[i];
        assign rx_1_rd_en[i] = rx_ready_d[i + 1];
        assign tx_1_dout[64*i+:64] = tx_data_d[64*(i+1)+:64];
        assign tx_1_wr_en[i] = tx_valid_d[i+1]; 
        assign tx_ready_d[i+1] = !tx_1_full[i];
    end
endgenerate


router #(
    .NUM_CHANNELS(NUM_FPGAS),
    .CHANNEL_WIDTH(CHANNEL_WIDTH),
    .DEST_WIDTH(DEST_WIDTH)
) router (
    .clk(clk),
    .reset(reset),

    .rx_data(rx_data_d),
    .rx_valid(rx_valid_d),
    .rx_ready(rx_ready_d),

    .tx_data(tx_data_d),
    .tx_valid(tx_valid_d),
    .tx_ready(tx_ready_d),

    .router_busy(router_busy)
);

endmodule