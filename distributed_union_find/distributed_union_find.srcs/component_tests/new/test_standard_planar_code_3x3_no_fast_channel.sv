`timescale 1ns / 10ps

module test_standard_planar_code_3x3_no_fast_channel;

`include "../../sources_1/new/parameters.sv"
`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

localparam CODE_DISTANCE = 3;
localparam PU_COUNT = CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 2;
localparam DISTANCE_WIDTH = 1 + PER_DIMENSION_WIDTH;

reg clk;
reg reset;
reg [STAGE_WIDTH-1:0] stage;
reg [PU_COUNT-1:0] is_error_syndromes;
wire [PU_COUNT-1:0] is_odd_clusters;
wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
`define INDEX(i, j) (i * (CODE_DISTANCE-1) + j)
`define is_error_syndrome(i, j) is_error_syndromes[`INDEX(i, j)]
`define is_odd_cluster(i, j) is_odd_clusters[`INDEX(i, j)]
`define root(i, j) roots[ADDRESS_WIDTH*(`INDEX(i, j)+1)-1:ADDRESS_WIDTH*`INDEX(i, j)]
`define root_x(i, j) roots[ADDRESS_WIDTH*(`INDEX(i, j)+1)-1:ADDRESS_WIDTH*`INDEX(i, j)+PER_DIMENSION_WIDTH]
`define root_y(i, j) roots[ADDRESS_WIDTH*(`INDEX(i, j)+1)-PER_DIMENSION_WIDTH-1:ADDRESS_WIDTH*`INDEX(i, j)]
`define PU(i, j) decoder.pu_i[i].pu_j[j].u_processing_unit

// instantiate
standard_planar_code_2d_no_fast_channel #(.CODE_DISTANCE(CODE_DISTANCE)) decoder (
    .clk(clk),
    .reset(reset),
    .stage(stage),
    .is_error_syndromes(is_error_syndromes),
    .is_odd_clusters(is_odd_clusters),
    .roots(roots)
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
    stage = STAGE_IDLE;
    #200;  // delay for 200ns
    reset = 1'b0;
    #200;
    
    // start test
    `assert(`root(0, 0) == make_address(0, 0), "initial root should be itself");
    `assert(`root(0, 1) == make_address(0, 1), "initial root should be itself");
    `assert(`root(1, 0) == make_address(1, 0), "initial root should be itself");
    `assert(`root(1, 1) == make_address(1, 1), "initial root should be itself");
//    $display("root of (2, 0) is (%d, %d)", `root_x(2, 0), `root_y(2, 0));
    `assert(`root(2, 0) == make_address(2, 0), "initial root should be itself");
    `assert(`root(2, 1) == make_address(2, 1), "initial root should be itself");
    
    // after several clock cycles in STAGE_SPREAD_CLUSTER, the root should still be itself
    stage = STAGE_SPREAD_CLUSTER;
    #60;
    `assert(`root(0, 0) == make_address(0, 0), "root should be itself");
    `assert(`root(0, 1) == make_address(0, 1), "root should be itself");
    `assert(`root(1, 0) == make_address(1, 0), "root should be itself");
    `assert(`root(1, 1) == make_address(1, 1), "root should be itself");
    `assert(`root(2, 0) == make_address(2, 0), "root should be itself");
    `assert(`root(2, 1) == make_address(2, 1), "root should be itself");
    
    // after several clock cycles in STAGE_SYNC_IS_ODD_CLUSTER, the root should still be itself
    stage = STAGE_SYNC_IS_ODD_CLUSTER;
    #60;
    `assert(`root(0, 0) == make_address(0, 0), "root should be itself");
    `assert(`root(0, 1) == make_address(0, 1), "root should be itself");
    `assert(`root(1, 0) == make_address(1, 0), "root should be itself");
    `assert(`root(1, 1) == make_address(1, 1), "root should be itself");
    `assert(`root(2, 0) == make_address(2, 0), "root should be itself");
    `assert(`root(2, 1) == make_address(2, 1), "root should be itself");
    
    // grow the boundary once, even if the stage is multiple cycles
    stage = STAGE_GROW_BOUNDARY;
    #100;
    `assert(`PU(1, 0).neighbor_is_fully_grown == 3'b100, "right neighbor link of (1,0) is fully grown");
    `assert(`PU(1, 1).neighbor_is_fully_grown == 3'b100, "left neighbor link of (1,1) is fully grown");
    
    // then spread the cluster
    stage = STAGE_SPREAD_CLUSTER;
    #100;
    `assert(`root(0, 0) == make_address(0, 0), "root should be itself");
    `assert(`root(0, 1) == make_address(0, 1), "root should be itself");
    `assert(`root(1, 0) == make_address(1, 0), "root should be (1, 0)");
    `assert(`root(1, 1) == make_address(1, 0), "root should be (1, 0)");
    `assert(`root(2, 0) == make_address(2, 0), "root should be itself");
    `assert(`root(2, 1) == make_address(2, 1), "root should be itself");
    `assert(`PU(1, 0).is_odd_cardinality == 0, "(1, 0) has two children: (1, 0) and (1, 1), so it's the root of even cluster");
    `assert(`PU(1, 1).is_odd_cardinality == 1, "(1, 1) is no longer a valid root, so the is_odd_cluster remains the same");
    `assert(`is_odd_cluster(1, 0) == 1, "is_odd_cluster never changes in this stage");
    `assert(`is_odd_cluster(1, 1) == 1, "is_odd_cluster never changes in this stage");
    
    // finally syncrhonize `is_odd_cluster`
    stage = STAGE_SYNC_IS_ODD_CLUSTER;
    #100;
    `assert(`root(1, 0) == make_address(1, 0), "root should be (1, 0)");
    `assert(`root(1, 1) == make_address(1, 0), "root should be (1, 0)");
    `assert(`is_odd_cluster(1, 0) == 0, "it becomes a even cluster");
    
    // run another iteration, should keep the same
    stage = STAGE_GROW_BOUNDARY;
    #100;
    stage = STAGE_SPREAD_CLUSTER;
    #100
    stage = STAGE_SYNC_IS_ODD_CLUSTER;
    #100;
    `assert(`root(0, 0) == make_address(0, 0), "root should be itself");
    `assert(`root(0, 1) == make_address(0, 1), "root should be itself");
    `assert(`root(1, 0) == make_address(1, 0), "root should be (1, 0)");
    `assert(`root(1, 1) == make_address(1, 0), "root should be (1, 0)");
    `assert(`root(2, 0) == make_address(2, 0), "root should be itself");
    `assert(`root(2, 1) == make_address(2, 1), "root should be itself");
    `assert(`PU(1, 0).neighbor_is_fully_grown == 3'b100, "right neighbor link of (1,0) is fully grown");
    `assert(`PU(1, 1).neighbor_is_fully_grown == 3'b100, "left neighbor link of (1,1) is fully grown");
    `assert(`is_odd_cluster(1, 0) == 0, "it's a even cluster");

end

always #10 clk = ~clk;  // flip every 10ns, that is 50MHz clock

endmodule
