module Helios_single_FPGA #(
    parameter GRID_WIDTH_X = 4,
    parameter GRID_WIDTH_Z = 1,
    parameter GRID_WIDTH_U = 3,
    parameter MAX_WEIGHT = 2,
    parameter NUM_CONTEXTS = 2,
    parameter NUM_FPGAS = 5
) (
    clk,
    reset,

    input_data,
    input_valid,
    input_ready,

    output_data,
    output_valid,
    output_ready,

    parent_rx_data,
    parent_rx_valid,
    parent_rx_ready,

    parent_tx_data,
    parent_tx_valid,
    parent_tx_ready,

    FPGA_ID


    // roots // A debug port. Do not use in the real implementation
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

localparam X_BIT_WIDTH = $clog2(GRID_WIDTH_X);
localparam Z_BIT_WIDTH = $clog2(GRID_WIDTH_Z);
localparam U_BIT_WIDTH = $clog2(GRID_WIDTH_U);
localparam FPGA_BIT_WIDTH = $clog2(NUM_FPGAS);
localparam ADDRESS_WIDTH = X_BIT_WIDTH + Z_BIT_WIDTH + U_BIT_WIDTH + FPGA_BIT_WIDTH;

localparam PU_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam PU_COUNT = PU_COUNT_PER_ROUND * GRID_WIDTH_U;

localparam NS_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z;
localparam EW_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z + 1;
localparam UD_ERROR_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam CORRECTION_COUNT_PER_ROUND = NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND + UD_ERROR_COUNT_PER_ROUND;

input clk;
input reset;

input [7 : 0] input_data;
input input_valid;
output input_ready;
output [7 : 0] output_data;
output output_valid;
input output_ready;

input [63 : 0] parent_rx_data;
input parent_rx_valid;
output parent_rx_ready;

output [63 : 0] parent_tx_data;
output parent_tx_valid;
input parent_tx_ready;

input [$clog2(NUM_FPGAS) -1 : 0] FPGA_ID;

wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;

wire [STAGE_WIDTH-1:0] global_stage;
wire [CORRECTION_COUNT_PER_ROUND - 1 : 0] correction;

wire [PU_COUNT_PER_ROUND-1:0] measurements;
wire [PU_COUNT - 1 : 0] odd_clusters;
wire [PU_COUNT - 1 : 0] busy;

wire [63:0] input_ctrl_rx_data;
wire input_ctrl_rx_valid;
wire input_ctrl_rx_ready;

wire [63:0] output_ctrl_tx_data;
wire output_ctrl_tx_valid;
wire output_ctrl_tx_ready;

single_FPGA_decoding_graph_dynamic_rsc #( 
    .GRID_WIDTH_X(GRID_WIDTH_X),
    .GRID_WIDTH_Z(GRID_WIDTH_Z),
    .GRID_WIDTH_U(GRID_WIDTH_U),
    .MAX_WEIGHT(MAX_WEIGHT),
    .NUM_CONTEXTS(NUM_CONTEXTS),
    .NUM_FPGAS(NUM_FPGAS)
) decoding_graph_rsc (
    .clk(clk),
    .reset(reset),
    .measurements(measurements),
    .odd_clusters(odd_clusters),
    .roots(roots),
    .correction(correction),
    .busy(busy),
    .global_stage(global_stage),
    .FPGA_ID(FPGA_ID)
);

unified_controller #( 
    .GRID_WIDTH_X(GRID_WIDTH_X),
    .GRID_WIDTH_Z(GRID_WIDTH_Z),
    .GRID_WIDTH_U(GRID_WIDTH_U),
    .ITERATION_COUNTER_WIDTH(8),
    .MAXIMUM_DELAY(3),
    .NUM_CONTEXTS(NUM_CONTEXTS),
    .NUM_FPGAS(NUM_FPGAS)
) controller (
    .clk(clk),
    .reset(reset),
    .input_data(input_data),
    .input_valid(input_valid),
    .input_ready(input_ready),
    .output_data(output_data),
    .output_valid(output_valid),
    .output_ready(output_ready),
    .input_ctrl_rx_data(input_ctrl_rx_data),
    .input_ctrl_rx_valid(input_ctrl_rx_valid),
    .input_ctrl_rx_ready(input_ctrl_rx_ready),
    .output_ctrl_tx_data(output_ctrl_tx_data),
    .output_ctrl_tx_valid(output_ctrl_tx_valid),
    .output_ctrl_tx_ready(output_ctrl_tx_ready),
    .busy_PE(busy),
    .odd_clusters_PE(odd_clusters),
    .global_stage(global_stage),
    .measurements(measurements),
    .correction(correction)
);

fifo_wrapper #(
    .WIDTH(64),
    .DEPTH(64)
) parent_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(parent_rx_data),
    .input_valid(parent_rx_valid),
    .input_ready(parent_rx_ready),
    .output_data(input_ctrl_rx_data),
    .output_valid(input_ctrl_rx_valid),
    .output_ready(input_ctrl_rx_ready)
);

fifo_wrapper #(
    .WIDTH(64),
    .DEPTH(64)
) controller_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(output_ctrl_tx_data),
    .input_valid(output_ctrl_tx_valid),
    .input_ready(output_ctrl_tx_ready),
    .output_data(parent_tx_data),
    .output_valid(parent_tx_valid),
    .output_ready(parent_tx_ready)
);

endmodule