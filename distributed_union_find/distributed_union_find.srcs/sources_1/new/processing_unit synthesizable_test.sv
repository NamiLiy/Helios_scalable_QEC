`timescale 1ns / 1ps

module processing_unit_synthesizable_test #(
    parameter CODE_DISTANCE = 5,
    parameter I = 4,
    parameter J = 4,
    parameter NEIGHBOR_COUNT = 4,
    parameter FAST_CHANNEL_COUNT = 0,  // CHANNEL_COUNT = NEIGHBOR_COUNT + FAST_CHANNEL_COUNT
    parameter INIT_BOUNDARY_COST = 2 
) (
    clk,
    reset,
    // initialize information, which is read on reset
    init_is_error_syndrome,
    // stage indicator
    stage_in,
    // neighbor links
    neighbor_is_fully_grown,
        // `old_root` should connect to *_old_root_in
    neighbor_old_roots,  // connect to *_old_root_out
    neighbor_increase,  // connect to *_increase
    // union channels using `nonblocking_channel`
    union_out_channels_data,
    union_out_channels_valid,
    union_in_channels_data,
    union_in_channels_valid,
    // direct channels using `blocking_channel`
    direct_out_channels_data_single,
    direct_out_channels_valid,
    direct_out_channels_is_full,
    direct_in_channels_data,
    direct_in_channels_valid,
    direct_in_channels_is_taken,
    // internal states are also published
    old_root,
    updated_root,
    is_error_syndrome,
    boundary_increased,
    is_odd_cluster,
    is_touching_boundary,
    is_odd_cardinality,
    is_processing
);

`include "parameters.sv"

localparam PU_COUNT = CODE_DISTANCE * CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

localparam DISTANCE_WIDTH = 1 + PER_DIMENSION_WIDTH;
localparam WEIGHT = 1;  // the weight in MWPM graph
localparam BOUNDARY_COST = 2 * WEIGHT;
localparam NEIGHBOR_COST = 2 * WEIGHT;
localparam BOUNDARY_WIDTH = $clog2(BOUNDARY_COST + 1);
localparam CHANNEL_COUNT = NEIGHBOR_COUNT + FAST_CHANNEL_COUNT;
localparam CHANNEL_WIDTH = $clog2(CHANNEL_COUNT);  // the index of channel, both neighbor and direct ones
localparam UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH;  // [old_root, updated_root]
localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]

