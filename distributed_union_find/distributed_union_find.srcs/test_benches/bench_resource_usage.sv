`timescale 1ns / 1ps

module bench_resource_usage #(
    CODE_DISTANCE = 3  // has CODE_DISTANCE ¡Á (CODE_DISTANCE-1) processing units
) (
    clk_in,
    reset,
    stage,
    is_error_syndromes,
    is_odd_clusters_xor
);

`include "../sources_1/new/parameters.sv"

localparam PU_COUNT = CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 2;
localparam DISTANCE_WIDTH = 1 + PER_DIMENSION_WIDTH;
localparam WEIGHT = 1;  // the weight in MWPM graph
localparam BOUNDARY_COST = 2 * WEIGHT;
localparam NEIGHBOR_COST = 2 * WEIGHT;
localparam BOUNDARY_WIDTH = $clog2(BOUNDARY_COST + 1);
localparam UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH;  // [old_root, updated_root]
localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]

input clk_in;
input reset;
input [STAGE_WIDTH-1:0] stage;
input [PU_COUNT-1:0] is_error_syndromes;
wire [PU_COUNT-1:0] is_odd_clusters;
output is_odd_clusters_xor;
assign is_odd_clusters_xor = ^is_odd_clusters;  // compress information to fit into limited ports

wire clk;
clk_wiz_0 u_clk_wiz_0(
    .reset(reset),
    .clk_in(clk_in),
    .clk_out(clk)
);

genvar i;
genvar j;

wire [PU_COUNT-1:0] test;

