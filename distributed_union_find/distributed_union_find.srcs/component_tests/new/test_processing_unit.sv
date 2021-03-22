`timescale 1ns / 10ps

module test_processing_unit;

`include "../../sources_1/new/parameters.sv"
`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

reg clk;
reg reset;
reg [STAGE_WIDTH-1:0] stage;

localparam ADDRESS_WIDTH = 8;
localparam DISTANCE_WIDTH = 6;
localparam NEIGHBOR_COUNT = 1;
localparam FAST_CHANNEL_COUNT = 0;
localparam CHANNEL_COUNT = NEIGHBOR_COUNT + FAST_CHANNEL_COUNT;
localparam CHANNEL_WIDTH = $clog2(CHANNEL_COUNT);  // the index of channel, both neighbor and direct ones
localparam UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH;  // [old_root, new_root]
localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]

localparam ADDRESS_MINE = 8'b10101010;
localparam ADDRESS_OTHER = 8'b11110000;

wire [(ADDRESS_WIDTH * CHANNEL_COUNT)-1:0] compare_solver_addrs;
wire [CHANNEL_COUNT-1:0] compare_solver_addrs_valid;
// distance solvers should take a target and multiple points and output the nearest point to the target, the multiple points are fixed and could be optimized
wire [ADDRESS_WIDTH-1:0] compare_solver_default_addr;
wire [ADDRESS_WIDTH-1:0] distance_solver_target;
reg [CHANNEL_WIDTH-1:0] distance_solver_result_idx;
// neighbor links using `neighbor_link` module
reg [NEIGHBOR_COUNT-1:0] neighbor_is_fully_grown;
wire [ADDRESS_WIDTH-1:0] old_root;  // connect to *_old_root_in, shared by all neighbors
reg [(ADDRESS_WIDTH * NEIGHBOR_COUNT)-1:0] neighbor_old_roots;  // connect to *_old_root_out
wire neighbor_increase;  // connect to *_increase, shared by all neighbors
// union channels using `nonblocking_channel`, each message is packed [old_root, updated_root]
wire [(UNION_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] union_out_channels_data;
wire union_out_channels_valid;
reg [(UNION_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] union_in_channels_data;
reg [CHANNEL_COUNT-1:0] union_in_channels_valid;
// direct channels using `blocking_channel`, each message is packed [receiver, is_odd_cardinality_root, is_touching_boundary]
wire [DIRECT_MESSAGE_WIDTH-1:0] direct_out_channels_data_single;
wire [CHANNEL_COUNT-1:0] direct_out_channels_valid;
reg [CHANNEL_COUNT-1:0] direct_out_channels_is_full;
reg [(DIRECT_MESSAGE_WIDTH * CHANNEL_COUNT)-1:0] direct_in_channels_data;
reg [CHANNEL_COUNT-1:0] direct_in_channels_valid;
wire [CHANNEL_COUNT-1:0] direct_in_channels_is_taken;

// instantiate
processing_unit #(
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .DISTANCE_WIDTH(DISTANCE_WIDTH),
    .NEIGHBOR_COUNT(NEIGHBOR_COUNT),
    .FAST_CHANNEL_COUNT(FAST_CHANNEL_COUNT)
) u_processing_unit(
    .clk(clk),
    .reset(reset),
    .stage(stage),
    .compare_solver_default_addr(compare_solver_default_addr),
    .compare_solver_addrs(compare_solver_addrs),
    .compare_solver_addrs_valid(compare_solver_addrs_valid),
    .distance_solver_target(distance_solver_target),
    .distance_solver_result_idx(distance_solver_result_idx),
    .neighbor_is_fully_grown(neighbor_is_fully_grown),
    .neighbor_old_roots(neighbor_old_roots),
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
    .old_root(old_root)
);


initial begin
    clk = 1'b0;
    reset = 1'b1;
    #200;  // delay for 200ns
    reset = 1'b0;
    #200;
    
    // start test
//    `assert(out_valid == 0, "there is no valid output after reset");
//    in_data = DATA1;
//    in_valid = 1'b1;
    #20;

end

always #10 clk = ~clk;  // flip every 10ns, that is 50MHz clock

endmodule
