`timescale 1ns / 1ps

module single_FPGA_decoding_graph_dynamic #(
    parameter GRID_WIDTH_X = 3,
    parameter GRID_WIDTH_Z = 2,
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
localparam NEIGHBOR_COUNT = 6;

localparam NS_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z;
localparam EW_ERROR_COUNT_PER_ROUND = GRID_WIDTH_X * (GRID_WIDTH_Z+1);
localparam UD_ERROR_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam CORRECTION_COUNT_PER_ROUND = NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND + UD_ERROR_COUNT_PER_ROUND;
localparam EXPOSED_DATA_SIZE = ADDRESS_WIDTH + 1 + 1 + 1 + 1 + 3;

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

`define NEIGHBOR_IDX_NORTH 0
`define NEIGHBOR_IDX_SOUTH 1 
`define NEIGHBOR_IDX_WEST 2
`define NEIGHBOR_IDX_EAST 3
`define NEIGHBOR_IDX_DOWN 4
`define NEIGHBOR_IDX_UP 5

`define SLICE_ADDRESS_VEC(vec, idx) (vec[(((idx)+1)*ADDRESS_WIDTH)-1:(idx)*ADDRESS_WIDTH])
`define SLICE_VEC(vec, idx, width) (vec[idx*width +: width])


`define CORR_INDEX_NS(i, j) ((i-1)*(GRID_WIDTH_Z) + j)
`define CORR_INDEX_EW(i, j) (i*(GRID_WIDTH_Z+1) + j + NS_ERROR_COUNT_PER_ROUND)
`define CORR_INDEX_UD(i, j) (i*GRID_WIDTH_Z + j + NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND)


`define CORRECTION_NS(i, j) correction[`CORR_INDEX_NS(i, j)]
`define CORRECTION_EW(i, j) correction[`CORR_INDEX_EW(i, j)]
`define CORRECTION_UD(i, j) correction[`CORR_INDEX_UD(i, j)]