// generate macros
`define CHANNEL_COUNT_IJ(i, j) ((i>0?1:0) + (i<(CODE_DISTANCE-1)?1:0) + (j>0?1:0) + (j<(CODE_DISTANCE-2)?1:0))
`define CHANNEL_COUNT (`CHANNEL_COUNT_IJ(i, j))
`define CHANNEL_WIDTH ($clog2(`CHANNEL_COUNT))
`define NEIGHBOR_COUNT `CHANNEL_COUNT
localparam FAST_CHANNEL_COUNT = 0;
`define channel_addresses_i(idx) channel_addresses[(idx+1)*ADDRESS_WIDTH-1 : idx*ADDRESS_WIDTH+PER_DIMENSION_WIDTH]
`define channel_addresses_j(idx) channel_addresses[(idx+1)*ADDRESS_WIDTH-1-PER_DIMENSION_WIDTH : idx*ADDRESS_WIDTH]
`define init_is_error_syndrome(i, j) is_error_syndromes[i * (CODE_DISTANCE-1) + j]
`define init_has_boundary(i, j) ((j==0) || (j==(CODE_DISTANCE-2)))
`define is_odd_cluster(i, j) is_odd_clusters[i * (CODE_DISTANCE-1) + j]

// instantiate processing units and their local solver
generate
    for (i=0; i < CODE_DISTANCE; i=i+1) begin: pu_i
        for (j=0; j < CODE_DISTANCE-1; j=j+1) begin: pu_j
            // instant compare solver
            wire [ADDRESS_WIDTH-1:0] compare_solver_default_addr;
            wire [(ADDRESS_WIDTH * `CHANNEL_COUNT)-1:0] compare_solver_addrs;
            wire [`CHANNEL_COUNT-1:0] compare_solver_addrs_valid;
            wire [ADDRESS_WIDTH-1:0] compare_solver_result;
            tree_compare_solver #(
                .DATA_WIDTH(ADDRESS_WIDTH),
                .CHANNEL_COUNT(`CHANNEL_COUNT)
            ) u_tree_compare_solver(
                .default_value(compare_solver_default_addr),
                .values(compare_solver_addrs),
                .valids(compare_solver_addrs_valid),
                .result(compare_solver_result)
            );
            // instantiate distance 2d solver
            wire [ADDRESS_WIDTH-1:0] distance_solver_target;
            wire [`CHANNEL_WIDTH-1:0] distance_solver_result_idx;
            wire [(ADDRESS_WIDTH * `CHANNEL_COUNT)-1:0] channel_addresses;
            // address order: top, bottom, left, right
            if (i>0) begin
                if (i<(CODE_DISTANCE-1)) begin
                    if (j>0) begin
                        if (j<(CODE_DISTANCE-2)) begin
                            // middle part
                            // top
                            assign `channel_addresses_i(0) = i - 1;
                            assign `channel_addresses_j(0) = j;
                            // bottom
                            assign `channel_addresses_i(1) = i + 1;
                            assign `channel_addresses_j(1) = j;
                            // left
                            assign `channel_addresses_i(2) = i;
                            assign `channel_addresses_j(2) = j - 1;
                            // right
                            assign `channel_addresses_i(3) = i;
                            assign `channel_addresses_j(3) = j + 1;
                        end else begin  // if (j<(CODE_DISTANCE-2))
                            // right boundary
                            // top
                            assign `channel_addresses_i(0) = i - 1;
                            assign `channel_addresses_j(0) = j;
                            // bottom
                            assign `channel_addresses_i(1) = i + 1;
                            assign `channel_addresses_j(1) = j;
                            // left
                            assign `channel_addresses_i(2) = i;
                            assign `channel_addresses_j(2) = j - 1;
                        end  // if (j<(CODE_DISTANCE-2))
                    end else begin  // if (j>0)
                        // left boundary
                        // top
                        assign `channel_addresses_i(0) = i - 1;
                        assign `channel_addresses_j(0) = j;
                        // bottom
                        assign `channel_addresses_i(1) = i + 1;
                        assign `channel_addresses_j(1) = j;
                        // right
                        assign `channel_addresses_i(2) = i;
                        assign `channel_addresses_j(2) = j + 1;
                    end  // if (j>0)
                end else begin  // if (i<(CODE_DISTANCE-1))
                    if (j>0) begin
                        if (j<(CODE_DISTANCE-2)) begin
                            // bottom boundary
                            // top
                            assign `channel_addresses_i(0) = i - 1;
                            assign `channel_addresses_j(0) = j;
                            // left
                            assign `channel_addresses_i(1) = i;
                            assign `channel_addresses_j(1) = j - 1;
                            // right
                            assign `channel_addresses_i(2) = i;
                            assign `channel_addresses_j(2) = j + 1;
                        end else begin  // if (j<(CODE_DISTANCE-2))
                            // bottom right corner
                            // top
                            assign `channel_addresses_i(0) = i - 1;
                            assign `channel_addresses_j(0) = j;
                            // left
                            assign `channel_addresses_i(1) = i;
                            assign `channel_addresses_j(1) = j - 1;
                        end  // if (j<(CODE_DISTANCE-2))
                    end else begin  // if (j>0)
                        // bottom left corner
                        // top
                        assign `channel_addresses_i(0) = i - 1;
                        assign `channel_addresses_j(0) = j;
                        // right
                        assign `channel_addresses_i(1) = i;
                        assign `channel_addresses_j(1) = j + 1;
                    end  // if (j>0)
                end  // if (i<(CODE_DISTANCE-1))
            end else begin  // if (i>0)
                if (j>0) begin
                    if (j<(CODE_DISTANCE-2)) begin
                        // top boundary
                        // bottom
                        assign `channel_addresses_i(0) = i + 1;
                        assign `channel_addresses_j(0) = j;
                        // left
                        assign `channel_addresses_i(1) = i;
                        assign `channel_addresses_j(1) = j - 1;
                        // right
                        assign `channel_addresses_i(2) = i;
                        assign `channel_addresses_j(2) = j + 1;
                    end else begin  // if (j<(CODE_DISTANCE-2))
                        // top right corner
                        // bottom
                        assign `channel_addresses_i(0) = i + 1;
                        assign `channel_addresses_j(0) = j;
                        // left
                        assign `channel_addresses_i(1) = i;
                        assign `channel_addresses_j(1) = j - 1;
                    end  // if (j<(CODE_DISTANCE-2))
                end else begin  // if (j>0)
                    // top left corner
                    // bottom
                    assign `channel_addresses_i(0) = i + 1;
                    assign `channel_addresses_j(0) = j;
                    // right
                    assign `channel_addresses_i(1) = i;
                    assign `channel_addresses_j(1) = j + 1;
                end  // if (j>0)
            end  // if (i>0)
            tree_distance_2d_solver #(
                .PER_DIMENSION_WIDTH(PER_DIMENSION_WIDTH),
                .CHANNEL_COUNT(`CHANNEL_COUNT)
            ) u_tree_distance_2d_solver(
                .points(channel_addresses),
                .target(distance_solver_target),
                .result_idx(distance_solver_result_idx)
            );
            // instantiate processing unit
            wire [ADDRESS_WIDTH-1:0] init_address;
            assign init_address[ADDRESS_WIDTH-1:PER_DIMENSION_WIDTH] = i;
            assign init_address[PER_DIMENSION_WIDTH-1:0] = j;
            wire [`NEIGHBOR_COUNT-1:0] neighbor_is_fully_grown;
            wire [(ADDRESS_WIDTH * `NEIGHBOR_COUNT)-1:0] neighbor_old_roots;
            wire neighbor_increase;
            wire [(UNION_MESSAGE_WIDTH * `CHANNEL_COUNT)-1:0] union_out_channels_data;
            wire union_out_channels_valid;
            wire [(UNION_MESSAGE_WIDTH * `CHANNEL_COUNT)-1:0] union_in_channels_data;
            wire [`CHANNEL_COUNT-1:0] union_in_channels_valid;
            wire [DIRECT_MESSAGE_WIDTH-1:0] direct_out_channels_data_single;
            wire [`CHANNEL_COUNT-1:0] direct_out_channels_valid;
            wire [`CHANNEL_COUNT-1:0] direct_out_channels_is_full;
            wire [(DIRECT_MESSAGE_WIDTH * `CHANNEL_COUNT)-1:0] direct_in_channels_data;
            wire [`CHANNEL_COUNT-1:0] direct_in_channels_valid;
            wire [`CHANNEL_COUNT-1:0] direct_in_channels_is_taken;
            wire [ADDRESS_WIDTH-1:0] old_root;
            processing_unit #(
                .ADDRESS_WIDTH(ADDRESS_WIDTH),
                .DISTANCE_WIDTH(DISTANCE_WIDTH),
                .BOUNDARY_WIDTH(BOUNDARY_WIDTH),
                .NEIGHBOR_COUNT(`NEIGHBOR_COUNT),
                .FAST_CHANNEL_COUNT(FAST_CHANNEL_COUNT)
            ) u_processing_unit(
                .clk(clk),
                .reset(reset),
                .init_address(init_address),
                .init_is_error_syndrome(`init_is_error_syndrome(i, j)),
                .init_has_boundary(`init_has_boundary(i, j)),
                .init_boundary_cost(BOUNDARY_COST),
                .stage(stage),
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
//                .updated_root(updated_root),
//                .is_error_syndrome(is_error_syndrome),
//                .boundary_increased(boundary_increased),
                .is_odd_cluster(`is_odd_cluster(i, j))
//                .is_touching_boundary(is_touching_boundary),
//                .is_odd_cardinality(is_odd_cardinality),
//                .pending_tell_new_root_cardinality(pending_tell_new_root_cardinality),
//                .pending_tell_new_root_touching_boundary(pending_tell_new_root_touching_boundary)
            );
        end
    end
endgenerate

`define NEIGHBOR_IDX_TOP(i, j) (0)
`define NEIGHBOR_IDX_BOTTOM(i, j) (i>0?1:0)
`define NEIGHBOR_IDX_LEFT(i, j) ((i>0?1:0) + (i<(CODE_DISTANCE-1)?1:0))
`define NEIGHBOR_IDX_RIGHT(i, j) ((i>0?1:0) + (i<(CODE_DISTANCE-1)?1:0) + (j>0?1:0))
`define PU(i, j) pu_i[i].pu_j[j]
`define SLICE_ADDRESS_VEC(vec, idx) (vec[(((idx)+1)*ADDRESS_WIDTH)-1:(idx)*ADDRESS_WIDTH])
`define SLICE_UNION_MESSAGE_VEC(vec, idx) (vec[(((idx)+1)*UNION_MESSAGE_WIDTH)-1:(idx)*UNION_MESSAGE_WIDTH])
`define SLICE_DIRECT_MESSAGE_VEC(vec, idx) (vec[(((idx)+1)*DIRECT_MESSAGE_WIDTH)-1:(idx)*DIRECT_MESSAGE_WIDTH])

// instantiate vertical neighbor link and connect signals properly
`define NEIGHBOR_VERTICAL_INSTANTIATE \
neighbor_link #(.LENGTH(NEIGHBOR_COST), .ADDRESS_WIDTH(ADDRESS_WIDTH)) neighbor_vertical (\
    .clk(clk), .reset(reset), .is_fully_grown(`PU(i, j).neighbor_is_fully_grown[`NEIGHBOR_IDX_BOTTOM(i, j)]),\
    .a_old_root_in(`PU(i, j).old_root), .a_increase(`PU(i, j).neighbor_increase),\
    .b_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j).neighbor_old_roots, `NEIGHBOR_IDX_BOTTOM(i, j))),\
    .b_old_root_in(`PU(i+1, j).old_root), .b_increase(`PU(i+1, j).neighbor_increase),\
    .a_old_root_out(`SLICE_ADDRESS_VEC(`PU(i+1, j).neighbor_old_roots, `NEIGHBOR_IDX_TOP(i+1, j)))\
);\
assign `PU(i+1, j).neighbor_is_fully_grown[`NEIGHBOR_IDX_TOP(i+1, j)] = `PU(i, j).neighbor_is_fully_grown[`NEIGHBOR_IDX_BOTTOM(i, j)];

// instantiate horizontal neighbor link and connect signals properly
`define NEIGHBOR_HORIZONTAL_INSTANTIATE \
neighbor_link #(.LENGTH(NEIGHBOR_COST), .ADDRESS_WIDTH(ADDRESS_WIDTH)) neighbor_horizontal (\
    .clk(clk), .reset(reset), .is_fully_grown(`PU(i, j).neighbor_is_fully_grown[`NEIGHBOR_IDX_RIGHT(i, j)]),\
    .a_old_root_in(`PU(i, j).old_root), .a_increase(`PU(i, j).neighbor_increase),\
    .b_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j).neighbor_old_roots, `NEIGHBOR_IDX_RIGHT(i, j))),\
    .b_old_root_in(`PU(i, j+1).old_root), .b_increase(`PU(i, j+1).neighbor_increase),\
    .a_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j+1).neighbor_old_roots, `NEIGHBOR_IDX_LEFT(i, j+1)))\
);\
assign `PU(i, j+1).neighbor_is_fully_grown[`NEIGHBOR_IDX_LEFT(i, j+1)] = `PU(i, j).neighbor_is_fully_grown[`NEIGHBOR_IDX_RIGHT(i, j)];

