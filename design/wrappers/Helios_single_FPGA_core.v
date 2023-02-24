module Helios_single_FPGA #(
    parameter CODE_DISTANCE_X = 5,
    parameter CODE_DISTANCE_Z = 4,
    parameter WEIGHT_X = 2,
    parameter WEIGHT_Z = 2,
    parameter WEIGHT_M = 2 // Weight up down
) (
    clk,
    reset,
    new_round_start,
    measurements,
    roots,
    correction,
    result_valid,
    iteration_counter,
    cycle_counter,
    global_stage
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam PER_DIM_BIT_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = PER_DIM_BIT_WIDTH * 3;

localparam NS_ERROR_COUNT = (CODE_DISTANCE_X-1) * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam EW_ERROR_COUNT = CODE_DISTANCE_X * (CODE_DISTANCE_Z+1) * MEASUREMENT_ROUNDS;
localparam UD_ERROR_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam CORRECTION_COUNT = NS_ERROR_COUNT + EW_ERROR_COUNT + UD_ERROR_COUNT;

input clk;
input reset;
input new_round_start;
input [PU_COUNT-1:0] measurements;
output result_valid;
output [7:0] iteration_counter;
output [31:0] cycle_counter;
output [STAGE_WIDTH-1:0] global_stage;
output [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
output [CORRECTION_COUNT - 1 : 0] correction;

wire [PU_COUNT - 1 : 0] odd_clusters;
wire [PU_COUNT - 1 : 0] busy;

single_FPGA_decoding_graph #( 
    .CODE_DISTANCE_X(CODE_DISTANCE_X),
    .CODE_DISTANCE_Z(CODE_DISTANCE_Z),
    .WEIGHT_X(WEIGHT_X),
    .WEIGHT_Z(WEIGHT_Z),
    .WEIGHT_M(WEIGHT_M)
) decoding_graph (
    .clk(clk),
    .reset(reset),
    .measurements(measurements),
    .roots(roots),
    .correction(correction),
    .odd_clusters(odd_clusters),
    .busy(busy),
    .global_stage(global_stage)
);

unified_controller #( 
    .CODE_DISTANCE_X(CODE_DISTANCE_X),
    .CODE_DISTANCE_Z(CODE_DISTANCE_Z),
    .ITERATION_COUNTER_WIDTH(8),
    .MAXIMUM_DELAY(3)
) controller (
    .clk(clk),
    .reset(reset),
    .new_round_start(new_round_start),
    .busy_PE(busy),
    .odd_clusters_PE(odd_clusters),
    .global_stage(global_stage),
    .result_valid(result_valid),
    .iteration_counter(iteration_counter),
    .cycle_counter(cycle_counter)
);

endmodule