`timescale 1ns / 1ps

module single_FPGA_decoding_graph_dynamic_rsc #(
    parameter GRID_WIDTH_X = 4,
    parameter GRID_WIDTH_Z = 1,
    parameter GRID_WIDTH_U = 3,
    parameter MAX_WEIGHT = 2 
) (
    clk,
    reset,
    measurements,
    odd_clusters,
    roots,
    busy,
    global_stage,
    correction
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

localparam X_BIT_WIDTH = $clog2(GRID_WIDTH_X);
localparam Z_BIT_WIDTH = $clog2(GRID_WIDTH_Z);
localparam U_BIT_WIDTH = $clog2(GRID_WIDTH_U);
localparam ADDRESS_WIDTH = X_BIT_WIDTH + Z_BIT_WIDTH + U_BIT_WIDTH;

localparam PU_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam PU_COUNT = PU_COUNT_PER_ROUND * GRID_WIDTH_U;
localparam NEIGHBOR_COUNT = 10;

localparam NS_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z;
localparam EW_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z + 1;
localparam UD_ERROR_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam DIAG_NS_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z - GRID_WIDTH_Z;
localparam DIAG_EW_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z - GRID_WIDTH_Z - 1;
localparam DIAG_HOOK_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_U > 3) ? GRID_WIDTH_U-1 : 0;
localparam CORRECTION_COUNT_PER_ROUND = NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND + UD_ERROR_COUNT_PER_ROUND + DIAG_NS_ERROR_COUNT_PER_ROUND + DIAG_EW_COUNT_PER_ROUND + DIAG_HOOK_ERROR_COUNT_PER_ROUND;
localparam EXPOSED_DATA_SIZE = ADDRESS_WIDTH + 1 + 1 + 1 + 1 + 3;

localparam LINK_BIT_WIDTH = $clog2(MAX_WEIGHT + 1);

input clk;
input reset;
input [PU_COUNT_PER_ROUND-1:0] measurements;
input [STAGE_WIDTH-1:0] global_stage;

output [PU_COUNT - 1 : 0] odd_clusters;
output [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
output [PU_COUNT - 1 : 0] busy;
output [CORRECTION_COUNT_PER_ROUND - 1 : 0] correction;

genvar i;
genvar j;
genvar k;

`define INDEX(i, j, k) (i * GRID_WIDTH_Z + j + k * GRID_WIDTH_Z*GRID_WIDTH_X)
`define INDEX_PLANAR(i, j) (i * GRID_WIDTH_Z + j)
`define ADDRESS(i,j,k) ( (k<< (X_BIT_WIDTH + Z_BIT_WIDTH)) + (i<< Z_BIT_WIDTH) + j)
`define roots(i, j, k) roots[ADDRESS_WIDTH*(`INDEX(i, j, k)+1)-1:ADDRESS_WIDTH*`INDEX(i, j, k)]
`define odd_clusters(i, j, k) odd_clusters[`INDEX(i, j, k)]
`define busy(i, j, k) busy[`INDEX(i, j, k)]
`define PU(i, j, k) pu_k[k].pu_i[i].pu_j[j]

generate
    for (k=GRID_WIDTH_U-1; k >= 0; k=k-1) begin: pu_k
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: pu_i
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: pu_j
                wire local_measurement;
                wire measurement_out;
                wire [NEIGHBOR_COUNT-1:0] neighbor_fully_grown;
                wire neighbor_increase;
                wire [NEIGHBOR_COUNT-1:0] neighbor_is_boundary;
                wire [NEIGHBOR_COUNT-1:0] neighbor_is_error;

                wire [NEIGHBOR_COUNT*EXPOSED_DATA_SIZE-1:0] input_data;
                wire [NEIGHBOR_COUNT*EXPOSED_DATA_SIZE-1:0] output_data;

                wire odd;
                wire [ADDRESS_WIDTH-1 : 0] root;
                wire busy_PE;

                processing_unit #(
                    .ADDRESS_WIDTH(ADDRESS_WIDTH),
                    .NEIGHBOR_COUNT(NEIGHBOR_COUNT),
                    .ADDRESS(`ADDRESS(i,j,k))
                ) pu (
                    .clk(clk),
                    .reset(reset),
                    .measurement(local_measurement),
                    .measurement_out(measurement_out),
                    .global_stage(global_stage),

                    .neighbor_fully_grown(neighbor_fully_grown),
                    .neighbor_increase(neighbor_increase),
                    .neighbor_is_boundary(neighbor_is_boundary),
                    .neighbor_is_error(neighbor_is_error),

                    .input_data(input_data),
                    .output_data(output_data),

                    .odd(odd),
                    .root(root),
                    .busy(busy_PE)
                );
                assign `roots(i, j, k) = root;
                assign `busy(i, j, k) = busy_PE;
                assign `odd_clusters(i,j,k) = odd;
            end
        end
    end
endgenerate
    

generate
    for (k=GRID_WIDTH_U-1; k >= 0; k=k-1) begin: pu_k_extra
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: pu_i_extra
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: pu_j_extra
                if(k==GRID_WIDTH_U-1) begin
                    assign `PU(i, j, k).local_measurement = measurements[`INDEX_PLANAR(i,j)];
                end else begin
                    assign `PU(i, j, k).local_measurement = `PU(i, j, k+1).measurement_out;
                end
            end
        end
    end

endgenerate

`define NEIGHBOR_IDX_NORTH 0 // In RSC North means North West
`define NEIGHBOR_IDX_SOUTH 1 
`define NEIGHBOR_IDX_WEST 2
`define NEIGHBOR_IDX_EAST 3
`define NEIGHBOR_IDX_DOWN 4
`define NEIGHBOR_IDX_UP 5
`define NEIGHBOR_IDX_DIAG_NORTH 6
`define NEIGHBOR_IDX_DIAG_SOUTH 7
`define NEIGHBOR_IDX_DIAG_WEST 8
`define NEIGHBOR_IDX_DIAG_EAST 9
`define NEIGHBOR_IDX_HOOK_LEFT 10
`define NEIGHBOR_IDX_HOOK_RIGHT 11

`define SLICE_ADDRESS_VEC(vec, idx) (vec[(((idx)+1)*ADDRESS_WIDTH)-1:(idx)*ADDRESS_WIDTH])
`define SLICE_VEC(vec, idx, width) (vec[idx*width +: width])


`define CORR_INDEX_NS(i, j) ((i-1)*(GRID_WIDTH_Z) + j-1)
`define CORR_INDEX_EW(i, j) ((i-1)*(GRID_WIDTH_Z) + j + NS_ERROR_COUNT_PER_ROUND)
`define CORR_INDEX_UD(i, j) (i*GRID_WIDTH_Z + j + NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND)
`define CORR_INDEX_DIAG_NS(i, j) (i*GRID_WIDTH_Z + j + NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND + UD_ERROR_COUNT_PER_ROUND)
`define CORR_INDEX_DIAG_EW(i, j) (i*GRID_WIDTH_Z + j + NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND + UD_ERROR_COUNT_PER_ROUND + DIAG_NS_ERROR_COUNT_PER_ROUND)
`define CORR_INDEX_DIAG_HOOK(i, j) (i*GRID_WIDTH_Z + j + NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND + UD_ERROR_COUNT_PER_ROUND + DIAG_NS_ERROR_COUNT_PER_ROUND + DIAG_EW_ERROR_COUNT_PER_ROUND)


`define CORRECTION_NS(i, j) correction[`CORR_INDEX_NS(i, j)]
`define CORRECTION_EW(i, j) correction[`CORR_INDEX_EW(i, j)]
`define CORRECTION_UD(i, j) correction[`CORR_INDEX_UD(i, j)]
`define CORRECTION_DIAG_NS(i, j) correction[`CORR_INDEX_DIAG_NS(i, j)]
`define CORRECTION_DIAG_EW(i, j) correction[`CORR_INDEX_DIAG_EW(i, j)]
`define CORRECTION_DIAG_HOOK(i, j) correction[`CORR_INDEX_DIAG_HOOK(i, j)]

