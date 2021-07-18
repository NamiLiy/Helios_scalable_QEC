`timescale 1ns / 10ps

module test_decoder_stage_controller;

`include "../../sources_1/new/parameters.sv"
`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

localparam CODE_DISTANCE = 3;
localparam PU_COUNT = CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 2;
localparam DISTANCE_WIDTH = 1 + PER_DIMENSION_WIDTH;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

reg clk;
reg reset;

reg [PU_COUNT-1:0] is_error_syndromes;
wire [PU_COUNT-1:0] is_odd_clusters;
wire [PU_COUNT-1:0] is_odd_cardinalities;
wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
`define INDEX(i, j) (i * (CODE_DISTANCE-1) + j)
`define is_error_syndrome(i, j) is_error_syndromes[`INDEX(i, j)]
`define is_odd_cluster(i, j) is_odd_clusters[`INDEX(i, j)]
`define root(i, j) roots[ADDRESS_WIDTH*(`INDEX(i, j)+1)-1:ADDRESS_WIDTH*`INDEX(i, j)]
`define root_x(i, j) roots[ADDRESS_WIDTH*(`INDEX(i, j)+1)-1:ADDRESS_WIDTH*`INDEX(i, j)+PER_DIMENSION_WIDTH]
`define root_y(i, j) roots[ADDRESS_WIDTH*(`INDEX(i, j)+1)-PER_DIMENSION_WIDTH-1:ADDRESS_WIDTH*`INDEX(i, j)]
`define PU(i, j) decoder.pu_i[i].pu_j[j].u_processing_unit

wire has_message_flying;
wire has_odd_clusters;
wire [STAGE_WIDTH-1:0] stage;
wire result_valid;
wire [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
assign has_odd_clusters = |is_odd_clusters;

// instantiate
decoder_stage_controller #(.ITERATION_COUNTER_WIDTH(ITERATION_COUNTER_WIDTH)) u_decoder_stage_controller (
    .clk(clk),
    .reset(reset),
    .has_message_flying(has_message_flying),
    .has_odd_clusters(has_odd_clusters),
    .stage(stage),
    .result_valid(result_valid),
    .iteration_counter(iteration_counter)
);

// instantiate
standard_planar_code_2d_no_fast_channel #(.CODE_DISTANCE(CODE_DISTANCE)) decoder (
    .clk(clk),
    .reset(reset),
    .stage(stage),
    .is_error_syndromes(is_error_syndromes),
    .is_odd_clusters(is_odd_clusters),
    .is_odd_cardinalities(is_odd_cardinalities),
    .roots(roots),
    .has_message_flying(has_message_flying)
);

function [ADDRESS_WIDTH-1:0] make_address;
input [PER_DIMENSION_WIDTH-1:0] i;
input [PER_DIMENSION_WIDTH-1:0] j;
begin
    make_address = { i, j };
end
endfunction

initial begin
    clk = 1'b0;
    reset = 1'b1;
    `is_error_syndrome(0, 0) = 0;
    `is_error_syndrome(0, 1) = 0;
    `is_error_syndrome(1, 0) = 1;  // should match with (1, 1)
    `is_error_syndrome(1, 1) = 1;  // should match with (1, 0)
    `is_error_syndrome(2, 0) = 0;
    `is_error_syndrome(2, 1) = 0;
    #200;  // delay for 200ns
    reset = 1'b0;
    #200;
    
    #500;
    `assert(`root(0, 0) == make_address(0, 0), "root should be itself");
    `assert(`root(0, 1) == make_address(0, 1), "root should be itself");
    `assert(`root(1, 0) == make_address(1, 0), "root should be (1, 0)");
    `assert(`root(1, 1) == make_address(1, 0), "root should be (1, 0)");
    `assert(`root(2, 0) == make_address(2, 0), "root should be itself");
    `assert(`root(2, 1) == make_address(2, 1), "root should be itself");
    `assert(`PU(1, 0).neighbor_is_fully_grown == 3'b100, "right neighbor link of (1,0) is fully grown");
    `assert(`PU(1, 1).neighbor_is_fully_grown == 3'b100, "left neighbor link of (1,1) is fully grown");
    `assert(`is_odd_cluster(1, 0) == 0, "it's a even cluster");
    `assert(result_valid, "decoder should terminate after 500ns");
    `assert(iteration_counter == 2, "this simple case should terminate after 2 iterations");
    
    
    // test case 2, connect to boundary
    reset = 1'b1;
    `is_error_syndrome(0, 0) = 0;
    `is_error_syndrome(0, 1) = 0;
    `is_error_syndrome(1, 0) = 1;  // should match with boundary
    `is_error_syndrome(1, 1) = 0;
    `is_error_syndrome(2, 0) = 0;
    `is_error_syndrome(2, 1) = 0;
    #40;
    reset = 1'b0;
    #40;
    #1000;
    `assert(`root(0, 0) == make_address(0, 0), "root should be (0, 0)");
    `assert(`root(0, 1) == make_address(0, 1), "root should be itself");
    `assert(`root(1, 0) == make_address(0, 0), "root should be (0, 0)");
    `assert(`root(1, 1) == make_address(0, 0), "root should be (0, 0)");
    `assert(`root(2, 0) == make_address(0, 0), "root should be (0, 0)");
    `assert(`root(2, 1) == make_address(2, 1), "root should be itself");
    `assert(`is_odd_cluster(0, 0) == 0, "it's a even cluster");
    `assert(`PU(1, 0).is_touching_boundary == 1, "it's itself touching boundary");
    `assert(`PU(0, 0).is_touching_boundary == 1, "it's the root of a set that touching boundary");
    `assert(result_valid, "decoder should terminate after 1000ns");
    `assert(iteration_counter == 3, "this simple case should terminate after 3 iterations");

end

always #10 clk = ~clk;  // flip every 10ns, that is 50MHz clock

endmodule
