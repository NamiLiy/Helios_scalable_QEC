`timescale 1ns / 1ps

// compare solver with tree structure combinational logic
// it will return the smallest number among `CHANNEL_COUNT` and the default value
// the longest path is O(log(CHANNEL_COUNT)), to fit into a single clock cycle as much as possible

module tree_compare_solver #(
    parameter DATA_WIDTH = 8,  // width of data to be compared
    parameter CHANNEL_COUNT = 6  // number of channels to be compared
) (
    input wire [DATA_WIDTH-1:0] default_value,
    input wire [(DATA_WIDTH * CHANNEL_COUNT)-1:0] values,
    input wire [CHANNEL_COUNT-1:0] valids,
    output wire [DATA_WIDTH-1:0] result
);

localparam DEPTH = $clog2(CHANNEL_COUNT);
localparam EXPAND_COUNT = 2 ** DEPTH;
localparam ALL_EXPAND_COUNT = 2 * EXPAND_COUNT - 1;  // 8 + 4 + 2 + 1 = 2 * 8 - 1

wire [ALL_EXPAND_COUNT-1:0] expanded_valids;
wire [(DATA_WIDTH * ALL_EXPAND_COUNT)-1:0] expanded_values;
`define expanded_value(i) expanded_values[((i+1) * DATA_WIDTH) - 1 : (i * DATA_WIDTH)]
`define original_value(i) values[((i+1) * DATA_WIDTH) - 1 : (i * DATA_WIDTH)]

generate
genvar i;
// connect input valid to expended valids
for (i=0; i < EXPAND_COUNT; i=i+1) begin: initialization
    if (i < CHANNEL_COUNT) begin
        assign `expanded_value(i) = `original_value(i);
        assign expanded_valids[i] = valids[i];
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
        assign expanded_valids[`CURRENT_IDX] = expanded_valids[`CHILD_1_IDX] || expanded_valids[`CHILD_2_IDX];
        assign `expanded_value(`CURRENT_IDX) = expanded_valids[`CHILD_1_IDX] ? 
            (expanded_valids[`CHILD_2_IDX] ? (
                `expanded_value(`CHILD_1_IDX) < `expanded_value(`CHILD_2_IDX) ? `expanded_value(`CHILD_1_IDX) : `expanded_value(`CHILD_2_IDX)
            ) : (`expanded_value(`CHILD_1_IDX))):
            (expanded_valids[`CHILD_2_IDX] ? (`expanded_value(`CHILD_2_IDX)) : (0));
    end
end
endgenerate

localparam ROOT_IDX = ALL_EXPAND_COUNT - 1;
assign result = expanded_valids[ROOT_IDX] ? (
    `expanded_value(ROOT_IDX) < default_value ? `expanded_value(ROOT_IDX) : default_value
) : (default_value);

endmodule
