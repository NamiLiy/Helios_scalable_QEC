/// This module is a synthesizable wrapper around the top module.
/// It just drops the debug lines from the top module used for simulation

module standard_planar_code_3d_no_fast_channel_synthesizable_top #(
    CODE_DISTANCE = 3
) (
    clk,
    reset,
    new_round_start,
    is_error_syndromes,
    is_odd_cardinalities,
    roots,
    result_valid
    // iteration_counter,
    // cycle_counter
);

localparam PU_COUNT = CODE_DISTANCE * CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
// localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

input clk;
input reset;
input new_round_start;
input [PU_COUNT-1:0] is_error_syndromes;
output [PU_COUNT-1:0] is_odd_cardinalities;
output [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
output result_valid;

// output reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
// output [31:0] cycle_counter;

standard_planar_code_3d_no_fast_channel_with_stage_controller #(.CODE_DISTANCE(CODE_DISTANCE)) top_module (
    .clk(clk),
    .reset(reset),
    .new_round_start(new_round_start),
    .is_error_syndromes(is_error_syndromes),
    .is_odd_cardinalities(is_odd_cardinalities),
    .roots(roots),
    .result_valid(result_valid),
    .iteration_counter(),
    .cycle_counter(),
    .deadlock()
);

endmodule