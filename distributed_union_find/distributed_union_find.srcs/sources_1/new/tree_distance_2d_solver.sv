`timescale 1ns / 1ps

// distance solver with high dimensional vector
// given CHANNEL_COUNT points and a target, solve the index of the nearest point to target

module tree_distance_3d_solver #(
    parameter PER_DIMENSION_WIDTH = 4,  // width of each coordinate
    parameter CHANNEL_COUNT = 6  // number of channels to be compared
) (
    points,
    target,
    result_idx
);

localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam CHANNEL_WIDTH = $clog2(CHANNEL_COUNT);  // the index of channel, both neighbor and direct ones
localparam DISTANCE_WIDTH = 2 + PER_DIMENSION_WIDTH;  // the maximum width should fit into this width

localparam DEPTH = $clog2(CHANNEL_COUNT);
localparam EXPAND_COUNT = 2 ** DEPTH;
localparam ALL_EXPAND_COUNT = 2 * EXPAND_COUNT - 1;  // 8 + 4 + 2 + 1 = 2 * 8 - 1

input [(ADDRESS_WIDTH * CHANNEL_COUNT)-1:0] points;
input [ADDRESS_WIDTH-1:0] target;
output [CHANNEL_WIDTH-1:0] result_idx;

wire [ALL_EXPAND_COUNT:0] expanded_valids;
wire [(CHANNEL_WIDTH * ALL_EXPAND_COUNT)-1:0] expanded_indices;
wire [(DISTANCE_WIDTH * ALL_EXPAND_COUNT)-1:0] expanded_distances;
`define index(i) expanded_indices[((i+1) * CHANNEL_WIDTH) - 1 : (i * CHANNEL_WIDTH)]
`define distance(i) expanded_distances[((i+1) * DISTANCE_WIDTH) - 1 : (i * DISTANCE_WIDTH)]
`define point(i) points[((i+1) * ADDRESS_WIDTH) - 1 : (i * ADDRESS_WIDTH)]
`define point_z(i) points[((i+1) * ADDRESS_WIDTH) - 1 : (i * ADDRESS_WIDTH) + 2*PER_DIMENSION_WIDTH]
`define point_x(i) points[((i+1) * ADDRESS_WIDTH) - 1 - PER_DIMENSION_WIDTH : (i * ADDRESS_WIDTH) + PER_DIMENSION_WIDTH]
`define point_y(i) points[((i+1) * ADDRESS_WIDTH) - 1 - 2*PER_DIMENSION_WIDTH : (i * ADDRESS_WIDTH)]
`define target_z target[ADDRESS_WIDTH - 1 : PER_DIMENSION_WIDTH*2]
`define target_x target[PER_DIMENSION_WIDTH*2 - 1 : PER_DIMENSION_WIDTH]
`define target_y target[PER_DIMENSION_WIDTH - 1 : 0]

generate
genvar i;
// connect input valid to expended valids
for (i=0; i < EXPAND_COUNT; i=i+1) begin: initialization
    if (i < CHANNEL_COUNT) begin
        assign expanded_valids[i] = 1;
        assign `index(i) = i;
        wire [DISTANCE_WIDTH-1:0] distance_x;
        assign distance_x = { 1'b0, ((`point_x(i) < `target_x) ? (`target_x - `point_x(i)) : (`point_x(i) - `target_x)) };
        wire [DISTANCE_WIDTH-1:0] distance_y;
        assign distance_y = { 1'b0, ((`point_y(i) < `target_y) ? (`target_y - `point_y(i)) : (`point_y(i) - `target_y)) };
        wire [DISTANCE_WIDTH-1:0] distance_z;
        assign distance_z = { 1'b0, ((`point_z(i) < `target_z) ? (`target_z - `point_z(i)) : (`point_z(i) - `target_z)) };
        assign `distance(i) = distance_x + distance_y + distance_z;
    end else begin
        assign expanded_valids[i] = 0;  // not valid
    end
end
// build the tree
`define LAYER_WIDTH (2 ** (DEPTH - 1 - i))
`define LAYERT_IDX (2 ** (DEPTH + 1) - 2 ** (DEPTH - i))
`define LAST_LAYERT_IDX (2 ** (DEPTH + 1) - 2 ** (DEPTH + 1 - i))
`define CURRENT_IDX (`LAYERT_IDX + j)
`define CHILD_1_IDX (`LAST_LAYERT_IDX + 2 * j)
`define CHILD_2_IDX (`CHILD_1_IDX + 1)
for (i=0; i < DEPTH; i=i+1) begin: election
    genvar j;
    for (j=0; j < `LAYER_WIDTH; j=j+1) begin: layer_election
        wire is_child_1_smaller;
        assign is_child_1_smaller = (`distance(`CHILD_1_IDX) < `distance(`CHILD_2_IDX));
        assign expanded_valids[`CURRENT_IDX] = expanded_valids[`CHILD_1_IDX] | expanded_valids[`CHILD_2_IDX];
        assign `distance(`CURRENT_IDX) = expanded_valids[`CHILD_1_IDX] ? (
            expanded_valids[`CHILD_2_IDX] ? (
                is_child_1_smaller ? `distance(`CHILD_1_IDX) : `distance(`CHILD_2_IDX)
            ) : (`distance(`CHILD_1_IDX))
        ) : (
            `distance(`CHILD_2_IDX)
        );
        assign `index(`CURRENT_IDX) = expanded_valids[`CHILD_1_IDX] ? (
            expanded_valids[`CHILD_2_IDX] ? (
                is_child_1_smaller ? `index(`CHILD_1_IDX) : `index(`CHILD_2_IDX)
            ) : (`index(`CHILD_1_IDX))
        ) : (
            `index(`CHILD_2_IDX)
        );
    end
end
endgenerate

localparam ROOT_IDX = ALL_EXPAND_COUNT - 1;
assign result_idx = `index(ROOT_IDX);

endmodule