// `define EDGE_INDEX(i,j) (i*GRID_WIDTH_Z + j)

//localparam logic [31:0] weight_list [CORRECTION_COUNT_PER_ROUND] = {32'd9, 32'd9, 32'd9, 32'd8, 32'd9, 32'd9, 32'd8, 32'd9, 32'd9, 32'd9, 32'd10, 32'd9, 32'd9, 32'd9, 32'd9, 32'd10, 32'd10, 32'd9, 32'd9, 32'd9, 32'd10, 32'd10, 32'd9, 32'd9, 32'd9, 32'd10, 32'd9, 32'd9, 32'd9, 32'd9, 32'd10, 32'd9, 32'd9, 32'd11, 32'd9, 32'd11, 32'd8, 32'd8, 32'd9, 32'd9, 32'd10, 32'd10, 32'd10, 32'd9, 32'd11, 32'd8, 32'd9, 32'd11, 32'd8, 32'd9, 32'd9, 32'd9, 32'd11, 32'd9, 32'd9, 32'd9, 32'd10, 32'd9, 32'd9, 32'd9, 32'd9, 32'd8, 32'd10, 32'd8, 32'd8, 32'd9, 32'd10, 32'd9, 32'd16, 32'd9, 32'd9, 32'd10, 32'd10, 32'd9, 32'd8, 32'd11, 32'd9, 32'd11, 
//32'd12, 32'd9, 32'd16, 32'd9, 32'd9, 32'd9, 32'd9, 32'd9, 32'd9, 32'd9, 32'd9, 32'd9, 32'd10, 32'd8, 32'd9, 32'd9, 32'd9, 32'd8, 32'd9, 32'd9, 32'd10, 32'd9, 32'd9, 32'd8, 32'd16, 32'd9, 32'd9, 32'd8, 32'd10, 32'd9, 32'd9, 32'd9, 32'd8, 32'd9, 32'd8, 32'd9, 32'd10, 32'd9, 32'd9, 32'd9, 32'd9, 32'd9, 32'd9, 32'd9, 32'd8, 32'd8, 32'd8, 32'd10, 32'd9, 32'd9, 32'd10, 32'd10, 32'd8, 32'd9, 32'd9, 32'd8, 32'd9, 32'd10, 32'd9, 32'd9, 32'd8, 32'd9, 32'd8, 32'd16, 32'd9, 32'd8, 32'd10, 32'd9, 32'd9, 32'd9, 32'd8, 32'd9, 32'd10, 32'd10, 32'd9, 32'd9, 32'd9, 32'd9, 32'd9, 
//32'd12, 32'd9, 32'd9, 32'd9, 32'd10, 32'd9, 32'd16, 32'd9, 32'd9, 32'd8, 32'd11, 32'd8, 32'd9, 32'd9, 32'd10, 32'd10, 32'd9, 32'd8, 32'd12, 32'd9, 32'd9, 32'd8, 32'd9, 32'd10, 32'd9, 32'd8, 32'd9, 32'd10, 32'd8, 32'd9, 32'd8, 32'd12, 32'd9, 32'd10, 32'd8, 32'd9, 32'd10, 32'd8, 32'd10, 32'd9, 32'd10, 32'd10, 32'd9, 32'd8, 32'd9, 32'd9, 32'd9, 32'd8, 32'd9, 32'd9, 32'd9, 32'd9, 32'd9, 32'd8, 32'd9, 32'd10, 32'd11, 32'd9, 32'd9, 32'd9, 32'd15, 32'd9, 32'd8, 32'd9, 32'd10, 32'd10, 32'd10, 32'd8, 32'd9, 32'd9, 32'd9, 32'd9, 32'd9, 32'd9, 32'd16, 32'd9, 32'd9, 32'd9, 32'd9, 32'd9, 32'd9, 32'd8, 32'd9, 32'd9};

