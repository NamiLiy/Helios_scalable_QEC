module root_hub_/*$$ID*/ #(
    parameter CODE_DISTANCE_X = /*$$CODE_DISTANCE_X*/,
    parameter CODE_DISTANCE_Z = /*$$CODE_DISTANCE_Z*/,
    parameter WEIGHT_X = 1,
    parameter WEIGHT_Z = 1,
    parameter WEIGHT_UD = 1 // Weight up down
) (
    clk,
    reset,

    // Temporary ports for debug
    new_round_start,
    // is_error_syndromes,
    // roots,
    result_valid,
    iteration_counter,
    cycle_counter,
    deadlock,
    final_cardinality,

    // Following three ports are for single FPGA debug only and should not be used in the multi-FPGA design
    is_touching_boundaries, 
    is_odd_cardinalities, 
    roots,

    // downstream_fifo_out_data,
    // downstream_fifo_out_valid,
    // downstream_fifo_out_ready,
    // downstream_fifo_in_data,
    // downstream_fifo_in_valid,
    // downstream_fifo_in_ready,

    downstream_has_message_flying,
    downstream_has_odd_clusters,
    downstream_state_signal,

    upstream_has_message_flying
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = /*$$MEASUREMENT_ROUNDS*/;
localparam PU_COUNT = /*$$PU_COUNT*/;
localparam PER_DIMENSION_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = /*$$ADDRESS_WIDTH*/;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]

localparam MASTER_FIFO_WIDTH = DIRECT_MESSAGE_WIDTH + 1;

localparam HUB_FIFO_WIDTH = /*$$HUB_FIFO_WIDTH*/;
localparam HUB_FIFO_PHYSICAL_WIDTH = /*$$HUB_FIFO_PHYSICAL_WIDTH*/;
localparam DOWNSTREAM_FIFO_COUNT = /*$$DOWNSTREAM_FIFO_COUNT*/;
localparam FPGAID_WIDTH = /*$$FPGAID_WIDTH*/;
localparam FIFO_IDWIDTH = /*$$FIFO_IDWIDTH*/;
localparam STATE_SIGNAL_WIDTH = /*$$STATE_SIGNAL_WIDTH*/;
localparam ROOT_WIDTH = /*$$ROOT_WIDTH*/;


input clk;
input reset;
input new_round_start;

