`timescale 1ns / 1ps

module neighbor_link #(
    parameter LENGTH = 2,  // in a graph with integer edge weight, the LENGTH should be weight * 2, LENGHT > 0
    parameter ADDRESS_WIDTH = 8  // width of address, e.g. single measurement standard surface code under d <= 15 could be 4bit * 2 = 8bit
) (
    input clk,
    input reset,
    output is_fully_grown,
    // used by node a
    input [ADDRESS_WIDTH-1:0] a_old_root_in,
    output [ADDRESS_WIDTH-1:0] b_old_root_out,
    input a_increase,  // should be triggered only once in the stage of STAGE_GROW_BOUNDARY
    // used by node b
    input [ADDRESS_WIDTH-1:0] b_old_root_in,
    output [ADDRESS_WIDTH-1:0] a_old_root_out,
    input b_increase  // should be triggered only once in the stage of STAGE_GROW_BOUNDARY
);

localparam COUNTER_WIDTH = $clog2(LENGTH + 2);  // in the worse case, counter would have a value of LENGTH + 1

reg a_old_root;
reg b_old_root;
reg [COUNTER_WIDTH-1:0] increased;

assign a_old_root_out = a_old_root;
assign b_old_root_out = b_old_root;
assign is_fully_grown = increased >= LENGTH;

always_ff @(posedge clk) begin
    if (reset) begin
        increased <= 0;
        a_old_root <= 0;
        b_old_root <= 0;
    end else begin
        a_old_root <= a_old_root_in;
        b_old_root <= b_old_root_in;
        // only increase when it's not fully grown, to reduce bits needed
        if (increased < LENGTH) begin
            increased <= increased + a_increase + b_increase;
        end
    end
end

endmodule