//`define WEIGHT_NS(i,j) weight_list[`CORR_INDEX_NS(i, j)]
//`define WEIGHT_EW(i,j) weight_list[`CORR_INDEX_EW(i, j)]
//`define WEIGHT_UD(i,j) weight_list[`CORR_INDEX_UD(i, j)]

`define WEIGHT_NS(i,j) 2
`define WEIGHT_EW(i,j) 2
`define WEIGHT_UD(i,j) 2



`define NEIGHBOR_LINK_INTERNAL_0(ai, aj, ak, bi, bj, bk, adirection, bdirection) \
    wire is_boundary; \
    wire fully_grown; \
    neighbor_link_internal #( \
        .ADDRESS_WIDTH(ADDRESS_WIDTH), \
        .MAX_WEIGHT(MAX_WEIGHT) \
    ) neighbor_link ( \
        .clk(clk), \
        .reset(reset), \
        .global_stage(global_stage), \
        .fully_grown(fully_grown), \
        .a_increase(`PU(ai, aj, ak).neighbor_increase), \
        .b_increase(`PU(bi, bj, bk).neighbor_increase), \
        .is_boundary(is_boundary), \
        .a_is_error_in(`PU(ai, aj, ak).neighbor_is_error[adirection]), \
        .b_is_error_in(`PU(bi, bj, bk).neighbor_is_error[bdirection]), \
        .is_error(is_error_out), \
        .a_input_data(`SLICE_VEC(`PU(ai, aj, ak).output_data, adirection, EXPOSED_DATA_SIZE)), \
        .b_input_data(`SLICE_VEC(`PU(bi, bj, bk).output_data, bdirection, EXPOSED_DATA_SIZE)), \
        .a_output_data(`SLICE_VEC(`PU(ai, aj, ak).input_data, adirection, EXPOSED_DATA_SIZE)), \
        .b_output_data(`SLICE_VEC(`PU(bi, bj, bk).input_data, bdirection, EXPOSED_DATA_SIZE)), \
        .weight_in(weight_in), \
        .weight_out(), \
        .boundary_condition_in(0), \
        .boundary_condition_out(), \
        .is_error_systolic_in(is_error_systolic_in) \
    );\
    assign `PU(ai, aj, ak).neighbor_fully_grown[adirection] = fully_grown;\
    assign `PU(bi, bj, bk).neighbor_fully_grown[bdirection] = fully_grown;\
    assign `PU(ai, aj, ak).neighbor_is_boundary[adirection] = is_boundary;\
    assign `PU(bi, bj, bk).neighbor_is_boundary[bdirection] = is_boundary;