input clk;
input reset;
// initialization information, which is read on reset
input init_is_error_syndrome;
// stage indicator
input [STAGE_WIDTH-1:0] stage_in;
// neighbor links using `neighbor_link` module
input [NEIGHBOR_COUNT-1:0] neighbor_is_fully_grown;
input [(ADDRESS_WIDTH * NEIGHBOR_COUNT)-1:0] neighbor_old_roots;  // connect to *_old_root_out
output reg neighbor_increase;  // connect to *_increase, shared by all neighbors
// union channels using `nonblocking_channel`, each message is packed [old_root, updated_root]
output reg [(UNION_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] union_out_channels_data;
output reg union_out_channels_valid; // single wire connects to all union channels
input [(UNION_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] union_in_channels_data;
input [CHANNEL_COUNT-1:0] union_in_channels_valid;
// direct channels using `blocking_channel`, each message is packed [receiver, is_odd_cardinality_root, is_touching_boundary]
output reg [DIRECT_MESSAGE_WIDTH-1:0] direct_out_channels_data_single;
output reg [CHANNEL_COUNT-1:0] direct_out_channels_valid;
input [CHANNEL_COUNT-1:0] direct_out_channels_is_full;
input [(DIRECT_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] direct_in_channels_data;
input [CHANNEL_COUNT-1:0] direct_in_channels_valid;
output reg [CHANNEL_COUNT-1:0] direct_in_channels_is_taken;

// internal states

output reg [ADDRESS_WIDTH-1:0] old_root;
output reg [ADDRESS_WIDTH-1:0] updated_root;

output reg is_error_syndrome;

output reg [BOUNDARY_WIDTH-1:0] boundary_increased;
output reg is_odd_cluster;
output reg is_touching_boundary;
output reg is_odd_cardinality;
output reg is_processing;

reg init_is_error_syndrome_reg;
reg [STAGE_WIDTH-1:0] stage_in_reg;

reg [NEIGHBOR_COUNT-1:0] neighbor_is_fully_grown_reg;
reg [(ADDRESS_WIDTH * NEIGHBOR_COUNT)-1:0] neighbor_old_roots_reg;  // connect to *_old_root_out
wire neighbor_increase_reg;  // connect to *_increase, shared by all neighbors
// union channels using `nonblocking_channel`, each message is packed [old_root, updated_root]
wire [(UNION_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] union_out_channels_data_reg;
wire union_out_channels_valid_reg; // single wire connects to all union channels
reg [(UNION_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] union_in_channels_data_reg;
reg [CHANNEL_COUNT-1:0] union_in_channels_valid_reg;
// direct channels using `blocking_channel`, each message is packed [receiver, is_odd_cardinality_root, is_touching_boundary]
wire [DIRECT_MESSAGE_WIDTH-1:0] direct_out_channels_data_single_reg;
wire [CHANNEL_COUNT-1:0] direct_out_channels_valid_reg;
reg [CHANNEL_COUNT-1:0] direct_out_channels_is_full_reg;
reg [(DIRECT_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] direct_in_channels_data_reg;
reg [CHANNEL_COUNT-1:0] direct_in_channels_valid_reg;
wire [CHANNEL_COUNT-1:0] direct_in_channels_is_taken_reg;

// internal states
wire [ADDRESS_WIDTH-1:0] old_root_reg;
wire [ADDRESS_WIDTH-1:0] updated_root_reg;
wire is_error_syndrome_reg;
wire [BOUNDARY_WIDTH-1:0] boundary_increased_reg;
wire is_odd_cluster_reg;
wire is_touching_boundary_reg;
wire is_odd_cardinality_reg;
wire is_processing_reg;

always@(posedge clk) begin
    init_is_error_syndrome_reg <= init_is_error_syndrome;
    stage_in_reg <= stage_in;
    neighbor_is_fully_grown_reg <= neighbor_is_fully_grown;
    neighbor_old_roots_reg <= neighbor_old_roots;  // connect to *_old_root_out
    neighbor_increase <= neighbor_increase_reg;  // connect to *_increase, shared by all neighbors
    union_out_channels_data <= union_out_channels_data_reg;
    union_out_channels_valid <= union_out_channels_valid_reg; // single wire connects to all union channels
    union_in_channels_data_reg <= union_in_channels_data;
    union_in_channels_valid_reg <= union_in_channels_valid;
    direct_out_channels_data_single <= direct_out_channels_data_single_reg;
    direct_out_channels_valid <= direct_out_channels_valid_reg;
    direct_out_channels_is_full_reg <= direct_out_channels_is_full;
    direct_in_channels_data_reg <= direct_in_channels_data;
    direct_in_channels_valid_reg <= direct_in_channels_valid;
    direct_in_channels_is_taken <= direct_in_channels_is_taken_reg;
    old_root <= old_root_reg;
    updated_root <= updated_root_reg;
    is_error_syndrome  <= is_error_syndrome_reg;
    boundary_increased <= boundary_increased_reg;
    is_odd_cluster <= is_odd_cluster_reg;
    is_touching_boundary <= is_touching_boundary_reg;
    is_odd_cardinality <= is_odd_cardinality_reg;
    is_processing <= is_processing_reg;
end

processing_unit #(
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .DISTANCE_WIDTH(DISTANCE_WIDTH),
    .BOUNDARY_WIDTH(BOUNDARY_WIDTH),
    .NEIGHBOR_COUNT(NEIGHBOR_COUNT),
    .FAST_CHANNEL_COUNT(FAST_CHANNEL_COUNT),
    .I(I),
    .J(J),
    .CODE_DISTANCE(CODE_DISTANCE),
    .INIT_BOUNDARY_COST(INIT_BOUNDARY_COST)
) u_processing_unit (
    .clk(clk),
    .reset(reset),
    .init_is_error_syndrome(init_is_error_syndrome_reg),
    .stage_in(stage_in_reg),
    .neighbor_is_fully_grown(neighbor_is_fully_grown_reg),
    .neighbor_old_roots(neighbor_old_roots_reg),
    .neighbor_increase(neighbor_increase_reg),
    .union_out_channels_data(union_out_channels_data_reg),
    .union_out_channels_valid(union_out_channels_valid_reg),
    .union_in_channels_data(union_in_channels_data_reg),
    .union_in_channels_valid(union_in_channels_valid_reg),
    .direct_out_channels_data_single(direct_out_channels_data_single_reg),
    .direct_out_channels_valid(direct_out_channels_valid_reg),
    .direct_out_channels_is_full(direct_out_channels_is_full_reg),
    .direct_in_channels_data(direct_in_channels_data_reg),
    .direct_in_channels_valid(direct_in_channels_valid_reg),
    .direct_in_channels_is_taken(direct_in_channels_is_taken_reg),
    .old_root(old_root_reg),
    .updated_root(updated_root_reg),
    .is_odd_cluster(is_odd_cluster_reg),
    .is_odd_cardinality(is_odd_cardinality_reg),
    .is_processing(is_processing_reg)
);


endmodule
