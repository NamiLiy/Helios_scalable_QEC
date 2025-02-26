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
localparam LOGICAL_QUBITS_PER_DIM_PER_FPGA = 2;
localparam NUM_LEAVES_PER_DIM = 2;
localparam ROUTER_DELAY = 2;
localparam MAX_COUNT = 10;
localparam MEASUREMENT_FUSION=1;
localparam NUM_CONTEXTS=2*CODE_DISTANCE;
localparam IS_SIM=1;

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

wire [64*NUM_LEAVES - 1:0] horizontal_out_data;
wire [NUM_LEAVES - 1 : 0] horizontal_out_valid;
wire [NUM_LEAVES - 1 : 0] horizontal_out_ready;

wire [64*NUM_LEAVES - 1:0] horizontal_in_data;
wire [NUM_LEAVES - 1 : 0] horizontal_in_valid;
wire [NUM_LEAVES - 1 : 0] horizontal_in_ready;

wire [64*NUM_LEAVES - 1:0] vertical_out_data;
wire [NUM_LEAVES - 1 : 0] vertical_out_valid;
wire [NUM_LEAVES - 1 : 0] vertical_out_ready;

wire [64*NUM_LEAVES - 1:0] vertical_in_data;
wire [NUM_LEAVES - 1 : 0] vertical_in_valid;
wire [NUM_LEAVES - 1 : 0] vertical_in_ready;

genvar i;

generate
    for(i = 0; i < NUM_LEAVES; i = i + 1) begin : leaf

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
            .NUM_CONTEXTS(NUM_CONTEXTS),
            .LOGICAL_QUBITS_PER_DIM(LOGICAL_QUBITS_PER_DIM_PER_FPGA),
            .MEASUREMENT_FUSION_ENABLED(MEASUREMENT_FUSION),
            .IS_SIM(IS_SIM)
        ) decoder_tb(
            .clk(clk),
            .reset(reset),
            .parent_rx_data(local_parent_rx_data),
            .parent_rx_valid(local_parent_rx_valid),
            .parent_rx_ready(local_parent_rx_ready),
            .parent_tx_data(local_parent_tx_data),
            .parent_tx_valid(local_parent_tx_valid),
            .parent_tx_ready(local_parent_tx_ready),

            .grid_1_out_data(horizontal_out_data[(i+1)*64 - 1 : i*64]),
            .grid_1_out_valid(horizontal_out_valid[i]),
            .grid_1_out_ready(horizontal_out_ready[i]),

            .grid_2_out_data(vertical_out_data[(i+1)*64 - 1 : i*64]),
            .grid_2_out_valid(vertical_out_valid[i]),
            .grid_2_out_ready(vertical_out_ready[i]),

            .grid_1_in_data(horizontal_in_data[i*64 +: 64]),
            .grid_1_in_valid(horizontal_in_valid[i]),
            .grid_1_in_ready(horizontal_in_ready[i]),

            .grid_2_in_data(vertical_in_data[i*64 +: 64]),
            .grid_2_in_valid(vertical_in_valid[i]),
            .grid_2_in_ready(vertical_in_ready[i])
            //.roots(roots)
        );
    end
endgenerate

generate
    for(i = 0; i < NUM_LEAVES; i = i + 1) begin : horizontal_fifos
        localparam hc = (i==0 || i==2) ? (i+1) : (i-1);
        fifo_wrapper #(
            .WIDTH(64),
            .DEPTH(128)
        ) output_fifo (
            .clk(clk),
            .reset(reset),
            .input_data(horizontal_out_data[(i+1)*64 - 1 : i*64]),
            .input_valid(horizontal_out_valid[i]),
            .input_ready(horizontal_out_ready[i]),
            .output_data(horizontal_in_data[(hc+1)*64 - 1 : hc*64]),
            .output_valid(horizontal_in_valid[hc]),
            .output_ready(horizontal_in_ready[hc])
        );
    end
endgenerate

generate
    for(i = 0; i < NUM_LEAVES; i = i + 1) begin : vertical_fifos
        localparam vc = (i==0 || i==1) ? (i+2) : (i-2);
        fifo_wrapper #(
            .WIDTH(64),
            .DEPTH(128)
        ) output_fifo (
            .clk(clk),
            .reset(reset),
            .input_data(vertical_out_data[(i+1)*64 - 1 : i*64]),
            .input_valid(vertical_out_valid[i]),
            .input_ready(vertical_out_ready[i]),
            .output_data(vertical_in_data[(vc+1)*64 - 1 : vc*64]),
            .output_valid(vertical_in_valid[vc]),
            .output_ready(vertical_in_ready[vc])
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
