`timescale 1ns / 10ps

module test_tree_distance_2d_solver;

`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

localparam PER_DIMENSION_WIDTH = 4;
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 2;
localparam CHANNEL_COUNT = 5;
localparam CHANNEL_WIDTH = $clog2(CHANNEL_COUNT);  // the index of channel, both neighbor and direct ones
reg [ADDRESS_WIDTH-1:0] target;
reg [ADDRESS_WIDTH-1:0] value_1;
reg [ADDRESS_WIDTH-1:0] value_2;
reg [ADDRESS_WIDTH-1:0] value_3;
reg [ADDRESS_WIDTH-1:0] value_4;
reg [ADDRESS_WIDTH-1:0] value_5;
wire [CHANNEL_WIDTH-1:0] result_idx;

// instantiate
tree_distance_2d_solver #(
    .PER_DIMENSION_WIDTH(PER_DIMENSION_WIDTH),
    .CHANNEL_COUNT(CHANNEL_COUNT)
) u_tree_distance_2d_solver(
    .points({ value_5, value_4, value_3, value_2, value_1 }),
    .target(target),
    .result_idx(result_idx)
);

localparam DATA1 = 8'b10101010;
localparam DATA2 = 8'b11110000;
localparam DATA3 = 8'b01010101;

initial begin

    // init points
    value_1 = { 4'd5, 4'd4 };
    value_2 = { 4'd12, 4'd13 };
    value_3 = { 4'd3, 4'd11 };
    value_4 = { 4'd15, 4'd0 };
    value_5 = { 4'd6, 4'd4 };
    
    // target 1
    target = { 4'd4, 4'd3 };
    #20;
    `assert(result_idx == 1 - 1, "nearest point");
    
    // target 2
    target = { 4'd6, 4'd5 };
    #20;
    `assert(result_idx == 5 - 1, "nearest point");
    
    // target 3
    target = { 4'd7, 4'd3 };
    #20;
    `assert(result_idx == 5 - 1, "nearest point");
    
    // target 4
    target = { 4'd11, 4'd2 };
    #20;
    `assert(result_idx == 4 - 1, "nearest point");
    
    // target 5
    target = { 4'd9, 4'd7 };
    #20;
    `assert(result_idx == 5 - 1, "nearest point");
    
    // target 6
    target = { 4'd10, 4'd8 };
    #20;
    `assert(result_idx == 2 - 1, "nearest point");
    
    // target 7
    target = { 4'd1, 4'd14 };
    #20;
    `assert(result_idx == 3 - 1, "nearest point");
    
    // target 8
    target = { 4'd6, 4'd15 };
    #20;
    `assert(result_idx == 3 - 1, "nearest point");
    
    // target 9
    target = { 4'd2, 4'd8 };
    #20;
    `assert(result_idx == 3 - 1, "nearest point");
    
    // target 10
    target = { 4'd15, 4'd15 };
    #20;
    `assert(result_idx == 2 - 1, "nearest point");
    
    // target 11
    target = { 4'd15, 4'd0 };
    #20;
    `assert(result_idx == 4 - 1, "nearest point");
    
    // target 12
    target = { 4'd0, 4'd0 };
    #20;
    `assert(result_idx == 1 - 1, "nearest point");

end

endmodule
