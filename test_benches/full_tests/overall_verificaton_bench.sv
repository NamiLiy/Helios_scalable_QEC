`timescale 1ns / 10ps

// Output file format
// Each line is 32 bit. Cordinates are entered as two 16 bit entries in a single line
// Test ID
// root_of_0,0
// root_of_0,1
// .....
// Test ID
// root_of_0,0
// root_of_0,1
// .......

module overall_verification_bench;

`include "../../parameters/parameters.sv"
`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

localparam CODE_DISTANCE = 5;
localparam NUM_LEAVES = 1;

reg clk;
reg reset;

wire [63:0] parent_rx_data;
wire parent_rx_valid;
wire parent_rx_ready;

wire [63:0] parent_tx_data;
wire parent_tx_valid;
wire parent_tx_ready;
wire on;

root_hub_test #(
    .CODE_DISTANCE(CODE_DISTANCE),
    .NUM_LEAVES(NUM_LEAVES)
) root_hub (
    .clk(clk),
    .reset(reset),

    .down_tx_data(parent_rx_data),
    .down_tx_valid(parent_rx_valid),
    .down_tx_ready(parent_rx_ready),
    .up_rx_data(parent_tx_data),
    .up_rx_valid(parent_tx_valid),
    .up_rx_ready(parent_tx_ready)
);


// instantiate
verification_bench_leaf #(
    .CODE_DISTANCE(CODE_DISTANCE),
    .FPGA_ID(1)
 ) decoder (
    .clk(clk),
    .reset(reset),
    .parent_rx_data(parent_rx_data),
    .parent_rx_valid(parent_rx_valid),
    .parent_rx_ready(parent_rx_ready),
    .parent_tx_data(parent_tx_data),
    .parent_tx_valid(parent_tx_valid),
    .parent_tx_ready(parent_tx_ready)
    //.roots(roots)
);

always #5 clk = ~clk;  // flip every 5ns, that is 100MHz clock

initial begin
    clk = 1'b1;
    reset = 1'b1;

    #107;
    reset = 1'b0;
    #100;
end

endmodule
