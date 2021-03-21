`timescale 1ns / 1ps

module processing_unit #(
    parameter ADDRESS_WIDTH = 8,  // width of address, e.g. single measurement standard surface code under d <= 15 could be 4bit * 2 = 8bit
    parameter DISTANCE_WIDTH = 6,  // the maximum distance between two nodes should fit into DISTANCE_WIDTH bits
    parameter BOUNDARY_WIDTH = 2,  // usually boundary cost would be 2, so by default 2 bits for boundary cost
    parameter NEIGHBOR_COUNT = 4,  // the direct neighbor of a stabilizer, usually between 2 and 4 for surface code
    parameter FAST_CHANNEL_COUNT = 0  // CHANNEL_COUNT = NEIGHBOR_COUNT + FAST_CHANNEL_COUNT
) (
    clk,
    reset,
    // initialize information, which is read on reset
    init_address,
    init_is_error_syndrome,
    init_has_boundary,
    init_boundary_cost,
    // stage indicator
    stage,
    // external compare solver
    compare_solver_default_addr,
    compare_solver_addrs,
    compare_solver_addrs_valid,
    compare_solver_result,
    // external distance solver
    distance_solver_target,
    distance_solver_result_idx,
    // neighbor links
    neighbor_is_fully_grown,
    old_root,  // connect to *_old_root_in
    neighbor_old_root,  // connect to *_old_root_out
    neighbor_increase,  // connect to *_increase
    // union channels using `nonblocking_channel`
    union_out_channels_data,
    union_out_channels_valid,
    union_in_channels_data,
    union_in_channels_valid,
    // direct channels using `blocking_channel`
    direct_out_channels_data,
    direct_out_channels_valid,
    direct_out_channels_is_full,
    direct_in_channels_data,
    direct_in_channels_valid,
    direct_in_channels_is_taken
);

`include "parameters.sv"

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
// compare solvers should be a combinational logic that takes multiple addresses and output the smallest one
output [ADDRESS_WIDTH-1:0] compare_solver_default_addr;
output [(ADDRESS_WIDTH * CHANNEL_COUNT)-1:0] compare_solver_addrs;
output [CHANNEL_COUNT-1:0] compare_solver_addrs_valid;
input [ADDRESS_WIDTH-1:0] compare_solver_result;
// distance solvers should take a target and multiple points and output the nearest point to the target, the multiple points are fixed and could be optimized
output [ADDRESS_WIDTH-1:0] distance_solver_target;
input [CHANNEL_WIDTH-1:0] distance_solver_result_idx;
// neighbor links using `neighbor_link` module
input [NEIGHBOR_COUNT-1:0] neighbor_is_fully_grown;
output [ADDRESS_WIDTH-1:0] old_root;  // connect to *_old_root_in, shared by all neighbors
input [(ADDRESS_WIDTH * NEIGHBOR_COUNT)-1:0] neighbor_old_root;  // connect to *_old_root_out
output neighbor_increase;  // connect to *_increase, shared by all neighbors
// union channels using `nonblocking_channel`, each message is packed [old_root, updated_root]
output [(UNION_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] union_out_channels_data;
output [CHANNEL_COUNT-1:0] union_out_channels_valid;
input [(UNION_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] union_in_channels_data;
input [CHANNEL_COUNT-1:0] union_in_channels_valid;
// direct channels using `blocking_channel`, each message is packed [receiver, is_odd_cardinality_root, is_touching_boundary]
output [(DIRECT_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] direct_out_channels_data;
output [CHANNEL_COUNT-1:0] direct_out_channels_valid;
input [CHANNEL_COUNT-1:0] direct_out_channels_is_full;
input [(DIRECT_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] direct_in_channels_data;
input [CHANNEL_COUNT-1:0] direct_in_channels_valid;
output [CHANNEL_COUNT-1:0] direct_in_channels_is_taken;

// internal states
reg [ADDRESS_WIDTH-1:0] address;  // my address
reg [ADDRESS_WIDTH-1:0] old_root;
reg [ADDRESS_WIDTH-1:0] updated_root;
reg [STAGE_WIDTH-1:0] last_stage;
reg is_error_syndrome;
reg has_boundary;
reg [BOUNDARY_WIDTH-1:0] boundary_cost;
reg is_odd_cluster;
reg is_touching_boundary;
reg is_odd_cardinality;
reg pending_tell_new_root_cardinality;
reg pending_tell_new_root_touching_boundary;

// create separate local wires for packed arrays, because Vivado doesn't seem to support things like input  logic [0:15] [127:0] mux_in,
// i defined in range [0, CHANNEL_COUNT)
`define compare_solver_addr(i) compare_solver_addrs[((i+1) * ADDRESS_WIDTH) - 1 : (i * ADDRESS_WIDTH)]
`define compare_solver_valid(i) compare_solver_addrs_valid[i]
`define union_out_data(i) union_out_channels_data[((i+1) * UNION_MESSAGE_WIDTH) - 1 : (i * UNION_MESSAGE_WIDTH)]
`define union_out_valid(i) union_out_channels_valid[i]
`define union_in_data(i) union_in_channels_data[((i+1) * UNION_MESSAGE_WIDTH) - 1 : (i * UNION_MESSAGE_WIDTH)]
`define union_in_valid(i) union_in_channels_valid[i]
`define direct_out_data(i) direct_out_channels_data[((i+1) * DIRECT_MESSAGE_WIDTH) - 1 : (i * DIRECT_MESSAGE_WIDTH)]
`define direct_out_valid(i) direct_out_channels_valid[i]
`define direct_out_is_full(i) direct_out_channels_is_full[i]
`define direct_in_data(i) direct_in_channels_data[((i+1) * DIRECT_MESSAGE_WIDTH) - 1 : (i * DIRECT_MESSAGE_WIDTH)]
`define direct_in_valid(i) direct_in_channels_valid[i]
`define direct_in_is_taken(i) direct_in_channels_is_taken[i]
// i defined in range [0, NEIGHBOR_COUNT)
`define is_fully_grown(i) neighbor_is_fully_grown[i]
`define old_root(i) neighbor_old_root[((i+1) * ADDRESS_WIDTH) - 1 : (i * ADDRESS_WIDTH)]

// compute `new_updated_root` based on messages and neighbors, used in `STAGE_SPREAD_CLUSTER` stage
wire [ADDRESS_WIDTH-1:0] new_updated_root;
assign compare_solver_default_addr = old_root;
genvar i;
generate
    for (i=0; i < CHANNEL_COUNT; i=i+1) begin: compare_new_updated_root
        wire [ADDRESS_WIDTH-1:0] elected_updated_root;
        wire elected_valid;
        if (i < NEIGHBOR_COUNT) begin  // first for neighbors
            // if has union message in the channel, use that one; otherwise use the old_root from neighbor link
            assign elected_valid = 1;  // always valid
            assign elected_updated_root = `union_in_valid(i) ? `union_in_data(i) : `old_root(i);
        end else begin  // then for non-neighbors (fast channels only)
            assign elected_valid = `union_in_valid(i);
            assign elected_updated_root = `union_in_data(i);
        end
        assign `compare_solver_addr(i) = elected_updated_root;
        assign `compare_solver_valid(i) = elected_valid;
    end
endgenerate
assign new_updated_root = compare_solver_result;  // combinational logic that computes within a sinlge clock cycle

// increase neighbor link
assign neighbor_increase = (stage == STAGE_GROW_BOUNDARY) && (last_stage != STAGE_GROW_BOUNDARY);

// state machine
always @(posedge clk) begin
    if (reset) begin
        address <= init_address;
        old_root <= init_address;
        updated_root <= init_address;
        last_stage <= STAGE_IDLE;
        is_error_syndrome <= init_is_error_syndrome;
        has_boundary <= init_has_boundary;
        boundary_cost <= init_boundary_cost;
        is_odd_cluster <= init_is_error_syndrome;
        is_touching_boundary <= 0;
        is_odd_cardinality <= init_is_error_syndrome;
        pending_tell_new_root_cardinality <= 0;
        pending_tell_new_root_touching_boundary <= 0;
    end else begin
        last_stage <= stage;  // record last stage
        if (stage == STAGE_IDLE) begin
            // PUs do nothing
        end else if (stage == STAGE_SPREAD_CLUSTER) begin
            
        end else if (stage == STAGE_GROW_BOUNDARY) begin
            // only gives a trigger to neighbor links
            // see `assign neighbor_increase = (stage == STAGE_GROW_BOUNDARY) && (last_stage != STAGE_GROW_BOUNDARY);`
        end else if (stage == STAGE_SYNC_IS_ODD_CLUSTER) begin
        
        end
    end
end

endmodule
