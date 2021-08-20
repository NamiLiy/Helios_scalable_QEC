`timescale 1ns / 1ps

module bench_resource_usage #(
    CODE_DISTANCE = 5  // has CODE_DISTANCE ¡Á (CODE_DISTANCE-1) processing units
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

standard_planar_code_2d_no_fast_channel #(.CODE_DISTANCE(CODE_DISTANCE)) decoder (
    .clk(clk),
    .reset(reset),
    .stage(stage),
    .is_error_syndromes(is_error_syndromes),
    .is_odd_clusters(is_odd_clusters)
);

endmodule