// instantiate vertical union channels and connect signals properly
`define UNION_CHANNEL_VERTICAL_INSTANTIATE \
nonblocking_channel #(.WIDTH(UNION_MESSAGE_WIDTH)) nonblocking_channel_down (\
    .clk(clk), .reset(reset),\
    .in_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j).union_out_channels_data, `NEIGHBOR_IDX_BOTTOM(i, j))),\
    .in_valid(`PU(i, j).union_out_channels_valid),\
    .out_data(`SLICE_UNION_MESSAGE_VEC(`PU(i+1, j).union_in_channels_data, `NEIGHBOR_IDX_TOP(i+1, j))),\
    .out_valid(`PU(i+1, j).union_in_channels_valid[`NEIGHBOR_IDX_TOP(i+1, j)])\
);\
nonblocking_channel #(.WIDTH(UNION_MESSAGE_WIDTH)) nonblocking_channel_up (\
    .clk(clk), .reset(reset),\
    .in_data(`SLICE_UNION_MESSAGE_VEC(`PU(i+1, j).union_out_channels_data, `NEIGHBOR_IDX_TOP(i+1, j))),\
    .in_valid(`PU(i+1, j).union_out_channels_valid),\
    .out_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j).union_in_channels_data, `NEIGHBOR_IDX_BOTTOM(i, j))),\
    .out_valid(`PU(i, j).union_in_channels_valid[`NEIGHBOR_IDX_BOTTOM(i, j)])\
);

// instantiate horizontal union channels and connect signals properly
`define UNION_CHANNEL_HORIZONTAL_INSTANTIATE \
nonblocking_channel #(.WIDTH(UNION_MESSAGE_WIDTH)) nonblocking_channel_right (\
    .clk(clk), .reset(reset),\
    .in_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j).union_out_channels_data, `NEIGHBOR_IDX_RIGHT(i, j))),\
    .in_valid(`PU(i, j).union_out_channels_valid),\
    .out_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j+1).union_in_channels_data, `NEIGHBOR_IDX_LEFT(i, j+1))),\
    .out_valid(`PU(i, j+1).union_in_channels_valid[`NEIGHBOR_IDX_LEFT(i, j+1)])\
);\
nonblocking_channel #(.WIDTH(UNION_MESSAGE_WIDTH)) nonblocking_channel_left (\
    .clk(clk), .reset(reset),\
    .in_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j+1).union_out_channels_data, `NEIGHBOR_IDX_LEFT(i, j+1))),\
    .in_valid(`PU(i, j+1).union_out_channels_valid),\
    .out_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j).union_in_channels_data, `NEIGHBOR_IDX_RIGHT(i, j))),\
    .out_valid(`PU(i, j).union_in_channels_valid[`NEIGHBOR_IDX_RIGHT(i, j)])\
);

