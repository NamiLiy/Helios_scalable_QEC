/// This module combines the stage controller with planar code grid.
/// Use this for the main test bench

module standard_planar_code_2d_no_fast_channel_with_stage_controller #(
    CODE_DISTANCE = 5
) (
    clk,
    reset,
    new_round_start,
    is_error_syndromes,
    is_odd_cardinalities,
    roots,
    result_valid,
    iteration_counter,
    cycle_counter,
    deadlock
);

localparam PU_COUNT = CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 2;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

input clk;
input reset;
input new_round_start;
input [PU_COUNT-1:0] is_error_syndromes;
output [PU_COUNT-1:0] is_odd_cardinalities;
output [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
output reg result_valid;
output reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
output [31:0] cycle_counter;
output deadlock;

wire has_message_flying;
wire [STAGE_WIDTH-1:0] stage;
wire [PU_COUNT-1:0] is_odd_clusters;
reg has_odd_clusters;

always@(posedge clk) begin
    has_odd_clusters <= |is_odd_clusters;
end

standard_planar_code_2d_no_fast_channel #(.CODE_DISTANCE(CODE_DISTANCE)) decoder (
    .clk(clk),
    .reset(reset),
    .stage(stage),
    .is_error_syndromes(is_error_syndromes),
    .is_odd_clusters(is_odd_clusters),
    .is_odd_cardinalities(is_odd_cardinalities),
    .roots(roots),
    .has_message_flying(has_message_flying)
);

decoder_stage_controller #(
    .CODE_DISTANCE(CODE_DISTANCE), 
    .ITERATION_COUNTER_WIDTH(ITERATION_COUNTER_WIDTH)
) u_decoder_stage_controller (
    .clk(clk),
    .reset(reset),
    .has_message_flying(has_message_flying),
    .has_odd_clusters(has_odd_clusters),
    .new_round_start(new_round_start),
    .stage(stage),
    .result_valid(result_valid),
    .iteration_counter(iteration_counter),
    .cycle_counter(cycle_counter),
    .deadlock(deadlock)
);

endmodule