`timescale 1ns / 1ps

module single_FPGA_decoding_graph #(
    parameter CODE_DISTANCE_X = 3,
    parameter CODE_DISTANCE_Z = 2,
    parameter WEIGHT_X = 2,
    parameter WEIGHT_Z = 2,
    parameter WEIGHT_M = 2 
) (
    clk,
    reset,
    measurements,
    odd_clusters,
    roots,
    busy,
    global_stage
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PER_DIM_BIT_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = PER_DIM_BIT_WIDTH * 3;

localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam NEIGHBOR_COUNT = 6;

input clk;
input reset;
input [PU_COUNT-1:0] measurements;
input [STAGE_WIDTH-1:0] global_stage;

output [PU_COUNT - 1 : 0] odd_clusters;
output [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
output [PU_COUNT - 1 : 0] busy;

genvar i;
genvar j;
genvar k;

`define INDEX(i, j, k) (i * CODE_DISTANCE_Z + j + k * CODE_DISTANCE_Z*CODE_DISTANCE_X)
`define roots(i, j, k) roots[ADDRESS_WIDTH*(`INDEX(i, j, k)+1)-1:ADDRESS_WIDTH*`INDEX(i, j, k)]
`define odd_clusters(i, j, k) odd_clusters[`INDEX(i, j, k)]
`define busy(i, j, k) busy[`INDEX(i, j, k)]

generate
    for (k=0; k < MEASUREMENT_ROUNDS; k=k+1) begin: pu_k
        for (i=0; i < CODE_DISTANCE_X; i=i+1) begin: pu_i
            for (j=0; j < CODE_DISTANCE_Z; j=j+1) begin: pu_j
                wire [NEIGHBOR_COUNT-1:0] neighbor_fully_grown;
                wire [ADDRESS_WIDTH*NEIGHBOR_COUNT-1:0] neighbor_root;
                wire [NEIGHBOR_COUNT-1:0] neighbor_parent_vector;
                wire neighbor_increase;
                wire [NEIGHBOR_COUNT-1:0] neighbor_is_boundary;
                wire [NEIGHBOR_COUNT-1:0] parent_odd;
                wire [NEIGHBOR_COUNT-1:0] parent_vector;
                wire [NEIGHBOR_COUNT-1:0] child_cluster_parity;
                wire [NEIGHBOR_COUNT-1:0] child_touching_boundary;
                wire [NEIGHBOR_COUNT-1:0] cluster_parity;
                wire [NEIGHBOR_COUNT-1:0] cluster_touching_boundary;
                wire odd;
                wire [ADDRESS_WIDTH-1 : 0] root;
                wire busy_PE;
                processing_unit #(
                    .PER_DIM_BIT_WIDTH(PER_DIM_BIT_WIDTH),
                    .NEIGHBOR_COUNT(NEIGHBOR_COUNT),
                    .ADDRESS(`INDEX(i,j,k)),
                    .CODE_DISTANCE_X(CODE_DISTANCE_X),
                    .CODE_DISTANCE_Z(CODE_DISTANCE_Z)
                ) pu (
                    .clk(clk),
                    .reset(reset),
                    .measurement(measurements),
                    .global_stage(global_stage),
                    .neighbor_fully_grown(neighbor_fully_grown),
                    .neighbor_root(neighbor_root),
                    .neighbor_parent_vector(neighbor_parent_vector),
                    .neighbor_increase(neighbor_increase),
                    .neighbor_is_boundary(neighbor_is_boundary),
                    .parent_odd(parent_odd),
                    .parent_vector(parent_vector),
                    .child_cluster_parity(child_cluster_parity),
                    .child_touching_boundary(child_touching_boundary),
                    .cluster_parity(cluster_parity),
                    .cluster_touching_boundary(cluster_touching_boundary),
                    .odd(odd),
                    .root(root),
                    .busy(busy)
                );
                assign `roots(i, j, k) = root;
                assign `busy(i, j, k) = busy_PE;
                assign `odd_clusters(i,j,k) = odd;
            end
        end
    end
endgenerate

`define NEIGHBOR_IDX_NORTH 0
`define NEIGHBOR_IDX_SOUTH 1 
`define NEIGHBOR_IDX_WEST 2
`define NEIGHBOR_IDX_EAST 3
`define NEIGHBOR_IDX_DOWN 4
`define NEIGHBOR_IDX_UP 5
`define PU(i, j, k) pu_k[k].pu_i[i].pu_j[j]
`define SLICE_ADDRESS_VEC(vec, idx) (vec[(((idx)+1)*ADDRESS_WIDTH)-1:(idx)*ADDRESS_WIDTH])


generate
    // Generate North South neighbors
    for (k=0; k < MEASUREMENT_ROUNDS; k=k+1) begin: ns_k
        for (i=0; i <= CODE_DISTANCE_X; i=i+1) begin: ns_i
            for (j=0; j < CODE_DISTANCE_Z; j=j+1) begin: ns_j
                if(i==0) begin
                    neighbor_link #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .WEIGHT(WEIGHT_X),
                        .BOUNDARY_CONDITION(2)
                    ) neighbor_link_NS (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_SOUTH]),
                        .a_root_in(), .b_root_in(), .a_root_out(), .b_root_out(), .a_parent_vector_in(), .b_parent_vector_in(),
                        .a_parent_vector_out(`PU(i, j, k).neighbor_parent_vector[`NEIGHBOR_IDX_SOUTH]),
                        .b_parent_vector_out(),
                        .a_increase(`PU(i, j, k).neighbor_increase),
                        .b_increase(),
                        .is_boundary(`PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_SOUTH]),
                        .a_parent_odd_in(), .b_parent_odd_in(), .a_parent_odd_out(), .b_parent_odd_out(),
                        .a_child_cluster_parity_in(), .b_child_cluster_parity_in(), .a_child_cluster_parity_out(), .b_child_cluster_parity_out(),
                        .a_child_touching_boundary_in(), .b_child_touching_boundary_in(), .a_child_touching_boundary_out(), .b_child_touching_boundary_out()
                    );     
                end else if (i < CODE_DISTANCE_X) begin
                    neighbor_link #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .WEIGHT(WEIGHT_X),
                        .BOUNDARY_CONDITION(0)
                    ) neighbor_link_NS (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_SOUTH]),
                        .a_root_in(`PU(i-1, j, k).root),
                        .b_root_in(`PU(i, j, k).root),
                        .a_root_out(`SLICE_ADDRESS_VEC(`PU(i-1, j, k).neighbor_root, `NEIGHBOR_IDX_NORTH)),
                        .b_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k).neighbor_root, `NEIGHBOR_IDX_SOUTH)),
                        .a_parent_vector_in(`PU(i-1, j, k).parent_vector[`NEIGHBOR_IDX_NORTH]),
                        .b_parent_vector_in(`PU(i, j, k).parent_vector[`NEIGHBOR_IDX_SOUTH]),
                        .a_parent_vector_out(`PU(i-1, j, k).neighbor_parent_vector[`NEIGHBOR_IDX_NORTH]),
                        .b_parent_vector_out(`PU(i, j, k).neighbor_parent_vector[`NEIGHBOR_IDX_SOUTH]),
                        .a_increase(`PU(i-1, j, k).neighbor_increase),
                        .b_increase(`PU(i, j, k).neighbor_increase),
                        .is_boundary(`PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_SOUTH]),
                        .a_parent_odd_in(`PU(i-1, j, k).odd),
                        .b_parent_odd_in(`PU(i, j, k).odd),
                        .a_parent_odd_out(`PU(i-1, j, k).parent_odd[`NEIGHBOR_IDX_NORTH]),
                        .b_parent_odd_out(`PU(i, j, k).parent_odd[`NEIGHBOR_IDX_SOUTH]),
                        .a_child_cluster_parity_in(`PU(i-1, j, k).cluster_parity),
                        .b_child_cluster_parity_in(`PU(i, j, k).cluster_parity),
                        .a_child_cluster_parity_out(`PU(i-1, j, k).child_cluster_parity[`NEIGHBOR_IDX_NORTH]),
                        .b_child_cluster_parity_out(`PU(i, j, k).child_cluster_parity[`NEIGHBOR_IDX_SOUTH]),
                        .a_child_touching_boundary_in(`PU(i-1, j, k).cluster_touching_boundary),
                        .b_child_touching_boundary_in(`PU(i, j, k).cluster_touching_boundary),
                        .a_child_touching_boundary_out(`PU(i-1, j, k).child_touching_boundary[`NEIGHBOR_IDX_NORTH]),
                        .b_child_touching_boundary_out(`PU(i, j, k).child_touching_boundary[`NEIGHBOR_IDX_SOUTH])
                    );

                    assign `PU(i-1, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_NORTH] = `PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_SOUTH];
                    assign `PU(i-1, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_NORTH] = `PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_SOUTH];
                end else begin
                    neighbor_link #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .WEIGHT(WEIGHT_X),
                        .BOUNDARY_CONDITION(2)
                    ) neighbor_link_NS (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i-1, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_NORTH]),
                        .a_root_in(), .b_root_in(), .a_root_out(), .b_root_out(), .a_parent_vector_in(), .b_parent_vector_in(),
                        .a_parent_vector_out(`PU(i-1, j, k).neighbor_parent_vector[`NEIGHBOR_IDX_NORTH]),
                        .b_parent_vector_out(),
                        .a_increase(`PU(i-1, j, k).neighbor_increase),
                        .b_increase(),
                        .is_boundary(`PU(i-1, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_NORTH]),
                        .a_parent_odd_in(), .b_parent_odd_in(), .a_parent_odd_out(), .b_parent_odd_out(),
                        .a_child_cluster_parity_in(), .b_child_cluster_parity_in(), .a_child_cluster_parity_out(), .b_child_cluster_parity_out(),
                        .a_child_touching_boundary_in(), .b_child_touching_boundary_in(), .a_child_touching_boundary_out(), .b_child_touching_boundary_out()
                    );
                end
            end
        end
    end

    // Generate East West neighbors
    for (k=0; k < MEASUREMENT_ROUNDS; k=k+1) begin: ew_k
        for (i=0; i < CODE_DISTANCE_X; i=i+1) begin: ew_i
            for (j=0; j <= CODE_DISTANCE_Z; j=j+1) begin: ew_j
                if(j==0) begin
                    neighbor_link #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .WEIGHT(WEIGHT_Z),
                        .BOUNDARY_CONDITION(1)
                    ) neighbor_link_EW (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_WEST]),
                        .a_root_in(), .b_root_in(), .a_root_out(), .b_root_out(), .a_parent_vector_in(), .b_parent_vector_in(),
                        .a_parent_vector_out(`PU(i, j, k).neighbor_parent_vector[`NEIGHBOR_IDX_WEST]),
                        .b_parent_vector_out(),
                        .a_increase(`PU(i, j, k).neighbor_increase),
                        .b_increase(),
                        .is_boundary(`PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_WEST]),
                        .a_parent_odd_in(), .b_parent_odd_in(), .a_parent_odd_out(), .b_parent_odd_out(),
                        .a_child_cluster_parity_in(), .b_child_cluster_parity_in(), .a_child_cluster_parity_out(), .b_child_cluster_parity_out(),
                        .a_child_touching_boundary_in(), .b_child_touching_boundary_in(), .a_child_touching_boundary_out(), .b_child_touching_boundary_out()
                    );     
                end else if (j < CODE_DISTANCE_Z) begin
                    neighbor_link #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .WEIGHT(WEIGHT_Z),
                        .BOUNDARY_CONDITION(0)
                    ) neighbor_link_EW (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_WEST]),
                        .a_root_in(`PU(i, j-1, k).root),
                        .b_root_in(`PU(i, j, k).root),
                        .a_root_out(`SLICE_ADDRESS_VEC(`PU(i, j-1, k).neighbor_root, `NEIGHBOR_IDX_EAST)),
                        .b_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k).neighbor_root, `NEIGHBOR_IDX_WEST)),
                        .a_parent_vector_in(`PU(i, j-1, k).parent_vector[`NEIGHBOR_IDX_EAST]),
                        .b_parent_vector_in(`PU(i, j, k).parent_vector[`NEIGHBOR_IDX_WEST]),
                        .a_parent_vector_out(`PU(i, j-1, k).neighbor_parent_vector[`NEIGHBOR_IDX_EAST]),
                        .b_parent_vector_out(`PU(i, j, k).neighbor_parent_vector[`NEIGHBOR_IDX_WEST]),
                        .a_increase(`PU(i, j-1, k).neighbor_increase),
                        .b_increase(`PU(i, j, k).neighbor_increase),
                        .is_boundary(`PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_WEST]),
                        .a_parent_odd_in(`PU(i, j-1, k).odd),
                        .b_parent_odd_in(`PU(i, j, k).odd),
                        .a_parent_odd_out(`PU(i, j-1, k).parent_odd[`NEIGHBOR_IDX_EAST]),
                        .b_parent_odd_out(`PU(i, j, k).parent_odd[`NEIGHBOR_IDX_WEST]),
                        .a_child_cluster_parity_in(`PU(i, j-1, k).cluster_parity),
                        .b_child_cluster_parity_in(`PU(i, j, k).cluster_parity),
                        .a_child_cluster_parity_out(`PU(i, j-1, k).child_cluster_parity[`NEIGHBOR_IDX_EAST]),
                        .b_child_cluster_parity_out(`PU(i, j, k).child_cluster_parity[`NEIGHBOR_IDX_WEST]),
                        .a_child_touching_boundary_in(`PU(i, j-1, k).cluster_touching_boundary),
                        .b_child_touching_boundary_in(`PU(i, j, k).cluster_touching_boundary),
                        .a_child_touching_boundary_out(`PU(i, j-1, k).child_touching_boundary[`NEIGHBOR_IDX_EAST]),
                        .b_child_touching_boundary_out(`PU(i, j, k).child_touching_boundary[`NEIGHBOR_IDX_SOUTH])
                    );

                    assign `PU(i, j-1, k).neighbor_fully_grown[`NEIGHBOR_IDX_EAST] = `PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_SOUTH];
                    assign `PU(i, j-1, k).neighbor_is_boundary[`NEIGHBOR_IDX_EAST] = `PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_SOUTH];
                end else begin
                    neighbor_link #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .WEIGHT(WEIGHT_Z),
                        .BOUNDARY_CONDITION(1)
                    ) neighbor_link_EW (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j-1, k).neighbor_fully_grown[`NEIGHBOR_IDX_EAST]),
                        .a_root_in(), .b_root_in(), .a_root_out(), .b_root_out(), .a_parent_vector_in(), .b_parent_vector_in(),
                        .a_parent_vector_out(`PU(i, j-1, k).neighbor_parent_vector[`NEIGHBOR_IDX_EAST]),
                        .b_parent_vector_out(),
                        .a_increase(`PU(i, j-1, k).neighbor_increase),
                        .b_increase(),
                        .is_boundary(`PU(i, j-1, k).neighbor_is_boundary[`NEIGHBOR_IDX_EAST]),
                        .a_parent_odd_in(), .b_parent_odd_in(), .a_parent_odd_out(), .b_parent_odd_out(),
                        .a_child_cluster_parity_in(), .b_child_cluster_parity_in(), .a_child_cluster_parity_out(), .b_child_cluster_parity_out(),
                        .a_child_touching_boundary_in(), .b_child_touching_boundary_in(), .a_child_touching_boundary_out(), .b_child_touching_boundary_out()
                    );
                end
            end
        end
    end

    // Generate UP DOWN link
    for (k=0; k <= MEASUREMENT_ROUNDS; k=k+1) begin: ud_k
        for (i=0; i < CODE_DISTANCE_X; i=i+1) begin: ud_i
            for (j=0; j < CODE_DISTANCE_Z; j=j+1) begin: ud_j
                if(k==0) begin
                    neighbor_link #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .WEIGHT(WEIGHT_M),
                        .BOUNDARY_CONDITION(1)
                    ) neighbor_link_UD (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_DOWN]),
                        .a_root_in(), .b_root_in(), .a_root_out(), .b_root_out(), .a_parent_vector_in(), .b_parent_vector_in(),
                        .a_parent_vector_out(`PU(i, j, k).neighbor_parent_vector[`NEIGHBOR_IDX_DOWN]),
                        .b_parent_vector_out(),
                        .a_increase(`PU(i, j, k).neighbor_increase),
                        .b_increase(),
                        .is_boundary(`PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_DOWN]),
                        .a_parent_odd_in(), .b_parent_odd_in(), .a_parent_odd_out(), .b_parent_odd_out(),
                        .a_child_cluster_parity_in(), .b_child_cluster_parity_in(), .a_child_cluster_parity_out(), .b_child_cluster_parity_out(),
                        .a_child_touching_boundary_in(), .b_child_touching_boundary_in(), .a_child_touching_boundary_out(), .b_child_touching_boundary_out()
                    );     
                end else if (k < MEASUREMENT_ROUNDS) begin
                    neighbor_link #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .WEIGHT(WEIGHT_Z),
                        .BOUNDARY_CONDITION(0)
                    ) neighbor_link_UD (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_DOWN]),
                        .a_root_in(`PU(i, j, k-1).root),
                        .b_root_in(`PU(i, j, k).root),
                        .a_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k-1).neighbor_root, `NEIGHBOR_IDX_UP)),
                        .b_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k).neighbor_root, `NEIGHBOR_IDX_DOWN)),
                        .a_parent_vector_in(`PU(i, j, k-1).parent_vector[`NEIGHBOR_IDX_UP]),
                        .b_parent_vector_in(`PU(i, j, k).parent_vector[`NEIGHBOR_IDX_DOWN]),
                        .a_parent_vector_out(`PU(i, j, k-1).neighbor_parent_vector[`NEIGHBOR_IDX_UP]),
                        .b_parent_vector_out(`PU(i, j, k).neighbor_parent_vector[`NEIGHBOR_IDX_DOWN]),
                        .a_increase(`PU(i, j, k-1).neighbor_increase),
                        .b_increase(`PU(i, j, k).neighbor_increase),
                        .is_boundary(`PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_DOWN]),
                        .a_parent_odd_in(`PU(i, j, k-1).odd),
                        .b_parent_odd_in(`PU(i, j, k).odd),
                        .a_parent_odd_out(`PU(i, j, k-1).parent_odd[`NEIGHBOR_IDX_UP]),
                        .b_parent_odd_out(`PU(i, j, k).parent_odd[`NEIGHBOR_IDX_DOWN]),
                        .a_child_cluster_parity_in(`PU(i, j, k-1).cluster_parity),
                        .b_child_cluster_parity_in(`PU(i, j, k).cluster_parity),
                        .a_child_cluster_parity_out(`PU(i, j, k-1).child_cluster_parity[`NEIGHBOR_IDX_UP]),
                        .b_child_cluster_parity_out(`PU(i, j, k).child_cluster_parity[`NEIGHBOR_IDX_DOWN]),
                        .a_child_touching_boundary_in(`PU(i, j, k-1).cluster_touching_boundary),
                        .b_child_touching_boundary_in(`PU(i, j, k).cluster_touching_boundary),
                        .a_child_touching_boundary_out(`PU(i, j, k-1).child_touching_boundary[`NEIGHBOR_IDX_UP]),
                        .b_child_touching_boundary_out(`PU(i, j, k).child_touching_boundary[`NEIGHBOR_IDX_SOUTH])
                    );

                    assign `PU(i, j, k-1).neighbor_fully_grown[`NEIGHBOR_IDX_UP] = `PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_SOUTH];
                    assign `PU(i, j, k-1).neighbor_is_boundary[`NEIGHBOR_IDX_UP] = `PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_SOUTH];
                end else begin
                    neighbor_link #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .WEIGHT(WEIGHT_Z),
                        .BOUNDARY_CONDITION(2)
                    ) neighbor_link_UD (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j, k-1).neighbor_fully_grown[`NEIGHBOR_IDX_UP]),
                        .a_root_in(), .b_root_in(), .a_root_out(), .b_root_out(), .a_parent_vector_in(), .b_parent_vector_in(),
                        .a_parent_vector_out(`PU(i, j, k-1).neighbor_parent_vector[`NEIGHBOR_IDX_UP]),
                        .b_parent_vector_out(),
                        .a_increase(`PU(i, j, k-1).neighbor_increase),
                        .b_increase(),
                        .is_boundary(`PU(i, j, k-1).neighbor_is_boundary[`NEIGHBOR_IDX_UP]),
                        .a_parent_odd_in(), .b_parent_odd_in(), .a_parent_odd_out(), .b_parent_odd_out(),
                        .a_child_cluster_parity_in(), .b_child_cluster_parity_in(), .a_child_cluster_parity_out(), .b_child_cluster_parity_out(),
                        .a_child_touching_boundary_in(), .b_child_touching_boundary_in(), .a_child_touching_boundary_out(), .b_child_touching_boundary_out()
                    );
                end
            end
        end
    end
    
endgenerate

endmodule

