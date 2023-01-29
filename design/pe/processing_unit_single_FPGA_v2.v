`timescale 1ns / 1ps

// This PEs are written for Z type ancillas

module processing_unit #(
    parameter PER_DIM_BIT_WIDTH = 3,
    parameter BOUNDARY_BIT_WIDTH = 2,
    parameter NEIGHBOR_COUNT = 6,
    parameter ADDRESS = 0, // M,X,Z, address
    parameter CODE_DISTANCE_X = 5,
    parameter CODE_DISTANCE_Z = 4
    // parameter BOUNDARY_COST_X = 2,
    // parameter BOUNDARY_COST_Z = 2,
    // parameter BOUNDARY_COST_M = 3,
) (
    clk,
    reset,
    measurement,
    global_stage,

    neighbor_fully_grown,
    neighbor_root,
    neighbor_parent_vector,
    neighbor_increase,
    neighbor_is_boundary,

    parent_cluster_parity,
    parent_touching_boundary,

    child_cluster_parity,
    child_touching_boundary,

    self_parent_vector,
    self_cluster_parity,
    self_touching_boundary,

    root,
    busy
);

`include "../../parameters/parameters.sv"

localparam ADDRESS_WIDTH = 3*PER_DIM_BIT_WIDTH;


input clk;
input reset;
input measurement;
input [STAGE_WIDTH-1:0] global_stage;

input [NEIGHBOR_COUNT-1:0] neighbor_fully_grown;
input [NEIGHBOR_COUNT*ADDRESS_WIDTH-1:0] neighbor_root;
input [NEIGHBOR_COUNT-1:0] neighbor_parent_vector;
input [NEIGHBOR_COUNT-1:0] neighbor_is_boundary;
output neighbor_increase;

input [NEIGHBOR_COUNT-1:0] parent_cluster_parity;
input [NEIGHBOR_COUNT-1:0] parent_touching_boundary;
input [NEIGHBOR_COUNT - 1:0] child_cluster_parity;
input [NEIGHBOR_COUNT - 1:0] child_touching_boundary;

output reg [ADDRESS_WIDTH-1:0] self_parent_vector;
output reg self_cluster_parity;
output reg self_touching_boundary;

output reg [ADDRESS_WIDTH-1:0] root;
output busy;

reg [STAGE_WIDTH - 1 : 0] stage;

always@(posedge clk) begin
    if(reset) begin
        stage <= 0;
    end else begin
        stage <= global_stage;
    end
end

always@(posedge clk) begin
    if(reset) begin
        root <= ADDRESS;
    end else begin
        
    end
end





    
endmodule