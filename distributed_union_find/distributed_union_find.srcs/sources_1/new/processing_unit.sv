`timescale 1ns / 1ps

`include "parameters.sv"

module processing_unit #(
    parameter ADDRESS_WIDTH = 8,  // width of address, e.g. single measurement standard surface code under d <= 15 could be 4bit * 2 = 8bit
    parameter DISTANCE_WIDTH = 6,  // the maximum distance between two nodes should fit into DISTANCE_WIDTH bits
    parameter NEIGHBOR_COUNT = 4,  // the direct neighbor of a stabilizer, usually between 2 and 4 for surface code
    parameter FAST_CHANNEL_COUNT = 0  // CHANNEL_COUNT = NEIGHBOR_COUNT + FAST_CHANNEL_COUNT
) (
    clk,
    reset,
    // external compare solver
    compare_solver_addrs,
    compare_solver_result,
    // external distance solver
    distance_solver_target,
    distance_solver_result,
    // union channels using `nonblocking_channel`
    union_out_channel_data,
    union_out_channel_valid,
    union_in_channel_data,
    union_in_channel_valid,
    // direct channels using `blocking_channel`
    direct_out_channel_data,
    direct_out_channel_valid,
    direct_out_channel_is_full,
    direct_in_channel_data,
    direct_in_channel_valid,
    direct_in_channel_is_taken
);

localparam CHANNEL_COUNT = NEIGHBOR_COUNT + FAST_CHANNEL_COUNT;
localparam UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH;  // [old_root, new_root]
localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]

input clk;
input reset;
// compare solvers should be a combinational logic that takes multiple addresses and output the smallest one
output [(ADDRESS_WIDTH * (CHANNEL_COUNT + 1))-1:0] compare_solver_addrs;
input [ADDRESS_WIDTH-1:0] compare_solver_result;
// distance solvers should take a target and multiple points and output the nearest point to the target, the multiple points are fixed and could be optimized
output [ADDRESS_WIDTH-1:0] distance_solver_target;
input [ADDRESS_WIDTH-1:0] distance_solver_result;
// union channels using `nonblocking_channel`, each message is packed [old_root, updated_root]
output [(UNION_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] union_out_channel_data;
output [CHANNEL_COUNT-1:0] union_out_channel_valid;
input [(UNION_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] union_in_channel_data;
input [CHANNEL_COUNT-1:0] union_in_channel_valid;
// direct channels using `blocking_channel`, each message is packed [receiver, is_odd_cardinality_root, is_touching_boundary]
output [(DIRECT_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] direct_out_channel_data;
output [CHANNEL_COUNT-1:0] direct_out_channel_valid;
input [CHANNEL_COUNT-1:0] direct_out_channel_is_full;
input [(DIRECT_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] direct_in_channel_data;
input [CHANNEL_COUNT-1:0] direct_in_channel_valid;
output [CHANNEL_COUNT-1:0] direct_in_channel_is_taken;



endmodule