output result_valid;
output [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
output [31:0] cycle_counter;
output deadlock;
output final_cardinality;

// output has_message_flying_otherside;
// output has_odd_clusters_otherside;

// wire [HUB_FIFO_WIDTH - 1 :0] upstream_fifo_out_data;
// wire upstream_fifo_out_valid;
// wire upstream_fifo_out_ready;
// wire [HUB_FIFO_WIDTH - 1 :0] upstream_fifo_in_data;
// wire upstream_fifo_in_valid;
// wire upstream_fifo_in_ready;

// output [DOWNSTREAM_FIFO_COUNT*HUB_FIFO_PHYSICAL_WIDTH - 1 :0] downstream_fifo_out_data;
// output [DOWNSTREAM_FIFO_COUNT - 1 :0] downstream_fifo_out_valid;
// input [DOWNSTREAM_FIFO_COUNT - 1 :0] downstream_fifo_out_ready;
// input [DOWNSTREAM_FIFO_COUNT*HUB_FIFO_PHYSICAL_WIDTH - 1 :0] downstream_fifo_in_data;
// input [DOWNSTREAM_FIFO_COUNT - 1 :0] downstream_fifo_in_valid;
// output [DOWNSTREAM_FIFO_COUNT - 1 :0] downstream_fifo_in_ready;

output upstream_has_message_flying;
wire upstream_has_odd_clusters;
wire [1:0] upstream_state_signal;

input [DOWNSTREAM_FIFO_COUNT - 1 :0] downstream_has_message_flying;
input [DOWNSTREAM_FIFO_COUNT - 1 :0] downstream_has_odd_clusters;
output [STATE_SIGNAL_WIDTH - 1 :0] downstream_state_signal;

input [PU_COUNT-1:0] is_odd_cardinalities;
input [PU_COUNT-1:0] is_touching_boundaries;
input [ROOT_WIDTH-1:0] roots;



top_module_hub_/*$$ID*/ #(
    .CODE_DISTANCE_X(/*$$CODE_DISTANCE_X*/),
    .CODE_DISTANCE_Z(/*$$CODE_DISTANCE_Z*/),
    .WEIGHT_X(WEIGHT_X),
    .WEIGHT_Z(WEIGHT_Z),
    .WEIGHT_UD(WEIGHT_UD)
) u_hub_/*$$ID*/ (
    .clk(clk),
    .reset(reset),

    // Temporary ports for debug
    // .new_round_start(new_round_start),
    // .is_error_syndromes(is_error_syndromes),
    // .roots(roots),
    // .result_valid(result_valid),
    // .iteration_counter(iteration_counter),
    // .cycle_counter(cycle_counter),
    // .deadlock(deadlock),
    // .final_cardinality(final_cardinality)


    // .upstream_fifo_out_data(upstream_fifo_out_data),
    // .upstream_fifo_out_valid(upstream_fifo_out_valid),
    // .upstream_fifo_out_ready(upstream_fifo_out_ready),
    // .upstream_fifo_in_data(upstream_fifo_in_data),
    // .upstream_fifo_in_valid(upstream_fifo_in_valid),
    // .upstream_fifo_in_ready(upstream_fifo_in_ready),

    // .downstream_fifo_out_data(downstream_fifo_out_data),
    // .downstream_fifo_out_valid(downstream_fifo_out_valid),
    // .downstream_fifo_out_ready(downstream_fifo_out_ready),
    // .downstream_fifo_in_data(downstream_fifo_in_data),
    // .downstream_fifo_in_valid(downstream_fifo_in_valid),
    // .downstream_fifo_in_ready(downstream_fifo_in_ready),

    .upstream_has_message_flying(upstream_has_message_flying),
    .upstream_has_odd_clusters(upstream_has_odd_clusters),
    .upstream_state_signal(upstream_state_signal),

    .downstream_has_message_flying(downstream_has_message_flying),
    .downstream_has_odd_clusters(downstream_has_odd_clusters),
    .downstream_state_signal(downstream_state_signal)
);

decoder_stage_controller_master_/*$$ID*/ #(
    .CODE_DISTANCE_X(CODE_DISTANCE_X),
    .CODE_DISTANCE_Z(CODE_DISTANCE_Z),
    .ITERATION_COUNTER_WIDTH(ITERATION_COUNTER_WIDTH)
) u_decoder_stage_controller (
    .clk(clk),
    .reset(reset),
    // .has_message_flying(has_message_flying_sc),
    // .has_odd_clusters(has_odd_clusters),

    .is_touching_boundaries(is_touching_boundaries),
    .is_odd_cardinalities(is_odd_cardinalities),
    .roots(roots),

    .new_round_start(new_round_start),
    // .stage(stage),
    .result_valid(result_valid),
    .iteration_counter(iteration_counter),
    .cycle_counter(cycle_counter),
    .deadlock(deadlock),
    .final_cardinality(final_cardinality),

    // .sc_fifo_out_data(upstream_fifo_in_data[MASTER_FIFO_WIDTH - 1 :0]),
    // .sc_fifo_out_valid(upstream_fifo_in_valid),
    // .sc_fifo_out_ready(upstream_fifo_in_ready),
    // .sc_fifo_in_data(upstream_fifo_out_data[MASTER_FIFO_WIDTH - 1 :0]),
    // .sc_fifo_in_valid(upstream_fifo_out_valid),
    // .sc_fifo_in_ready(upstream_fifo_out_ready),

    .downstream_has_message_flying(upstream_has_message_flying),
    .downstream_has_odd_clusters(upstream_has_odd_clusters),
    .state_signal(upstream_state_signal)
);

// Beasure master stage controller always send broadcast messages
// assign upstream_fifo_in_data[HUB_FIFO_WIDTH-1 : MASTER_FIFO_WIDTH] = 32'hffffffff;

endmodule