generate
    // Generate North South neighbors
    for (k=0; k < GRID_WIDTH_U; k=k+1) begin: ns_k
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: ns_i
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ns_j
                wire is_error_systolic_in;
                wire is_error_out;
                if(i==0) begin
                    neighbor_link_internal #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .MAX_WEIGHT(MAX_WEIGHT)
                    ) neighbor_link_NS (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_NORTH]),
                        .a_increase(`PU(i, j, k).neighbor_increase),
                        .b_increase(),
                        .is_boundary(`PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_NORTH]),
                        .a_is_error_in(`PU(i, j, k).neighbor_is_error[`NEIGHBOR_IDX_NORTH]),
                        .b_is_error_in(),
                        .is_error(),
                        .a_input_data(`SLICE_VEC(`PU(i, j, k).output_data, `NEIGHBOR_IDX_NORTH, EXPOSED_DATA_SIZE)),
                        .b_input_data(),
                        .a_output_data(`SLICE_VEC(`PU(i, j, k).input_data, `NEIGHBOR_IDX_NORTH, EXPOSED_DATA_SIZE)),
                        .b_output_data(),
                        .weight_in(2),
                        .weight_out(),
                        .boundary_condition_in(2),
                        .boundary_condition_out(),
                        .is_error_systolic_in(is_error_systolic_in)

                    );  
                end else if (i < GRID_WIDTH_X) begin
                    neighbor_link_internal #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .MAX_WEIGHT(MAX_WEIGHT)
                    ) neighbor_link_NS (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i-1, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_SOUTH]),
                        .a_increase(`PU(i-1, j, k).neighbor_increase),
                        .b_increase(`PU(i, j, k).neighbor_increase),
                        .is_boundary(`PU(i-1, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_SOUTH]),
                        .a_is_error_in(`PU(i-1, j, k).neighbor_is_error[`NEIGHBOR_IDX_SOUTH]),
                        .b_is_error_in(`PU(i, j, k).neighbor_is_error[`NEIGHBOR_IDX_NORTH]),
                        .is_error(is_error_out),
                        .a_input_data(`SLICE_VEC(`PU(i-1, j, k).output_data, `NEIGHBOR_IDX_SOUTH, EXPOSED_DATA_SIZE)),
                        .b_input_data(`SLICE_VEC(`PU(i, j, k).output_data, `NEIGHBOR_IDX_NORTH, EXPOSED_DATA_SIZE)),
                        .a_output_data(`SLICE_VEC(`PU(i-1, j, k).input_data, `NEIGHBOR_IDX_SOUTH, EXPOSED_DATA_SIZE)),
                        .b_output_data(`SLICE_VEC(`PU(i, j, k).input_data, `NEIGHBOR_IDX_NORTH, EXPOSED_DATA_SIZE)),
                        .weight_in(2),
                        .weight_out(),
                        .boundary_condition_in(0),
                        .boundary_condition_out(),
                        .is_error_systolic_in(is_error_systolic_in)
                    );

                    assign `PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_NORTH] = `PU(i-1, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_SOUTH];
                    assign `PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_NORTH] = `PU(i-1, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_SOUTH];
                end else begin
                    neighbor_link_internal #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .MAX_WEIGHT(MAX_WEIGHT)
                    ) neighbor_link_NS (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i-1, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_SOUTH]),
                        .a_increase(`PU(i-1, j, k).neighbor_increase),
                        .b_increase(),
                        .is_boundary(`PU(i-1, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_SOUTH]),
                        .a_is_error_in(`PU(i-1, j, k).neighbor_is_error[`NEIGHBOR_IDX_SOUTH]),
                        .b_is_error_in(),
                        .is_error(),
                        .a_input_data(`SLICE_VEC(`PU(i-1, j, k).output_data, `NEIGHBOR_IDX_SOUTH, EXPOSED_DATA_SIZE)),
                        .b_input_data(),
                        .a_output_data(`SLICE_VEC(`PU(i-1, j, k).input_data, `NEIGHBOR_IDX_SOUTH, EXPOSED_DATA_SIZE)),
                        .b_output_data(),
                        .weight_in(2),
                        .weight_out(),
                        .boundary_condition_in(2),
                        .boundary_condition_out(),
                        .is_error_systolic_in(is_error_systolic_in)
                    ); 
                end
            end
        end
    end

    // Generate East West neighbors
    for (k=0; k < GRID_WIDTH_U; k=k+1) begin: ew_k
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ew_i
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: ew_j
                wire is_error_systolic_in;
                wire is_error_out;
                if(j==0) begin
                    neighbor_link_internal #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .MAX_WEIGHT(MAX_WEIGHT)
                    ) neighbor_link_EW (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_WEST]),
                        .a_increase(`PU(i, j, k).neighbor_increase),
                        .b_increase(),
                        .is_boundary(`PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_WEST]),
                        .a_is_error_in(`PU(i, j, k).neighbor_is_error[`NEIGHBOR_IDX_WEST]),
                        .b_is_error_in(),
                        .is_error(is_error_out),
                        .a_input_data(`SLICE_VEC(`PU(i, j, k).output_data, `NEIGHBOR_IDX_WEST, EXPOSED_DATA_SIZE)),
                        .b_input_data(),
                        .a_output_data(`SLICE_VEC(`PU(i, j, k).input_data, `NEIGHBOR_IDX_WEST, EXPOSED_DATA_SIZE)),
                        .b_output_data(),
                        .weight_in(2),
                        .weight_out(),
                        .boundary_condition_in(1),
                        .boundary_condition_out(),
                        .is_error_systolic_in(is_error_systolic_in)
                    );  
                end else if (j < GRID_WIDTH_Z) begin
                    neighbor_link_internal #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .MAX_WEIGHT(MAX_WEIGHT)
                    ) neighbor_link_EW (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j-1, k).neighbor_fully_grown[`NEIGHBOR_IDX_EAST]),
                        .a_increase(`PU(i, j-1, k).neighbor_increase),
                        .b_increase(`PU(i, j, k).neighbor_increase),
                        .is_boundary(`PU(i, j-1, k).neighbor_is_boundary[`NEIGHBOR_IDX_EAST]),
                        .a_is_error_in(`PU(i, j-1, k).neighbor_is_error[`NEIGHBOR_IDX_EAST]),
                        .b_is_error_in(`PU(i, j, k).neighbor_is_error[`NEIGHBOR_IDX_WEST]),
                        .is_error(is_error_out),
                        .a_input_data(`SLICE_VEC(`PU(i, j-1, k).output_data, `NEIGHBOR_IDX_EAST, EXPOSED_DATA_SIZE)),
                        .b_input_data(`SLICE_VEC(`PU(i, j, k).output_data, `NEIGHBOR_IDX_WEST, EXPOSED_DATA_SIZE)),
                        .a_output_data(`SLICE_VEC(`PU(i, j-1, k).input_data, `NEIGHBOR_IDX_EAST, EXPOSED_DATA_SIZE)),
                        .b_output_data(`SLICE_VEC(`PU(i, j, k).input_data, `NEIGHBOR_IDX_WEST, EXPOSED_DATA_SIZE)),
                        .weight_in(2),
                        .weight_out(),
                        .boundary_condition_in(0),
                        .boundary_condition_out(),
                        .is_error_systolic_in(is_error_systolic_in)
                    );

                    assign `PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_WEST] = `PU(i, j-1, k).neighbor_fully_grown[`NEIGHBOR_IDX_EAST];
                    assign `PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_WEST] = `PU(i, j-1, k).neighbor_is_boundary[`NEIGHBOR_IDX_EAST];
                end else begin
                    neighbor_link_internal #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .MAX_WEIGHT(MAX_WEIGHT)
                    ) neighbor_link_EW (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j-1, k).neighbor_fully_grown[`NEIGHBOR_IDX_EAST]),
                        .a_increase(`PU(i, j-1, k).neighbor_increase),
                        .b_increase(),
                        .is_boundary(`PU(i, j-1, k).neighbor_is_boundary[`NEIGHBOR_IDX_EAST]),
                        .a_is_error_in(`PU(i, j-1, k).neighbor_is_error[`NEIGHBOR_IDX_EAST]),
                        .b_is_error_in(),
                        .is_error(is_error_out),
                        .a_input_data(`SLICE_VEC(`PU(i, j-1, k).output_data, `NEIGHBOR_IDX_EAST, EXPOSED_DATA_SIZE)),
                        .b_input_data(),
                        .a_output_data(`SLICE_VEC(`PU(i, j-1, k).input_data, `NEIGHBOR_IDX_EAST, EXPOSED_DATA_SIZE)),
                        .b_output_data(),
                        .weight_in(2),
                        .weight_out(),
                        .boundary_condition_in(1),
                        .boundary_condition_out(),
                        .is_error_systolic_in(is_error_systolic_in)
                    );
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
                if(k==0) begin
                    neighbor_link_internal #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .MAX_WEIGHT(MAX_WEIGHT)
                    ) neighbor_link_UD (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_DOWN]),
                        .a_increase(`PU(i, j, k).neighbor_increase),
                        .b_increase(),
                        .is_boundary(`PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_DOWN]),
                        .a_is_error_in(`PU(i, j, k).neighbor_is_error[`NEIGHBOR_IDX_DOWN]),
                        .b_is_error_in(),
                        .is_error(is_error_out),
                        .a_input_data(`SLICE_VEC(`PU(i, j, k).output_data, `NEIGHBOR_IDX_DOWN, EXPOSED_DATA_SIZE)),
                        .b_input_data(),
                        .a_output_data(`SLICE_VEC(`PU(i, j, k).input_data, `NEIGHBOR_IDX_DOWN, EXPOSED_DATA_SIZE)),
                        .b_output_data(),
                        .weight_in(2),
                        .weight_out(),
                        .boundary_condition_in(1),
                        .boundary_condition_out(),
                        .is_error_systolic_in(is_error_systolic_in)
                    );  
                end else if (k < GRID_WIDTH_U) begin
                    neighbor_link_internal #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .MAX_WEIGHT(MAX_WEIGHT)
                    ) neighbor_link_UD (
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j, k-1).neighbor_fully_grown[`NEIGHBOR_IDX_UP]),
                        .a_increase(`PU(i, j, k-1).neighbor_increase),
                        .b_increase(`PU(i, j, k).neighbor_increase),
                        .is_boundary(`PU(i, j, k-1).neighbor_is_boundary[`NEIGHBOR_IDX_UP]),
                        .a_is_error_in(`PU(i, j, k-1).neighbor_is_error[`NEIGHBOR_IDX_UP]),
                        .b_is_error_in(`PU(i, j, k).neighbor_is_error[`NEIGHBOR_IDX_DOWN]),
                        .is_error(is_error_out),
                        .a_input_data(`SLICE_VEC(`PU(i, j, k-1).output_data, `NEIGHBOR_IDX_UP, EXPOSED_DATA_SIZE)),
                        .b_input_data(`SLICE_VEC(`PU(i, j, k).output_data, `NEIGHBOR_IDX_DOWN, EXPOSED_DATA_SIZE)),
                        .a_output_data(`SLICE_VEC(`PU(i, j, k-1).input_data, `NEIGHBOR_IDX_UP, EXPOSED_DATA_SIZE)),
                        .b_output_data(`SLICE_VEC(`PU(i, j, k).input_data, `NEIGHBOR_IDX_DOWN, EXPOSED_DATA_SIZE)),
                        .weight_in(2),
                        .weight_out(),
                        .boundary_condition_in(0),
                        .boundary_condition_out(),
                        .is_error_systolic_in(is_error_systolic_in)
                    );

                    assign `PU(i, j, k).neighbor_fully_grown[`NEIGHBOR_IDX_DOWN] = `PU(i, j, k-1).neighbor_fully_grown[`NEIGHBOR_IDX_UP];
                    assign `PU(i, j, k).neighbor_is_boundary[`NEIGHBOR_IDX_DOWN] = `PU(i, j, k-1).neighbor_is_boundary[`NEIGHBOR_IDX_UP];
                end else begin
                    neighbor_link_internal #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH),
                        .MAX_WEIGHT(MAX_WEIGHT)
                    ) neighbor_link_UD(
                        .clk(clk),
                        .reset(reset),
                        .global_stage(global_stage),
                        .fully_grown(`PU(i, j, k-1).neighbor_fully_grown[`NEIGHBOR_IDX_UP]),
                        .a_increase(`PU(i, j, k-1).neighbor_increase),
                        .b_increase(),
                        .is_boundary(`PU(i, j, k-1).neighbor_is_boundary[`NEIGHBOR_IDX_UP]),
                        .a_is_error_in(`PU(i, j, k-1).neighbor_is_error[`NEIGHBOR_IDX_UP]),
                        .b_is_error_in(),
                        .is_error(),
                        .a_input_data(`SLICE_VEC(`PU(i, j, k-1).output_data, `NEIGHBOR_IDX_UP, EXPOSED_DATA_SIZE)),
                        .b_input_data(),
                        .a_output_data(`SLICE_VEC(`PU(i, j, k-1).input_data, `NEIGHBOR_IDX_UP, EXPOSED_DATA_SIZE)),
                        .b_output_data(),
                        .weight_in(2),
                        .weight_out(),
                        .boundary_condition_in(2),
                        .boundary_condition_out(),
                        .is_error_systolic_in(is_error_systolic_in)
                    );
                end
            end
        end
    end
    
endgenerate

generate
    for (k=0; k < GRID_WIDTH_U-1; k=k+1) begin: ns_k_extra
        for (i=1; i < GRID_WIDTH_X; i=i+1) begin: ns_i_extra
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ns_j_extra
                assign ns_k[k].ns_i[i].ns_j[j].is_error_systolic_in = ns_k[k+1].ns_i[i].ns_j[j].is_error_out;
            end
        end
    end

    for (k=0; k < GRID_WIDTH_U-1; k=k+1) begin: ew_k_extra
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ew_i_extra
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: ew_j_extra
                assign ew_k[k].ew_i[i].ew_j[j].is_error_systolic_in = ew_k[k+1].ew_i[i].ew_j[j].is_error_out;
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

    for (i=1; i < GRID_WIDTH_X; i=i+1) begin: ns_i_output
        for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ns_j_output
            assign `CORRECTION_NS(i,j) = ns_k[0].ns_i[i].ns_j[j].is_error_out;
        end
    end

    for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ew_i_output
        for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: ew_j_output
            assign `CORRECTION_EW(i,j) = ew_k[0].ew_i[i].ew_j[j].is_error_out;
        end
    end

    for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ud_i_output
        for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ud_j_output
            assign `CORRECTION_UD(i,j) = ud_k[0].ud_i[i].ud_j[j].is_error_out;
        end
    end

endgenerate

endmodule

