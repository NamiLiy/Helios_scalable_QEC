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
localparam LOGICAL_QUBITS_PER_DIM_PER_FPGA = 2; //This is across all the FPGAs. IF this is not compatible with qubits per dim, then the test could fail
localparam NUM_LEAVES_PER_DIM = 2;
localparam ROUTER_DELAY = 2;
localparam MAX_COUNT = 10;
localparam MULTI_FPGA_RUN = 0;
localparam MEASUREMENT_FUSION=0;

// `define SLICE_VEC(vec, idx, width) (vec[(idx+1)*width -1 : idx*width])

localparam NUM_LEAVES = NUM_LEAVES_PER_DIM * NUM_LEAVES_PER_DIM;
localparam LOGICAL_QUBITS_PER_DIM = LOGICAL_QUBITS_PER_DIM_PER_FPGA * NUM_LEAVES_PER_DIM;

reg clk;
reg reset;

wire [64*NUM_LEAVES - 1:0] parent_rx_data;
wire [NUM_LEAVES - 1 : 0] parent_rx_valid;
wire [NUM_LEAVES - 1 : 0] parent_rx_ready;

wire [64*NUM_LEAVES - 1:0] parent_tx_data;
wire [NUM_LEAVES - 1 : 0] parent_tx_valid;
wire [NUM_LEAVES - 1 : 0] parent_tx_ready;
wire on;

root_hub_test #(
    .CODE_DISTANCE(CODE_DISTANCE),
    .ROUTER_DELAY(ROUTER_DELAY),
    .NUM_LEAVES(NUM_LEAVES),
    .FPGA_ID(0)
) root_hub_tb(
    .clk(clk),
    .reset(reset),
    .down_tx_data(parent_rx_data),
    .down_tx_valid(parent_rx_valid),
    .down_tx_ready(parent_rx_ready),
    .up_rx_data(parent_tx_data),
    .up_rx_valid(parent_tx_valid),
    .up_rx_ready(parent_tx_ready)
);


generate
    genvar i;
    for(i = 0; i < NUM_LEAVES; i = i + 1) begin : leaf
        localparam south_boundary = (i==0 || i==1) ? 1 : 0;
        localparam east_boundary = (i==0 || i==2) ? 1 : 0;

        wire [63:0] local_parent_rx_data;
        assign local_parent_rx_data = `SLICE_VEC(parent_rx_data, i, 64);

        wire local_parent_rx_valid;
        assign local_parent_rx_valid = `SLICE_VEC(parent_rx_valid, i, 1);

        wire local_parent_rx_ready;
        assign parent_rx_ready[i] = local_parent_rx_ready;

        wire [63:0] local_parent_tx_data;
        assign parent_tx_data[(i+1)*64 - 1 : i*64] = local_parent_tx_data;

        wire local_parent_tx_valid;
        assign parent_tx_valid[i] = local_parent_tx_valid;

        wire local_parent_tx_ready;
        assign local_parent_tx_ready = parent_tx_ready[i];

        verification_bench_leaf #(
            .CODE_DISTANCE(CODE_DISTANCE),
            .NUM_FPGAS(NUM_LEAVES + 1),
            .ROUTER_DELAY(ROUTER_DELAY),
            .FPGA_ID(i + 1),
            .NUM_CONTEXTS(MEASUREMENT_FUSION + 1),
            .LOGICAL_QUBITS_PER_DIM(LOGICAL_QUBITS_PER_DIM_PER_FPGA),
            .ADDITIONAL_BOUNDARY_SOUTH(south_boundary),
            .ADDITIONAL_BOUNDARY_EAST(east_boundary)
        ) decoder_tb(
            .clk(clk),
            .reset(reset),
            .parent_rx_data(local_parent_rx_data),
            .parent_rx_valid(local_parent_rx_valid),
            .parent_rx_ready(local_parent_rx_ready),
            .parent_tx_data(local_parent_tx_data),
            .parent_tx_valid(local_parent_tx_valid),
            .parent_tx_ready(local_parent_tx_ready)
            //.roots(roots)
        );
    end
endgenerate


always #5 clk = ~clk;  // flip every 5ns, that is 100MHz clock

initial begin
    clk = 1'b1;
    reset = 1'b1;

    #107;
    reset = 1'b0;
    #100;
end

endmodule
