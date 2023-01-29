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




module min_val_with_index #(
    parameter DATA_WIDTH = 8,  // width of data to be compared
    parameter CHANNEL_COUNT = 8  // number of channels to be compared
) (
  input [DATA_WIDTH-1:0] val1, 
  input [DATA_WIDTH-1:0] val2,
  input [CHANNEL_COUNT - 1 :0] valid1, 
  input [CHANNEL_COUNT - 1 :0] valid2,
  output reg [2*CHANNEL_COUNT - 1 :0] valid,
  output reg [DATA_WIDTH-1:0] min_val
);

  always@(*) begin
    if ((|valid1) && (|valid2)) begin
      if (val1 < val2) begin
        min_val = val1;
        valid[CHANNEL_COUNT-1:0] = valid1[CHANNEL_COUNT-1:0];
        valid[2*CHANNEL_COUNT-1:CHANNEL_COUNT] = {(CHANNEL_COUNT){1'b0}};
      end else begin
        min_val = val2;
        valid[CHANNEL_COUNT-1:0] = {(CHANNEL_COUNT){1'b0}};
        valid[2*CHANNEL_COUNT-1:CHANNEL_COUNT] = valid2[CHANNEL_COUNT-1:0];
      end
    end
    else if (|valid1) begin
      min_val = val1;
      valid[CHANNEL_COUNT-1:0] = valid1[CHANNEL_COUNT-1:0];
      valid[2*CHANNEL_COUNT-1:CHANNEL_COUNT] = {(CHANNEL_COUNT){1'b0}};
    end else if (|valid2) begin
      min_val = val2;
      valid[CHANNEL_COUNT-1:0] = {(CHANNEL_COUNT){1'b0}};
      valid[2*CHANNEL_COUNT-1:CHANNEL_COUNT] = valid2[CHANNEL_COUNT-1:0];
    end else begin
      min_val = val2;
      valid[CHANNEL_COUNT-1:0] = {(CHANNEL_COUNT){1'b0}};
      valid[2*CHANNEL_COUNT-1:CHANNEL_COUNT] = {(CHANNEL_COUNT){1'b0}};
    end
  end
endmodule

module min_val_4x_with_index #(
    parameter DATA_WIDTH = 8,  // width of data to be compared
    parameter CHANNEL_COUNT = 8  // number of channels to be compared
) (
    input [4*DATA_WIDTH-1:0] val, 
    input [4*CHANNEL_COUNT - 1 :0] valid,
    output [DATA_WIDTH-1:0] min_val,
    output [4*CHANNEL_COUNT - 1 :0] min_valid
);

    wire [2*DATA_WIDTH-1:0] min_val_1;
    wire [4*CHANNEL_COUNT - 1 :0] min_valid_1;

    min_val_with_index #(
        .DATA_WIDTH(DATA_WIDTH),
        .CHANNEL_COUNT(CHANNEL_COUNT)
    ) min_val_with_index_1 (
        .val1(val[0*DATA_WIDTH+DATA_WIDTH-1:0*DATA_WIDTH]),
        .val2(val[1*DATA_WIDTH+DATA_WIDTH-1:1*DATA_WIDTH]),
        .valid1(valid[0*CHANNEL_COUNT+CHANNEL_COUNT-1:0*CHANNEL_COUNT]),
        .valid2(valid[1*CHANNEL_COUNT+CHANNEL_COUNT-1:1*CHANNEL_COUNT]),
        .valid(min_valid_1[0*CHANNEL_COUNT+2*CHANNEL_COUNT-1:0*CHANNEL_COUNT]),
        .min_val(min_val_1[0*DATA_WIDTH+DATA_WIDTH-1:0*DATA_WIDTH])
    );
    
    min_val_with_index #(
        .DATA_WIDTH(DATA_WIDTH),
        .CHANNEL_COUNT(CHANNEL_COUNT)
    ) min_val_with_index_2 (
        .val1(val[2*DATA_WIDTH+DATA_WIDTH-1:2*DATA_WIDTH]),
        .val2(val[3*DATA_WIDTH+DATA_WIDTH-1:3*DATA_WIDTH]),
        .valid1(valid[2*CHANNEL_COUNT+CHANNEL_COUNT-1:2*CHANNEL_COUNT]),
        .valid2(valid[3*CHANNEL_COUNT+CHANNEL_COUNT-1:3*CHANNEL_COUNT]),
        .valid(min_valid_1[2*CHANNEL_COUNT+2*CHANNEL_COUNT-1:2*CHANNEL_COUNT]),
        .min_val(min_val_1[1*DATA_WIDTH+DATA_WIDTH-1:1*DATA_WIDTH])
    );
    
    min_val_with_index #(
        .DATA_WIDTH(DATA_WIDTH),
        .CHANNEL_COUNT(2*CHANNEL_COUNT)
    ) min_val_with_index_3 (
        .val1(min_val_1[0*DATA_WIDTH+DATA_WIDTH-1:0*DATA_WIDTH]),
        .val2(min_val_1[1*DATA_WIDTH+DATA_WIDTH-1:1*DATA_WIDTH]),
        .valid1(min_valid_1[0*CHANNEL_COUNT+2*CHANNEL_COUNT-1:0*CHANNEL_COUNT]),
        .valid2(min_valid_1[2*CHANNEL_COUNT+2*CHANNEL_COUNT-1:2*CHANNEL_COUNT]),
        .valid(min_valid),
        .min_val(min_val)
    );

endmodule

module min_val_8x_with_index #(
    parameter DATA_WIDTH = 8,  // width of data to be compared
    parameter CHANNEL_COUNT = 8  // number of channels to be compared
) (
    input [8*DATA_WIDTH-1:0] val, 
    input [8*CHANNEL_COUNT - 1 :0] valid,
    output [DATA_WIDTH-1:0] min_val,
    output [8*CHANNEL_COUNT - 1 :0] min_valid
);

    wire [2*DATA_WIDTH-1:0] min_val_1;
    wire [4*CHANNEL_COUNT - 1 :0] min_valid_1;

    min_val_4x_with_index #(
        .DATA_WIDTH(DATA_WIDTH),
        .CHANNEL_COUNT(CHANNEL_COUNT)
    ) min_val_4x_with_index_1 (
        .val(val[0*4*DATA_WIDTH+4*DATA_WIDTH-1:0*4*DATA_WIDTH]),
        .valid(valid[0*4*CHANNEL_COUNT+4*CHANNEL_COUNT-1:0*4*CHANNEL_COUNT]),
        .min_val(min_val_1[0*DATA_WIDTH+DATA_WIDTH-1:0*DATA_WIDTH]),
        .min_valid(min_valid_1[0*4*CHANNEL_COUNT+4*CHANNEL_COUNT-1:0*4*CHANNEL_COUNT])
    );

    min_val_4x_with_index #(
        .DATA_WIDTH(DATA_WIDTH),
        .CHANNEL_COUNT(CHANNEL_COUNT)
    ) min_val_4x_with_index_2 (
        .val(val[1*4*DATA_WIDTH+4*DATA_WIDTH-1:1*4*DATA_WIDTH]),
        .valid(valid[1*4*CHANNEL_COUNT+4*CHANNEL_COUNT-1:1*4*CHANNEL_COUNT]),
        .min_val(min_val_1[1*DATA_WIDTH+DATA_WIDTH-1:1*DATA_WIDTH]),
        .min_valid(min_valid_1[1*4*CHANNEL_COUNT+4*CHANNEL_COUNT-1:1*4*CHANNEL_COUNT])
    );

    min_val_with_index #(
        .DATA_WIDTH(DATA_WIDTH),
        .CHANNEL_COUNT(4*CHANNEL_COUNT)
    ) min_val_with_index_3 (
        .val1(min_val_1[0*DATA_WIDTH+DATA_WIDTH-1:0*DATA_WIDTH]),
        .val2(min_val_1[1*DATA_WIDTH+DATA_WIDTH-1:1*DATA_WIDTH]),
        .valid1(min_valid_1[0*CHANNEL_COUNT+4*CHANNEL_COUNT-1:0*CHANNEL_COUNT]),
        .valid2(min_valid_1[4*CHANNEL_COUNT+4*CHANNEL_COUNT-1:4*CHANNEL_COUNT]),
        .valid(min_valid),
        .min_val(min_val)
    );

endmodule

module min_val_less_8x_with_index #(
    parameter DATA_WIDTH = 8,  // width of data to be compared
    parameter CHANNEL_COUNT = 6  // number of channels to be compared
) (
    input wire [(DATA_WIDTH * CHANNEL_COUNT)-1:0] values,
    input wire [CHANNEL_COUNT-1:0] valids,
    output wire [DATA_WIDTH-1:0] result,
    output wire [CHANNEL_COUNT-1:0] output_valids
);

parameter ALL_EXPAND_COUNT = 8;

wire [ALL_EXPAND_COUNT-1:0] expanded_valids;
wire [(DATA_WIDTH * ALL_EXPAND_COUNT)-1:0] expanded_values;
`define expanded_value(i) expanded_values[((i+1) * DATA_WIDTH) - 1 : (i * DATA_WIDTH)]
`define original_value(i) values[((i+1) * DATA_WIDTH) - 1 : (i * DATA_WIDTH)]

wire [ALL_EXPAND_COUNT-1:0] output_expanded_valids;

generate
genvar i;
// connect input valid to expended valids
for (i=0; i < ALL_EXPAND_COUNT; i=i+1) begin: initialization
    if (i < CHANNEL_COUNT) begin
        assign `expanded_value(i) = `original_value(i);
        assign expanded_valids[i] = valids[i];
        assign output_valids[i] = output_expanded_valids[i];
    end else begin
        assign expanded_valids[i] = 0;  // not valid
    end
end

endgenerate


min_val_8x_with_index #(
    .DATA_WIDTH(DATA_WIDTH),
    .CHANNEL_COUNT(1)
) min_val_8x_with_index_1 (
    .val(expanded_values),
    .valid(expanded_valids),
    .min_val(result),
    .min_valid(output_expanded_valids)
);


endmodule

    

