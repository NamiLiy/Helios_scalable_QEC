module root_hub_core #(
    parameter NUM_FPGAS = 5,
    parameter MAXIMUM_DELAY = 3,
    parameter CHANNEL_WIDTH = 64,
    parameter DEST_WIDTH = 8
) (
    clk,
    reset,

    tx_data_0,
    tx_valid_0,
    tx_ready_0,

    rx_data_0,
    rx_valid_0,
    rx_ready_0,

    tx_data_1,
    tx_valid_1,
    tx_ready_1,

    rx_data_1,
    rx_valid_1,
    rx_ready_1,

    tx_data_2,
    tx_valid_2,
    tx_ready_2,

    rx_data_2,
    rx_valid_2,
    rx_ready_2,

    tx_data_3,
    tx_valid_3,
    tx_ready_3,

    rx_data_3,
    rx_valid_3,
    rx_ready_3,

    tx_data_4,
    tx_valid_4,
    tx_ready_4,

    rx_data_4,
    rx_valid_4,
    rx_ready_4

    // roots // A debug port. Do not use in the real implementation
);

// Idx 0 is upstream rest are downstream in sequential order

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

localparam NUM_CHILDREN = NUM_FPGAS - 1;

input clk;
input reset;

output [63 : 0] tx_data_0;
output tx_valid_0;
input tx_ready_0;

input [63 : 0] rx_data_0;
input rx_valid_0;
output rx_ready_0;

output [63 : 0] tx_data_1;
output tx_valid_1;
input tx_ready_1;

input [63 : 0] rx_data_1;
input rx_valid_1;
output rx_ready_1;

output [63 : 0] tx_data_2;
output tx_valid_2;
input tx_ready_2;

input [63 : 0] rx_data_2;
input rx_valid_2;
output rx_ready_2;

output [63 : 0] tx_data_3;
output tx_valid_3;
input tx_ready_3;

input [63 : 0] rx_data_3;
input rx_valid_3;
output rx_ready_3;

output [63 : 0] tx_data_4;
output tx_valid_4;
input tx_ready_4;

input [63 : 0] rx_data_4;
input rx_valid_4;
output rx_ready_4;


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
    .data_from_cpu(rx_data_0),
    .valid_from_cpu(rx_valid_0),
    .ready_from_cpu(rx_ready_0),
    .data_to_cpu(tx_data_0),
    .valid_to_cpu(tx_valid_0),
    .ready_to_cpu(tx_ready_0),

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

`define CONNECT_NODE(id, tx_data_i, tx_valid_i, tx_ready_i, rx_data_i, rx_valid_i, rx_ready_i) \
    assign rx_data_d[64*id+:64] = rx_data_i; \
    assign rx_valid_d[id] = rx_valid_i; \
    assign rx_ready_i = rx_ready_d[id]; \
    assign tx_data_i = tx_data_d[64*id+:64]; \
    assign tx_valid_i = tx_valid_d[id]; \
    assign tx_ready_d[id] = tx_ready_i;

    generate
        if(NUM_FPGAS > 1) begin
            `CONNECT_NODE(1, tx_data_1, tx_valid_1, tx_ready_1, rx_data_1, rx_valid_1, rx_ready_1)
        end
        if(NUM_FPGAS > 2) begin
            `CONNECT_NODE(2, tx_data_2, tx_valid_2, tx_ready_2, rx_data_2, rx_valid_2, rx_ready_2)
        end
        if(NUM_FPGAS > 3) begin
            `CONNECT_NODE(3, tx_data_3, tx_valid_3, tx_ready_3, rx_data_3, rx_valid_3, rx_ready_3)
        end
        if(NUM_FPGAS > 4) begin
            `CONNECT_NODE(4, tx_data_4, tx_valid_4, tx_ready_4, rx_data_4, rx_valid_4, rx_ready_4)
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

// We buffer downstream data in a FIFO
// generate
//     genvar i;
//     for(i = 1; i < NUM_FPGAS; i = i + 1) begin: fpga
//         fifo_wrapper #(
//             .WIDTH(64),
//             .DEPTH(128)
//         ) input_fifo (
//             .clk(clk),
//             .reset(reset),
//             .input_data(rx_data[64*i+:64]),
//             .input_valid(rx_valid[i]),
//             .input_ready(rx_ready[i]),
//             .output_data(rx_data_d[64*i+:64]),
//             .output_valid(rx_valid_d[i]),
//             .output_ready(rx_ready_d[i])
//         );

//         fifo_wrapper #(
//             .WIDTH(64),
//             .DEPTH(128)
//         ) output_fifo (
//             .clk(clk),
//             .reset(reset),
//             .input_data(tx_data_d[64*i+:64]),
//             .input_valid(tx_valid_d[i]),
//             .input_ready(tx_ready_d[i]),
//             .output_data(tx_data[64*i+:64]),
//             .output_valid(tx_valid[i]),
//             .output_ready(tx_ready[i])
//         );
//     end
// endgenerate

endmodule