`define NEIGHBOR_LINK_INTERNAL_SINGLE(ai, aj, ak, adirection, type) \
    neighbor_link_internal #( \
        .ADDRESS_WIDTH(ADDRESS_WIDTH), \
        .MAX_WEIGHT(MAX_WEIGHT) \
    ) neighbor_link ( \
        .clk(clk), \
        .reset(reset), \
        .global_stage(global_stage), \
        .fully_grown(`PU(ai, aj, ak).neighbor_fully_grown[adirection]), \
        .a_increase(`PU(ai, aj, ak).neighbor_increase), \
        .b_increase(), \
        .is_boundary(`PU(ai, aj, ak).neighbor_is_boundary[adirection]), \
        .a_is_error_in(`PU(ai, aj, ak).neighbor_is_error[adirection]), \
        .b_is_error_in(), \
        .is_error(is_error_out), \
        .a_input_data(`SLICE_VEC(`PU(ai, aj, ak).output_data, adirection, EXPOSED_DATA_SIZE)), \
        .b_input_data(), \
        .a_output_data(`SLICE_VEC(`PU(ai, aj, ak).input_data, adirection, EXPOSED_DATA_SIZE)), \
        .b_output_data(), \
        .weight_in(weight_in), \
        .weight_out(), \
        .boundary_condition_in(type), \
        .boundary_condition_out(), \
        .is_error_systolic_in(is_error_systolic_in) \
    ); 
    
generate
    // Generate North South neighbors
    for (k=0; k < GRID_WIDTH_U; k=k+1) begin: ns_k
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: ns_i
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: ns_j
                wire is_error_systolic_in;
                wire is_error_out;
                wire [LINK_BIT_WIDTH-1:0] weight_in;
                if(i==0 && j < GRID_WIDTH_Z) begin // First row
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j, k, `NEIGHBOR_IDX_NORTH, 2)
                end else if(i==GRID_WIDTH_X && j < GRID_WIDTH_Z) begin
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j, k, `NEIGHBOR_IDX_SOUTH, 2)                   
                end else if (i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j > 0) begin // odd rows which are always internal
                    `NEIGHBOR_LINK_INTERNAL_0(i-1, j-1, k, i, j-1, k, `NEIGHBOR_IDX_SOUTH, `NEIGHBOR_IDX_NORTH)
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j == 0) begin // First element of even rows
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j, k, `NEIGHBOR_IDX_NORTH, 2)
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j == GRID_WIDTH_Z) begin // Last element of even rows
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j-1, k, `NEIGHBOR_IDX_SOUTH, 1)
                end else if (i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j > 0 && j < GRID_WIDTH_Z) begin // Middle elements of even rows
                    `NEIGHBOR_LINK_INTERNAL_0(i-1, j-1, k, i, j, k, `NEIGHBOR_IDX_SOUTH, `NEIGHBOR_IDX_NORTH)
                end
            end
        end
    end

    // Generate East West neighbors
    for (k=0; k < GRID_WIDTH_U; k=k+1) begin: ew_k
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: ew_i
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: ew_j
                wire is_error_systolic_in;
                wire is_error_out;
                wire [LINK_BIT_WIDTH-1:0] weight_in;
                assign weight_in = `WEIGHT_EW(i,j);
                if(i==0 && j < GRID_WIDTH_Z) begin // First row
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j, k, `NEIGHBOR_IDX_EAST, 2)
                end else if(i==GRID_WIDTH_X && j < GRID_WIDTH_Z) begin // Last row
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j, k, `NEIGHBOR_IDX_WEST, 2)
                end else if (i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j < GRID_WIDTH_Z) begin // even rows which are always internal
                    `NEIGHBOR_LINK_INTERNAL_0(i, j, k, i-1, j, k, `NEIGHBOR_IDX_EAST, `NEIGHBOR_IDX_WEST)
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j == 0) begin // First element of odd rows
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j, k, `NEIGHBOR_IDX_WEST, 1)
                end else if(i < GRID_WIDTH_X -1 && i > 0 && i%2 == 1 && j == GRID_WIDTH_Z) begin // Last element of odd rows excluding last row
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j-1, k, `NEIGHBOR_IDX_EAST, 2)
                end else if(i == GRID_WIDTH_X -1 && j == GRID_WIDTH_Z) begin // Last element of last odd row
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j-1, k, `NEIGHBOR_IDX_EAST, 1)
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j > 0 && j < GRID_WIDTH_Z) begin // Middle elements of odd rows
                    `NEIGHBOR_LINK_INTERNAL_0(i, j-1, k, i-1, j, k, `NEIGHBOR_IDX_EAST, `NEIGHBOR_IDX_WEST)
                end
            end
        end
    end

    // Generate UP DOWN link
    for (k=0; k <= GRID_WIDTH_U; k=k+1) begin: ud_k
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ud_i
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ud_j
                wire is_error_systolic_in;
                wire is_error_out;
                wire [LINK_BIT_WIDTH-1:0] weight_in;
                assign weight_in = `WEIGHT_UD(i,j);
                if(k==0) begin
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j, k, `NEIGHBOR_IDX_DOWN, 1)
                end else if(k==GRID_WIDTH_U) begin
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j, k-1, `NEIGHBOR_IDX_UP, 2)
                end else if (k < GRID_WIDTH_U) begin
                    `NEIGHBOR_LINK_INTERNAL_0(i, j, k-1, i, j, k, `NEIGHBOR_IDX_UP, `NEIGHBOR_IDX_DOWN)
                end
            end
        end
    end
    
    // Generate DIAGONAL NS link
    for (k=0; k < GRID_WIDTH_U; k=k+1) begin: diag_ns_k
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: diag_ns_i
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: diag_ns_j
                wire is_error_systolic_in;
                wire is_error_out;
                wire [LINK_BIT_WIDTH-1:0] weight_in;
                if(i==0 && j < GRID_WIDTH_Z) begin // First row
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j, k, `NEIGHBOR_IDX_DIAG_NORTH, 2)
                end else if (k == GRID_WIDTH_U-1  && j < GRID_WIDTH_Z) begin
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j, k, `NEIGHBOR_IDX_DIAG_SOUTH, 2)
                end else if(i==GRID_WIDTH_X && j < GRID_WIDTH_Z) begin
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j, k, `NEIGHBOR_IDX_DIAG_SOUTH, 2)                   
                end else if (i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j > 0 && k < GRID_WIDTH_U-1) begin // odd rows which are always internal
                    `NEIGHBOR_LINK_INTERNAL_0(i-1, j-1, k, i, j-1, k+1, `NEIGHBOR_IDX_DIAG_SOUTH, `NEIGHBOR_IDX_DIAG_NORTH)
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j == 0) begin // First element of even rows
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j, k, `NEIGHBOR_IDX_DIAG_NORTH, 2)
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j == GRID_WIDTH_Z) begin // Last element of even rows
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j-1, k, `NEIGHBOR_IDX_DIAG_SOUTH, 2)
                end else if (i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j > 0 && j < GRID_WIDTH_Z) begin // Middle elements of even rows
                    `NEIGHBOR_LINK_INTERNAL_0(i-1, j-1, k, i, j, k+1, `NEIGHBOR_IDX_DIAG_SOUTH, `NEIGHBOR_IDX_DIAG_NORTH)
                end
            end
        end
    end
    
    for (k=0; k < GRID_WIDTH_U; k=k+1) begin: diag_ew_k
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: diag_ew_i 
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: diag_ew_j
                wire is_error_systolic_in;
                wire is_error_out;
                wire [LINK_BIT_WIDTH-1:0] weight_in;
                if(i==0 && j < GRID_WIDTH_Z) begin // First row
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j, k, `NEIGHBOR_IDX_DIAG_EAST, 2)
                end else if (k == GRID_WIDTH_U-1  && j < GRID_WIDTH_Z) begin
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j, k, `NEIGHBOR_IDX_DIAG_WEST, 2)
                end else if(i==GRID_WIDTH_X && j < GRID_WIDTH_Z) begin // Last row
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j, k, `NEIGHBOR_IDX_DIAG_WEST, 2)
                end else if (i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j < GRID_WIDTH_Z && k < GRID_WIDTH_U-1) begin // even rows which are always internal
                    `NEIGHBOR_LINK_INTERNAL_0(i, j, k+1, i-1, j, k, `NEIGHBOR_IDX_DIAG_EAST, `NEIGHBOR_IDX_DIAG_WEST)
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j == 0) begin // First element of odd rows
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j, k, `NEIGHBOR_IDX_DIAG_WEST, 2)
                end else if(i < GRID_WIDTH_X -1 && i > 0 && i%2 == 1 && j == GRID_WIDTH_Z) begin // Last element of odd rows excluding last row
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j-1, k, `NEIGHBOR_IDX_DIAG_EAST, 2)
                end else if(i == GRID_WIDTH_X -1 && j == GRID_WIDTH_Z) begin // Last element of last odd row
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j-1, k, `NEIGHBOR_IDX_DIAG_EAST, 2)
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j > 0 && j < GRID_WIDTH_Z) begin // Middle elements of odd rows
                    `NEIGHBOR_LINK_INTERNAL_0(i, j-1, k+1, i-1, j, k, `NEIGHBOR_IDX_DIAG_EAST, `NEIGHBOR_IDX_DIAG_WEST)
                end
            end
        end
    end
    
