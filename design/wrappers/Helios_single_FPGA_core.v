module Helios_single_FPGA #(
    parameter GRID_WIDTH_X = 4,
    parameter GRID_WIDTH_Z = 1,
    parameter GRID_WIDTH_U = 3,
    parameter MAX_WEIGHT = 2
) (
    clk,
    reset,
    input_data,
    input_valid,
    input_ready,
    output_data,
    output_valid,
    output_ready

    // roots // A debug port. Do not use in the real implementation
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

localparam X_BIT_WIDTH = $clog2(GRID_WIDTH_X);
localparam Z_BIT_WIDTH = $clog2(GRID_WIDTH_Z);
localparam U_BIT_WIDTH = $clog2(GRID_WIDTH_U);
localparam ADDRESS_WIDTH = X_BIT_WIDTH + Z_BIT_WIDTH + U_BIT_WIDTH;

localparam PU_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam PU_COUNT = PU_COUNT_PER_ROUND * GRID_WIDTH_U;

localparam NS_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z;
localparam EW_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z + 1;
localparam UD_ERROR_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam DIAG_NS_ERROR_COUNT_PER_ROUND = ((GRID_WIDTH_X-1) * GRID_WIDTH_Z) - GRID_WIDTH_Z;
localparam DIAG_EW_ERROR_COUNT_PER_ROUND = ((GRID_WIDTH_X-1) * GRID_WIDTH_Z) - (GRID_WIDTH_Z + 1);
localparam DIAG_HOOK_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_U > 3) ? GRID_WIDTH_U-1 : 0;
localparam CORRECTION_COUNT_PER_ROUND = NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND + UD_ERROR_COUNT_PER_ROUND + DIAG_NS_ERROR_COUNT_PER_ROUND + DIAG_EW_ERROR_COUNT_PER_ROUND + DIAG_HOOK_ERROR_COUNT_PER_ROUND;

input clk;
input reset;

input [7 : 0] input_data;
input input_valid;
output input_ready;
output [7 : 0] output_data;
output output_valid;
input output_ready;

wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;

wire [STAGE_WIDTH-1:0] global_stage;
wire [CORRECTION_COUNT_PER_ROUND - 1 : 0] correction;

wire [PU_COUNT_PER_ROUND-1:0] measurements;
wire [PU_COUNT - 1 : 0] odd_clusters;
wire [PU_COUNT - 1 : 0] busy;

single_FPGA_decoding_graph_dynamic_rsc #( 
    .GRID_WIDTH_X(GRID_WIDTH_X),
    .GRID_WIDTH_Z(GRID_WIDTH_Z),
    .GRID_WIDTH_U(GRID_WIDTH_U),
    .MAX_WEIGHT(MAX_WEIGHT)
) decoding_graph_rsc (
    .clk(clk),
    .reset(reset),
    .measurements(measurements),
    .odd_clusters(odd_clusters),
    .roots(roots),
    .correction(correction),
    .busy(busy),
    .global_stage(global_stage)
);

unified_controller #( 
    .GRID_WIDTH_X(GRID_WIDTH_X),
    .GRID_WIDTH_Z(GRID_WIDTH_Z),
    .GRID_WIDTH_U(GRID_WIDTH_U),
    .ITERATION_COUNTER_WIDTH(8),
    .MAXIMUM_DELAY(3)
) controller (
    .clk(clk),
    .reset(reset),
    .input_data(input_data),
    .input_valid(input_valid),
    .input_ready(input_ready),
    .output_data(output_data),
    .output_valid(output_valid),
    .output_ready(output_ready),
    .busy_PE(busy),
    .odd_clusters_PE(odd_clusters),
    .global_stage(global_stage),
    .measurements(measurements),
    .correction(correction)
);

endmodule