// instantiate vertical direct channels and connect signals properly
`define DIRECT_CHANNEL_VERTICAL_INSTANTIATE \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH)) blocking_channel_down (\
    .clk(clk), .reset(reset),\
    .in_data(`PU(i, j).direct_out_channels_data_single),\
    .in_valid(`PU(i, j).direct_out_channels_valid[`NEIGHBOR_IDX_BOTTOM(i, j)]),\
    .in_is_full(`PU(i, j).direct_out_channels_is_full[`NEIGHBOR_IDX_BOTTOM(i, j)]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i+1, j).direct_in_channels_data, `NEIGHBOR_IDX_TOP(i+1, j))),\
    .out_valid(`PU(i+1, j).direct_in_channels_valid[`NEIGHBOR_IDX_TOP(i+1, j)]),\
    .out_is_taken(`PU(i+1, j).direct_in_channels_is_taken[`NEIGHBOR_IDX_TOP(i+1, j)])\
);\
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH)) blocking_channel_up (\
    .clk(clk), .reset(reset),\
    .in_data(`PU(i+1, j).direct_out_channels_data_single),\
    .in_valid(`PU(i+1, j).direct_out_channels_valid[`NEIGHBOR_IDX_TOP(i+1, j)]),\
    .in_is_full(`PU(i+1, j).direct_out_channels_is_full[`NEIGHBOR_IDX_TOP(i+1, j)]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j).direct_in_channels_data, `NEIGHBOR_IDX_BOTTOM(i, j))),\
    .out_valid(`PU(i, j).direct_in_channels_valid[`NEIGHBOR_IDX_BOTTOM(i, j)]),\
    .out_is_taken(`PU(i, j).direct_in_channels_is_taken[`NEIGHBOR_IDX_BOTTOM(i, j)])\
);

// instantiate horizontal direct channels and connect signals properly
`define DIRECT_CHANNEL_HORIZONTAL_INSTANTIATE \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH)) blocking_channel_right (\
    .clk(clk), .reset(reset),\
    .in_data(`PU(i, j).direct_out_channels_data_single),\
    .in_valid(`PU(i, j).direct_out_channels_valid[`NEIGHBOR_IDX_RIGHT(i, j)]),\
    .in_is_full(`PU(i, j).direct_out_channels_is_full[`NEIGHBOR_IDX_RIGHT(i, j)]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j+1).direct_in_channels_data, `NEIGHBOR_IDX_LEFT(i, j+1))),\
    .out_valid(`PU(i, j+1).direct_in_channels_valid[`NEIGHBOR_IDX_LEFT(i, j+1)]),\
    .out_is_taken(`PU(i, j+1).direct_in_channels_is_taken[`NEIGHBOR_IDX_LEFT(i, j+1)])\
);\
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH)) blocking_channel_left (\
    .clk(clk), .reset(reset),\
    .in_data(`PU(i, j+1).direct_out_channels_data_single),\
    .in_valid(`PU(i, j+1).direct_out_channels_valid[`NEIGHBOR_IDX_LEFT(i, j+1)]),\
    .in_is_full(`PU(i, j+1).direct_out_channels_is_full[`NEIGHBOR_IDX_LEFT(i, j+1)]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j).direct_in_channels_data, `NEIGHBOR_IDX_RIGHT(i, j))),\
    .out_valid(`PU(i, j).direct_in_channels_valid[`NEIGHBOR_IDX_RIGHT(i, j)]),\
    .out_is_taken(`PU(i, j).direct_in_channels_is_taken[`NEIGHBOR_IDX_RIGHT(i, j)])\
);