//    for (k=0; k <= GRID_WIDTH_U; k=k+1) begin: diag_hook_k
//        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: diag_hook_i
//            for (j=0; j <= GRID_WIDTH_Z*2; j=j+1) begin: diag_hook_j
//                if (i > 0 && i < GRID_WIDTH_X && j < GRID_WIDTH_Z) begin
//                    `NEIGHBOR_LINK_INTERNAL_0(i, j, k, i, j+1, k+1, `NEIGHBOR_IDX_HOOK_LEFT, `NEIGHBOR_IDX_HOOK_RIGHT);
//                end else if (j % 2 == 0) begin
//                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j, k, `NEIGHBOR_IDX_HOOK_LEFT, 2);
//                end else begin
//                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j, k, `NEIGHBOR_IDX_HOOK_RIGHT, 2);
//                end
//            end
//        end
//    end
    
endgenerate

generate
    for (k=0; k < GRID_WIDTH_U-1; k=k+1) begin: ns_k_extra
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: ns_i_extra
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: ns_j_extra
                if (i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j > 0) begin // odd rows 
                    assign ns_k[k].ns_i[i].ns_j[j].is_error_systolic_in = ns_k[k+1].ns_i[i].ns_j[j].is_error_out;
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j > 0) begin // Even rows
                    assign ns_k[k].ns_i[i].ns_j[j].is_error_systolic_in = ns_k[k+1].ns_i[i].ns_j[j].is_error_out;
                end
            end
        end
    end

    for (k=0; k < GRID_WIDTH_U - 1; k=k+1) begin: ew_k_extra
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: ew_i_extra
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: ew_j_extra
                if (i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j < GRID_WIDTH_Z) begin // even rows which are always internal
                    assign ew_k[k].ew_i[i].ew_j[j].is_error_systolic_in = ew_k[k+1].ew_i[i].ew_j[j].is_error_out;
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j == 0) begin // First element of odd rows
                    assign ew_k[k].ew_i[i].ew_j[j].is_error_systolic_in = ew_k[k+1].ew_i[i].ew_j[j].is_error_out;
                end else if(i == GRID_WIDTH_X -1 && j == GRID_WIDTH_Z) begin // Last element of last odd row
                    assign ew_k[k].ew_i[i].ew_j[j].is_error_systolic_in = ew_k[k+1].ew_i[i].ew_j[j].is_error_out;
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j > 0 && j < GRID_WIDTH_Z) begin // Middle elements of odd rows
                    assign ew_k[k].ew_i[i].ew_j[j].is_error_systolic_in = ew_k[k+1].ew_i[i].ew_j[j].is_error_out;
                end
            end
        end
    end


    for (k=0; k < GRID_WIDTH_U-1; k=k+1) begin: ud_k_extra
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ud_i_extra
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ud_j_extra
                assign ud_k[k].ud_i[i].ud_j[j].is_error_systolic_in = ud_k[k+1].ud_i[i].ud_j[j].is_error_out;
            end
        end
    end
    
    for (k=0; k < GRID_WIDTH_U-1; k=k+1) begin: diag_ns_k_extra
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: diag_ns_i_extra
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: diag_ns_j_extra
                if (i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j > 0) begin // odd rows 
                    assign diag_ns_k[k].diag_ns_i[i].diag_ns_j[j].is_error_systolic_in = diag_ns_k[k+1].diag_ns_i[i].diag_ns_j[j].is_error_out;
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j > 0) begin // Even rows
                    assign diag_ns_k[k].diag_ns_i[i].diag_ns_j[j].is_error_systolic_in = diag_ns_k[k+1].diag_ns_i[i].diag_ns_j[j].is_error_out;
                end
            end
        end
    end
    
    for (k=0; k < GRID_WIDTH_U-2; k=k+1) begin: diag_ew_k_extra
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: diag_ew_i_extra
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: diag_ew_j_extra
                if (i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j < GRID_WIDTH_Z) begin // even rows which are always internal
                    assign diag_ew_k[k].diag_ew_i[i].diag_ew_j[j].is_error_systolic_in = diag_ew_k[k+1].diag_ew_i[i].diag_ew_j[j].is_error_out;
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j == 0) begin // First element of odd rows
                    assign diag_ew_k[k].diag_ew_i[i].diag_ew_j[j].is_error_systolic_in = diag_ew_k[k+1].diag_ew_i[i].diag_ew_j[j].is_error_out;
                end else if(i == GRID_WIDTH_X -1 && j == GRID_WIDTH_Z) begin // Last element of last odd row
                    assign diag_ew_k[k].diag_ew_i[i].diag_ew_j[j].is_error_systolic_in = diag_ew_k[k+1].diag_ew_i[i].diag_ew_j[j].is_error_out;
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j > 0 && j < GRID_WIDTH_Z) begin // Middle elements of odd rows
                    assign diag_ew_k[k].diag_ew_i[i].diag_ew_j[j].is_error_systolic_in = diag_ew_k[k+1].diag_ew_i[i].diag_ew_j[j].is_error_out;
                end
            end
        end
    end
    
