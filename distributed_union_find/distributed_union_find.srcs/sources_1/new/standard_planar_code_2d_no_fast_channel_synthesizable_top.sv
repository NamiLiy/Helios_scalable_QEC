/// This module is a synthesizable wrapper around the top module.
/// It just drops the debug lines from the top module used for simulation

module standard_planar_code_3d_no_fast_channel_synthesizable_top #(
    CODE_DISTANCE = 3
) (
    clk,
    reset,
    new_round_start,
    is_error_syndromes,
    result_valid,
    cycle_counter,
    iteration_counter,
    deadlock,
    final_cardinality
);

localparam PU_COUNT = CODE_DISTANCE * CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations
localparam UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH;  // [old_root, updated_root]
localparam MASTER_FIFO_WIDTH = UNION_MESSAGE_WIDTH + 1 + 1;
localparam FIFO_COUNT = CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam FINAL_FIFO_WIDTH = MASTER_FIFO_WIDTH + $clog2(FIFO_COUNT);

input clk;
input reset;
input new_round_start;
input [PU_COUNT-1:0] is_error_syndromes;
output result_valid;
output [7:0] iteration_counter;
output [31:0] cycle_counter;
output deadlock;
output final_cardinality;

wire [FINAL_FIFO_WIDTH - 1 :0] final_fifo_out_data;
wire final_fifo_out_valid;
wire final_fifo_out_ready;
wire [FINAL_FIFO_WIDTH - 1 :0] final_fifo_in_data;
wire final_fifo_in_valid;
wire final_fifo_in_ready;
wire has_message_flying_otherside;
wire has_odd_clusters_flying_other_side;

// output reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
// output [31:0] cycle_counter;

standard_planar_code_3d_no_fast_channel_with_stage_controller_left #(.CODE_DISTANCE(CODE_DISTANCE)) left_module (
    .clk(clk),
    .reset(reset),
    .new_round_start(new_round_start), //pulse signal
    .is_error_syndromes(is_error_syndromes),
    .roots(),
    .result_valid(result_valid),
    .iteration_counter(iteration_counter),
    .cycle_counter(cycle_counter),
    .deadlock(deadlock),
    .final_cardinality(final_cardinality),
    .final_fifo_out_data(final_fifo_out_data),
    .final_fifo_out_valid(final_fifo_out_valid),
    .final_fifo_out_ready(final_fifo_out_ready),
    .final_fifo_in_data(final_fifo_in_data),
    .final_fifo_in_valid(final_fifo_in_valid),
    .final_fifo_in_ready(final_fifo_in_ready),
    .has_message_flying_otherside(has_message_flying_otherside),
    .has_odd_clusters_otherside(has_odd_clusters_otherside)
);

standard_planar_code_3d_no_fast_channel_with_stage_controller_right #(.CODE_DISTANCE(CODE_DISTANCE)) right_module (
    .clk(clk),
    .reset(reset),
    .new_round_start(new_round_start), //pulse signal
    .is_error_syndromes(is_error_syndromes),
    .roots(),
    .result_valid(),
    .iteration_counter(iteration_counter),
    .cycle_counter(cycle_counter),
    .deadlock(deadlock),
    .final_cardinality(),
    .final_fifo_out_data(final_fifo_in_data),   // The in and out are mixed since we are in debugging stage
    .final_fifo_out_valid(final_fifo_in_valid),
    .final_fifo_out_ready(final_fifo_in_ready),
    .final_fifo_in_data(final_fifo_out_data),
    .final_fifo_in_valid(final_fifo_out_valid),
    .final_fifo_in_ready(final_fifo_out_ready),
    .has_message_flying_otherside(has_message_flying_otherside),
    .has_odd_clusters_otherside(has_odd_clusters_otherside)
);

endmodule