// instantiate vertical and horizontal links and channels
`define VERTICAL_INSTANTIATE \
`NEIGHBOR_VERTICAL_INSTANTIATE \
`UNION_CHANNEL_VERTICAL_INSTANTIATE \
`DIRECT_CHANNEL_VERTICAL_INSTANTIATE

`define HORIZONTAL_INSTANTIATE \
`NEIGHBOR_HORIZONTAL_INSTANTIATE \
`UNION_CHANNEL_HORIZONTAL_INSTANTIATE \
`DIRECT_CHANNEL_HORIZONTAL_INSTANTIATE

// instantiate neighbor links and channels
generate
    for (i=0; i < CODE_DISTANCE; i=i+1) begin: neighbor_i
        for (j=0; j < CODE_DISTANCE-1; j=j+1) begin: neighbor_j
            //@ [`NEIGHBOR_COUNT-1:0] neighbor_is_fully_grown;
            //@ [(ADDRESS_WIDTH * `NEIGHBOR_COUNT)-1:0] neighbor_old_roots;
            //@ neighbor_increase;
            //@ [(UNION_MESSAGE_WIDTH * `CHANNEL_COUNT)-1:0] union_out_channels_data;
            //@ union_out_channels_valid;
            //@ [(UNION_MESSAGE_WIDTH * `CHANNEL_COUNT)-1:0] union_in_channels_data;
            //@ [`CHANNEL_COUNT-1:0] union_in_channels_valid;
            //@ [DIRECT_MESSAGE_WIDTH-1:0] direct_out_channels_data_single;
            //@ [`CHANNEL_COUNT-1:0] direct_out_channels_valid;
            //@ [`CHANNEL_COUNT-1:0] direct_out_channels_is_full;
            //@ [(DIRECT_MESSAGE_WIDTH * `CHANNEL_COUNT)-1:0] direct_in_channels_data;
            //@ [`CHANNEL_COUNT-1:0] direct_in_channels_valid;
            //@ [`CHANNEL_COUNT-1:0] direct_in_channels_is_taken;
            //@ [ADDRESS_WIDTH-1:0] old_root;
            // address order: top, bottom, left, right
            if (i>0) begin
                if (i<(CODE_DISTANCE-1)) begin
                    if (j>0) begin
                        if (j<(CODE_DISTANCE-2)) begin
                            // middle part
                            // bottom
                            `VERTICAL_INSTANTIATE
                            // right
                           `HORIZONTAL_INSTANTIATE
                        end else begin  // if (j<(CODE_DISTANCE-2))
                            // right boundary
                            // bottom
                            `VERTICAL_INSTANTIATE
                        end  // if (j<(CODE_DISTANCE-2))
                    end else begin  // if (j>0)
                        // left boundary
                        // bottom
                        `VERTICAL_INSTANTIATE
                        // right
                        `HORIZONTAL_INSTANTIATE
                    end  // if (j>0)
                end else begin  // if (i<(CODE_DISTANCE-1))
                    if (j>0) begin
                        if (j<(CODE_DISTANCE-2)) begin
                            // bottom boundary
                            // right
                            `HORIZONTAL_INSTANTIATE
                        end else begin  // if (j<(CODE_DISTANCE-2))
                            // bottom right corner
                        end  // if (j<(CODE_DISTANCE-2))
                    end else begin  // if (j>0)
                        // bottom left corner
                        // right
                        `HORIZONTAL_INSTANTIATE
                    end  // if (j>0)
                end  // if (i<(CODE_DISTANCE-1))
            end else begin  // if (i>0)
                if (j>0) begin
                    if (j<(CODE_DISTANCE-2)) begin
                        // top boundary
                        // bottom
                        `VERTICAL_INSTANTIATE
                        // right
                        `HORIZONTAL_INSTANTIATE
                    end else begin  // if (j<(CODE_DISTANCE-2))
                        // top right corner
                        // bottom
                        `VERTICAL_INSTANTIATE
                    end  // if (j<(CODE_DISTANCE-2))
                end else begin  // if (j>0)
                    // top left corner
                    // bottom
                    `VERTICAL_INSTANTIATE
                    // right
                    `HORIZONTAL_INSTANTIATE
                end  // if (j>0)
            end  // if (i>0)
        end
    end
endgenerate

endmodule
