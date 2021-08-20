`timescale 1ns / 1ps

module bench_usual_latency(
    clk,
    reset,
    init_address,
    init_is_error_syndrome,
    init_has_boundary,
    init_boundary_cost,
    stage,
    neighbor_is_fully_grown,
    neighbor_old_roots,
    neighbor_increase,
    union_out_channels_data,
    union_out_channels_valid,
    union_in_channels_data,
    union_in_channels_valid,
    direct_out_channels_data_single,
    direct_out_channels_valid,
    direct_out_channels_is_full,
    direct_in_channels_data,
    direct_in_channels_valid,
    direct_in_channels_is_taken,
    old_root,
    updated_root,
    is_error_syndrome,
    boundary_increased,
    is_odd_cluster,
    is_touching_boundary,
    is_odd_cardinality,
    pending_tell_new_root_cardinality,
    pending_tell_new_root_touching_boundary,
    
    // the addresses of peer of channels
    channel_addresses
);

// instantiate a processing unit, a compare solver and a distance solver
// connect them together to see the longest path

`include "../sources_1/new/parameters.sv"

localparam ADDRESS_WIDTH = 8;
localparam DISTANCE_WIDTH = 6;
localparam BOUNDARY_WIDTH = 2;
localparam NEIGHBOR_COUNT = 4;
localparam FAST_CHANNEL_COUNT = 0;
localparam CHANNEL_COUNT = NEIGHBOR_COUNT + FAST_CHANNEL_COUNT;
localparam CHANNEL_WIDTH = $clog2(CHANNEL_COUNT);  // the index of channel, both neighbor and direct ones
localparam UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH;  // [old_root, new_root]
localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]

input clk;
input reset;
// initialization information, which is read on reset
input [ADDRESS_WIDTH-1:0] init_address;
input init_is_error_syndrome;
input init_has_boundary;
input [BOUNDARY_WIDTH-1:0] init_boundary_cost;
// stage indicator
input [STAGE_WIDTH-1:0] stage;
// neighbor links using `neighbor_link` module
input [NEIGHBOR_COUNT-1:0] neighbor_is_fully_grown;
input [(ADDRESS_WIDTH * NEIGHBOR_COUNT)-1:0] neighbor_old_roots;  // connect to *_old_root_out
output neighbor_increase;  // connect to *_increase, shared by all neighbors
// union channels using `nonblocking_channel`, each message is packed [old_root, updated_root]
output [(UNION_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] union_out_channels_data;
output union_out_channels_valid; // single wire connects to all union channels
input [(UNION_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] union_in_channels_data;
input [CHANNEL_COUNT-1:0] union_in_channels_valid;
// direct channels using `blocking_channel`, each message is packed [receiver, is_odd_cardinality_root, is_touching_boundary]
output [DIRECT_MESSAGE_WIDTH-1:0] direct_out_channels_data_single;
output [CHANNEL_COUNT-1:0] direct_out_channels_valid;
input [CHANNEL_COUNT-1:0] direct_out_channels_is_full;
input [(DIRECT_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] direct_in_channels_data;
input [CHANNEL_COUNT-1:0] direct_in_channels_valid;
output [CHANNEL_COUNT-1:0] direct_in_channels_is_taken;

output [ADDRESS_WIDTH-1:0] old_root;
output [ADDRESS_WIDTH-1:0] updated_root;
output is_error_syndrome;
output [BOUNDARY_WIDTH-1:0] boundary_increased;
output is_odd_cluster;
output is_touching_boundary;
output is_odd_cardinality;
output pending_tell_new_root_cardinality;
output pending_tell_new_root_touching_boundary;

input [(ADDRESS_WIDTH * CHANNEL_COUNT)-1:0] channel_addresses;

// compare solvers should be a combinational logic that takes multiple addresses and output the smallest one
wire [ADDRESS_WIDTH-1:0] compare_solver_default_addr;
wire [(ADDRESS_WIDTH * CHANNEL_COUNT)-1:0] compare_solver_addrs;
wire [CHANNEL_COUNT-1:0] compare_solver_addrs_valid;
wire [ADDRESS_WIDTH-1:0] compare_solver_result;

// instant compare solver
tree_compare_solver #(
    .DATA_WIDTH(ADDRESS_WIDTH),
    .CHANNEL_COUNT(CHANNEL_COUNT)
) u_tree_compare_solver(
    .default_value(compare_solver_default_addr),
    .values(compare_solver_addrs),
    .valids(compare_solver_addrs_valid),
    .result(compare_solver_result)
);

wire [ADDRESS_WIDTH-1:0] distance_solver_target;
wire [CHANNEL_WIDTH-1:0] distance_solver_result_idx;

// instantiate distance 2d solver
tree_distance_2d_solver #(
    .PER_DIMENSION_WIDTH(4),
    .CHANNEL_COUNT(CHANNEL_COUNT)
) u_tree_distance_2d_solver(
    .points(channel_addresses),
    .target(distance_solver_target),
    .result_idx(distance_solver_result_idx)
);

// instantiate processing unit
processing_unit #(
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .DISTANCE_WIDTH(DISTANCE_WIDTH),
    .BOUNDARY_WIDTH(BOUNDARY_WIDTH),
    .NEIGHBOR_COUNT(NEIGHBOR_COUNT),
    .FAST_CHANNEL_COUNT(FAST_CHANNEL_COUNT)
) u_processing_unit(
    .clk(clk),
    .reset(reset),
    .init_address(init_address),
    .init_is_error_syndrome(init_is_error_syndrome),
    .init_has_boundary(init_has_boundary),
    .init_boundary_cost(init_boundary_cost),
    .stage_in(stage),
    .compare_solver_default_addr(compare_solver_default_addr),
    .compare_solver_addrs(compare_solver_addrs),
    .compare_solver_addrs_valid(compare_solver_addrs_valid),
    .compare_solver_result(compare_solver_result),
    .distance_solver_target(distance_solver_target),
    .distance_solver_result_idx(distance_solver_result_idx),
    .neighbor_is_fully_grown(neighbor_is_fully_grown),
    .neighbor_old_roots(neighbor_old_roots),
    .neighbor_increase(neighbor_increase),
    .union_out_channels_data(union_out_channels_data),
    .union_out_channels_valid(union_out_channels_valid),
    .union_in_channels_data(union_in_channels_data),
    .union_in_channels_valid(union_in_channels_valid),
    .direct_out_channels_data_single(direct_out_channels_data_single),
    .direct_out_channels_valid(direct_out_channels_valid),
    .direct_out_channels_is_full(direct_out_channels_is_full),
    .direct_in_channels_data(direct_in_channels_data),
    .direct_in_channels_valid(direct_in_channels_valid),
    .direct_in_channels_is_taken(direct_in_channels_is_taken),
    .old_root(old_root),
    .updated_root(updated_root),
    .is_error_syndrome(is_error_syndrome),
    .boundary_increased(boundary_increased),
    .is_odd_cluster(is_odd_cluster),
    .is_touching_boundary(is_touching_boundary),
    .is_odd_cardinality(is_odd_cardinality),
    .pending_tell_new_root_cardinality(pending_tell_new_root_cardinality),
    .pending_tell_new_root_touching_boundary(pending_tell_new_root_touching_boundary)
);

endmodule
