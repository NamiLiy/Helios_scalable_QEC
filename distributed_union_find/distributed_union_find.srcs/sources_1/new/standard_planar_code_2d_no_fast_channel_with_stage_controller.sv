/// This module combines the stage controller with planar code grid.
/// Use this for the main test bench

module standard_planar_code_3d_no_fast_channel_with_stage_controller #(
    parameter CODE_DISTANCE_X = 4,
    parameter CODE_DISTANCE_Z = 12,
    parameter WEIGHT_X = 3,
    parameter WEIGHT_Z = 1,
    parameter WEIGHT_UD = 1 // Weight up down
) (
    clk,
    reset,
    new_round_start,
    is_error_syndromes,
    roots,
    result_valid,
    iteration_counter,
    cycle_counter,
    deadlock,
    final_cardinality

);

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam PER_DIMENSION_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

input clk;
input reset;
input new_round_start;
input [PU_COUNT-1:0] is_error_syndromes;
output [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
output reg result_valid;
output reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
output [31:0] cycle_counter;
output deadlock;
output final_cardinality;

wire [PU_COUNT-1:0] is_odd_cardinalities;
wire [PU_COUNT-1:0] is_touching_boundaries;
wire has_message_flying;
wire [STAGE_WIDTH-1:0] stage;
wire [PU_COUNT-1:0] is_odd_clusters;
reg has_odd_clusters;

always@(posedge clk) begin
    has_odd_clusters <= |is_odd_clusters;
end

standard_planar_code_3d_no_fast_channel #(
    .CODE_DISTANCE_X(CODE_DISTANCE_X),
    .CODE_DISTANCE_Z(CODE_DISTANCE_Z),
    .WEIGHT_X(WEIGHT_X),
    .WEIGHT_Z(WEIGHT_Z),
    .WEIGHT_UD(WEIGHT_UD)
) decoder (
    .clk(clk),
    .reset(reset),
    .stage(stage),
    .is_error_syndromes(is_error_syndromes),
    .is_odd_clusters(is_odd_clusters),
    .is_odd_cardinalities(is_odd_cardinalities),
    .is_touching_boundaries(is_touching_boundaries),
    .roots(roots),
    .has_message_flying(has_message_flying)
);

decoder_stage_controller #(
    .CODE_DISTANCE_X(CODE_DISTANCE_X),
    .CODE_DISTANCE_Z(CODE_DISTANCE_Z),
    .ITERATION_COUNTER_WIDTH(ITERATION_COUNTER_WIDTH)
) u_decoder_stage_controller (
    .clk(clk),
    .reset(reset),
    .has_message_flying(has_message_flying),
    .has_odd_clusters(has_odd_clusters),
    .is_touching_boundaries(is_touching_boundaries),
    .is_odd_cardinalities(is_odd_cardinalities),
    .roots(roots),
    .new_round_start(new_round_start),
    .stage(stage),
    .result_valid(result_valid),
    .iteration_counter(iteration_counter),
    .cycle_counter(cycle_counter),
    .deadlock(deadlock),
    .final_cardinality(final_cardinality)
);

endmodule