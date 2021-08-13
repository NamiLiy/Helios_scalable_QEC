/// This module combines the stage controller with planar code grid.
/// Use this for the main test bench

module left_with_stage_controller #(
    parameter CODE_DISTANCE_X = 5,
    parameter CODE_DISTANCE_Z = 4,
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
    final_cardinality,

    final_fifo_out_data,
    final_fifo_out_valid,
    final_fifo_out_ready,
    final_fifo_in_data,
    final_fifo_in_valid,
    final_fifo_in_ready,

    has_message_flying_otherside,
    has_odd_clusters_otherside
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam PER_DIMENSION_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

localparam UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH;  // [old_root, updated_root]
localparam MASTER_FIFO_WIDTH = UNION_MESSAGE_WIDTH + 1 + 1;
localparam FIFO_COUNT = MEASUREMENT_ROUNDS * (CODE_DISTANCE_Z);
localparam FINAL_FIFO_WIDTH = MASTER_FIFO_WIDTH + $clog2(FIFO_COUNT);


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

input has_message_flying_otherside;
input has_odd_clusters_otherside;

output [FINAL_FIFO_WIDTH - 1 :0] final_fifo_out_data;
output final_fifo_out_valid;
input final_fifo_out_ready;
input [FINAL_FIFO_WIDTH - 1 :0] final_fifo_in_data;
input final_fifo_in_valid;
output final_fifo_in_ready;

wire [MASTER_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_out_data_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_out_valid_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_out_ready_vector;
wire [MASTER_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_in_data_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_in_valid_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_in_ready_vector;

wire [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_out_data;
wire sc_fifo_out_valid;
wire sc_fifo_out_ready;
wire [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_in_data;
wire sc_fifo_in_valid;
wire sc_fifo_in_ready;

wire [PU_COUNT-1:0] is_odd_cardinalities;
wire [PU_COUNT-1:0] is_touching_boundaries;
wire has_message_flying;
wire [STAGE_WIDTH-1:0] stage;
wire [PU_COUNT-1:0] is_odd_clusters;
reg has_odd_clusters;
wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] left_roots;
wire has_message_flying_sc;
wire has_message_flying_grid;
wire has_message_flying_interconnect;

assign has_message_flying_sc = has_message_flying_grid | has_message_flying_interconnect;

always@(posedge clk) begin
    has_odd_clusters <= |is_odd_clusters;
end

standard_planar_code_3d_no_fast_channel_left #(
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
    .roots(left_roots),
    .has_message_flying(has_message_flying_grid),
    .master_fifo_out_data_vector(master_fifo_out_data_vector),
    .master_fifo_out_valid_vector(master_fifo_out_valid_vector),
    .master_fifo_out_ready_vector(master_fifo_out_ready_vector),
    .master_fifo_in_data_vector(master_fifo_in_data_vector),
    .master_fifo_in_valid_vector(master_fifo_in_valid_vector),
    .master_fifo_in_ready_vector(master_fifo_in_ready_vector)
);

decoder_stage_controller_left #(
    .CODE_DISTANCE_X(CODE_DISTANCE_X),
    .CODE_DISTANCE_Z(CODE_DISTANCE_Z),
    .ITERATION_COUNTER_WIDTH(ITERATION_COUNTER_WIDTH)
) u_decoder_stage_controller_left (
    .clk(clk),
    .reset(reset),
    .has_message_flying(has_message_flying_sc),
    .has_odd_clusters(has_odd_clusters),
    .is_touching_boundaries(is_touching_boundaries),
    .is_odd_cardinalities(is_odd_cardinalities),
    .roots(left_roots),
    .new_round_start(new_round_start),
    .stage(stage),
    .result_valid(result_valid),
    .iteration_counter(iteration_counter),
    .cycle_counter(cycle_counter),
    .deadlock(deadlock),
    .final_cardinality(final_cardinality),
    .sc_fifo_out_data(sc_fifo_out_data),
    .sc_fifo_out_valid(sc_fifo_out_valid),
    .sc_fifo_out_ready(sc_fifo_out_ready),
    .sc_fifo_in_data(sc_fifo_in_data),
    .sc_fifo_in_valid(sc_fifo_in_valid),
    .sc_fifo_in_ready(sc_fifo_in_ready),
    .has_message_flying_otherside(has_message_flying_otherside),
    .has_odd_clusters_otherside(has_odd_clusters_otherside),
    .net_roots_out(roots)
);

final_arbitration_unit #(
    .CODE_DISTANCE_X(CODE_DISTANCE_X),
    .CODE_DISTANCE_Z(CODE_DISTANCE_Z)
) u_final_arbitration_unit_left (
    .clk(clk),
    .reset(reset),
    .master_fifo_out_data_vector(master_fifo_out_data_vector),
    .master_fifo_out_valid_vector(master_fifo_out_valid_vector),
    .master_fifo_out_ready_vector(master_fifo_out_ready_vector),
    .master_fifo_in_data_vector(master_fifo_in_data_vector),
    .master_fifo_in_valid_vector(master_fifo_in_valid_vector),
    .master_fifo_in_ready_vector(master_fifo_in_ready_vector),
    .sc_fifo_out_data(sc_fifo_out_data),
    .sc_fifo_out_valid(sc_fifo_out_valid),
    .sc_fifo_out_ready(sc_fifo_out_ready),
    .sc_fifo_in_data(sc_fifo_in_data),
    .sc_fifo_in_valid(sc_fifo_in_valid),
    .sc_fifo_in_ready(sc_fifo_in_ready),
    .final_fifo_out_data(final_fifo_out_data),
    .final_fifo_out_valid(final_fifo_out_valid),
    .final_fifo_out_ready(final_fifo_out_ready),
    .final_fifo_in_data(final_fifo_in_data),
    .final_fifo_in_valid(final_fifo_in_valid),
    .final_fifo_in_ready(final_fifo_in_ready),
    .has_flying_messages(has_message_flying_interconnect)
);

endmodule