//    for (k=0; k < GRID_WIDTH_U-1; k=k+1) begin: diag_hook_k_extra
//        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: diag_hook_i_extra
//            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: diag_hook_j_extra
//                if (i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j > 0) begin // odd rows 
//                    assign diag_ns_k[k].diag_ns_i[i].diag_ns_j[j].is_error_systolic_in = diag_hook_k[k+1].diag_hook_i[i].diag_hook_j[j].is_error_out;
//                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j > 0) begin // Even rows
//                    assign diag_ns_k[k].diag_ns_i[i].diag_ns_j[j].is_error_systolic_in = diag_hook_k[k+1].diag_hook_i[i].diag_hook_j[j].is_error_out;
//                end
//            end
//        end
//    end

    for (i=1; i < GRID_WIDTH_X; i=i+1) begin: ns_i_output
        for (j=1; j <= GRID_WIDTH_Z; j=j+1) begin: ns_j_output
            assign `CORRECTION_NS(i,j) = ns_k[0].ns_i[i].ns_j[j].is_error_out;
        end
    end

    for (i=1; i < GRID_WIDTH_X; i=i+1) begin: ew_i_output
        for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ew_j_output
            assign `CORRECTION_EW(i,j) = ew_k[0].ew_i[i].ew_j[j].is_error_out;
        end
    end

    assign `CORRECTION_EW(GRID_WIDTH_X-1,GRID_WIDTH_Z) = ew_k[0].ew_i[GRID_WIDTH_X-1].ew_j[GRID_WIDTH_Z].is_error_out;

    for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ud_i_output
        for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ud_j_output
            assign `CORRECTION_UD(i,j) = ud_k[0].ud_i[i].ud_j[j].is_error_out;
        end
    end
    
    for (i=1; i < GRID_WIDTH_X; i=i+1) begin: diag_ns_i_output
        for (j=1; j <= GRID_WIDTH_Z; j=j+1) begin: diag_ns_j_output
            if(i == 1 || (i == 2 && j < GRID_WIDTH_Z)) begin
                assign `CORRECTION_DIAG_NS(i,j) = diag_ns_k[0].diag_ns_i[i].diag_ns_j[j].is_error_out;
            end else if (i % 2 == 1) begin
                assign `CORRECTION_DIAG_NS(i,j-(i/2)) = diag_ns_k[0].diag_ns_i[i].diag_ns_j[j].is_error_out;
            end else if (i % 2 == 0) begin
                assign `CORRECTION_DIAG_NS(i,j - ((i-1)/2)) = diag_ns_k[0].diag_ns_i[i].diag_ns_j[j].is_error_out;
            end
        end
    end
    
    for (i=1; i < GRID_WIDTH_X-1; i=i+1) begin: diag_ew_i_output
        for (j=1; j <= GRID_WIDTH_Z; j=j+1) begin: diag_ew_j_output
            if (i % 2 == 0) begin
                assign `CORRECTION_DIAG_EW(i,j-(i/2)) = diag_ew_k[0].diag_ew_i[i].diag_ew_j[j].is_error_out;
            end else if (i % 2 == 1 && j > 0 && j < GRID_WIDTH_Z) begin
                assign `CORRECTION_DIAG_EW(i,j - ((i-1)/2)) = diag_ew_k[0].diag_ew_i[i].diag_ew_j[j].is_error_out; 
            end
        end
    end

    for (k=0; k < GRID_WIDTH_U; k=k+1) begin: ns_k_weight
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: ns_i_weight
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: ns_j_weight
                if (i < GRID_WIDTH_X && i > 0 && j > 0) begin
                    assign ns_k[k].ns_i[i].ns_j[j].weight_in = `WEIGHT_NS(i,j);
                end else begin // Fake edges
                    assign ns_k[k].ns_i[i].ns_j[j].weight_in = 2;
                end
            end
        end
    end

    for (k=0; k < GRID_WIDTH_U; k=k+1) begin: ew_k_weight
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: ew_i_weight
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: ew_j_weight
                if (i < GRID_WIDTH_X && i > 0 && j < GRID_WIDTH_Z) begin
                    assign ew_k[k].ew_i[i].ew_j[j].weight_in = `WEIGHT_EW(i,j);
                end else if (i == GRID_WIDTH_X-1 && j == GRID_WIDTH_Z) begin
                    assign ew_k[k].ew_i[i].ew_j[j].weight_in = `WEIGHT_EW(i,j);
                end else begin // Fake edges
                    assign ew_k[k].ew_i[i].ew_j[j].weight_in = 2;
                end
            end
        end
    end

    for (k=0; k <= GRID_WIDTH_U; k=k+1) begin: ud_k_weight
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ud_i_weight
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ud_j_weight
                if(k < GRID_WIDTH_U) begin
                    assign ud_k[k].ud_i[i].ud_j[j].weight_in = `WEIGHT_UD(i,j);
                end else begin // Fake edges
                    assign ud_k[k].ud_i[i].ud_j[j].weight_in = 2;
                end
            end
        end
    end
    
    for (k=0; k < GRID_WIDTH_U; k=k+1) begin: diag_ns_k_weight
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: diag_ns_i_weight
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: diag_ns_j_weight
                if (i < GRID_WIDTH_X && i > 0 && j > 0) begin
                    assign diag_ns_k[k].diag_ns_i[i].diag_ns_j[j].weight_in = `WEIGHT_NS(i,j);
                end else begin // Fake edges
                    assign diag_ns_k[k].diag_ns_i[i].diag_ns_j[j].weight_in = 2;
                end
            end
        end
    end
    
    for (k=0; k < GRID_WIDTH_U-1; k=k+1) begin: diag_ew_k_weight
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: diag_ew_i_weight
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: diag_ew_j_weight
                if (i < GRID_WIDTH_X && i > 0 && j < GRID_WIDTH_Z) begin
                    assign diag_ew_k[k].diag_ew_i[i].diag_ew_j[j].weight_in = `WEIGHT_EW(i,j);
                end else if (i == GRID_WIDTH_X-1 && j == GRID_WIDTH_Z) begin
                    assign diag_ew_k[k].diag_ew_i[i].diag_ew_j[j].weight_in = `WEIGHT_EW(i,j);
                end else begin // Fake edges
                    assign diag_ew_k[k].diag_ew_i[i].diag_ew_j[j].weight_in = 2;
                end
            end
        end
    end


endgenerate

endmodule

