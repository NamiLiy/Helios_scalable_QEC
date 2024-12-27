`timescale 1ns / 1ps

module single_FPGA_decoding_graph_dynamic_rsc #(
    parameter MAX_WEIGHT = 2,
    parameter NUM_CONTEXTS = 4,
    parameter ACTUAL_D = 5,
    parameter FPGA_ID = 1,
    parameter FULL_LOGICAL_QUBITS_PER_DIM = 2,
    parameter MEASUREMENT_FUSION_ENABLED = 1
) (
    clk,
    reset,
    measurements,
    odd_clusters,
    roots,
    busy,
    global_stage,
    correction,

    artificial_boundary,
    fusion_boundary,
    reset_all_edges,

    east_border,
    west_border,
    north_border,
    south_border,

    update_artifical_border,
    continutation_from_top,
    context_stage

);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

localparam GRID_X_EXTRA = (FPGA_ID < 3) ? ((((ACTUAL_D + 1)>>2)<<1) + 1) : 0;
localparam GRID_Z_EXTRA = (FPGA_ID % 2 == 1) ? ((ACTUAL_D + 3)>>2) : 0;
localparam GRID_X_NORMAL = FULL_LOGICAL_QUBITS_PER_DIM * (ACTUAL_D + 1);
localparam GRID_Z_NORMAL = (FULL_LOGICAL_QUBITS_PER_DIM * (ACTUAL_D - 1) >> 1) + (FULL_LOGICAL_QUBITS_PER_DIM >> 1);
localparam GRID_WIDTH_X = GRID_X_NORMAL + GRID_X_EXTRA;
localparam GRID_WIDTH_Z = (GRID_Z_NORMAL + GRID_Z_EXTRA);
localparam GRID_WIDTH_U = ACTUAL_D*(MEASUREMENT_FUSION_ENABLED + 1);

localparam X_BIT_WIDTH = $clog2(GRID_WIDTH_X);
localparam Z_BIT_WIDTH = $clog2(GRID_WIDTH_Z);
localparam U_BIT_WIDTH = $clog2(GRID_WIDTH_U);
localparam ADDRESS_WIDTH = X_BIT_WIDTH + Z_BIT_WIDTH + U_BIT_WIDTH;
localparam ADDRESS_WIDTH_WITH_B = ADDRESS_WIDTH + 1;

localparam PHYSICAL_GRID_WIDTH_U = (GRID_WIDTH_U % NUM_CONTEXTS == 0) ? 
                                   (GRID_WIDTH_U / NUM_CONTEXTS) : 
                                   (GRID_WIDTH_U / NUM_CONTEXTS + 1);
localparam PU_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z; // This has some excess PUs keep in mind to ignore them
localparam PU_COUNT = PU_COUNT_PER_ROUND * PHYSICAL_GRID_WIDTH_U;
localparam NEIGHBOR_COUNT = 6;

localparam logical_qubits_in_j_dim = (FPGA_ID % 2 == 1) ? (FULL_LOGICAL_QUBITS_PER_DIM + 1) : FULL_LOGICAL_QUBITS_PER_DIM;
localparam logical_qubits_in_i_dim = (FPGA_ID < 3) ? (FULL_LOGICAL_QUBITS_PER_DIM + 1) : FULL_LOGICAL_QUBITS_PER_DIM;
localparam borders_in_j_dim = (logical_qubits_in_j_dim + 1)*logical_qubits_in_i_dim; // number of || border
localparam borders_in_i_dim = (logical_qubits_in_i_dim + 1)*logical_qubits_in_j_dim; // number of -- borders

// here we only consider the errors commited in this FPGA
localparam HOR_ERROR_COUNT = ACTUAL_D*ACTUAL_D*FULL_LOGICAL_QUBITS_PER_DIM*FULL_LOGICAL_QUBITS_PER_DIM;
localparam UD_ERROR_COUNT_PER_ROUND = GRID_X_NORMAL*GRID_Z_NORMAL; // This has some extra PEs in short rows. That has to be discarded
localparam CORRECTION_COUNT_PER_ROUND = HOR_ERROR_COUNT + UD_ERROR_COUNT_PER_ROUND;

localparam EXPOSED_DATA_SIZE = ADDRESS_WIDTH_WITH_B + 1 + 1 + 1;

localparam LINK_BIT_WIDTH = $clog2(MAX_WEIGHT + 1);
localparam HALF_CONTEXT = (NUM_CONTEXTS >> 1);
localparam CONTEXT_COUNTER_WIDTH = $clog2(NUM_CONTEXTS);

input clk;
input reset;
input [PU_COUNT_PER_ROUND-1:0] measurements;
input [STAGE_WIDTH-1:0] global_stage;

output [PU_COUNT - 1 : 0] odd_clusters;
output [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
output [PU_COUNT - 1 : 0] busy;
output [CORRECTION_COUNT_PER_ROUND - 1 : 0] correction;

input artificial_boundary; // this being 0 indicates that artificial boundary is removed
input [borders_in_j_dim + borders_in_i_dim - 1 : 0] fusion_boundary; // this is the boundary of the fusion
input reset_all_edges; // all edges are reset

localparam EW_BORDER_WIDTH = (GRID_WIDTH_X + 1) / 2;
localparam NS_BORDER_WIDTH = GRID_WIDTH_Z;

output [EW_BORDER_WIDTH-1:0] east_border;
input [EW_BORDER_WIDTH-1:0] west_border;
input [NS_BORDER_WIDTH-1:0] north_border;
output [NS_BORDER_WIDTH-1:0] south_border;

input update_artifical_border;
input continutation_from_top;
input [CONTEXT_COUNTER_WIDTH-1:0] context_stage;

genvar i;
genvar j;
genvar k;

//context_stage delayed
reg[CONTEXT_COUNTER_WIDTH -1:0] context_stage_delayed;
always@(posedge clk) begin
    if(reset) begin
        context_stage_delayed <= 0;
    end else begin
        context_stage_delayed <= context_stage;
    end
end

wire [PU_COUNT-1:0] measurement_debug;

`define INDEX(i, j, k) (i * GRID_WIDTH_Z + j + k * GRID_WIDTH_Z*GRID_WIDTH_X)
`define INDEX_PLANAR(i, j) (i * GRID_WIDTH_Z + j)
`define ADDRESS(i,j,k) ( (k<< (X_BIT_WIDTH + Z_BIT_WIDTH)) + (i<< Z_BIT_WIDTH) + j)
`define roots(i, j, k) roots[ADDRESS_WIDTH*(`INDEX(i, j, k)+1)-1:ADDRESS_WIDTH*`INDEX(i, j, k)]
`define odd_clusters(i, j, k) odd_clusters[`INDEX(i, j, k)]
`define busy(i, j, k) busy[`INDEX(i, j, k)]
`define PU(i, j, k) pu_k[k].pu_i[i].pu_j[j]
`define SPU(i, j, k) s_pu_i[i].s_pu_j[j].s_pu_k[k]
`define measurement_debug(i,j,k) measurement_debug[`INDEX(i, j, k)]

function IS_LONG_ROW;
    input integer i;
    begin
        IS_LONG_ROW = (((i%(2*(ACTUAL_D+1)))<(ACTUAL_D+1))==((i%2)==0)); // Example condition
    end
endfunction

localparam CONTEXTS_FOR_UPPER_SPU = (NUM_CONTEXTS > 2) ? NUM_CONTEXTS : 1;

generate
    for (k=PHYSICAL_GRID_WIDTH_U-1; k >= 0; k=k-1) begin: pu_k
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: pu_i
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: pu_j

                wire local_measurement;
                wire update_measurements_special;
                wire measurement_out;
                wire [NEIGHBOR_COUNT-1:0] neighbor_fully_grown;
                wire  neighbor_increase;
                wire [NEIGHBOR_COUNT-1:0] neighbor_is_boundary;
                wire [NEIGHBOR_COUNT-1:0] neighbor_is_error;

                wire [NEIGHBOR_COUNT*EXPOSED_DATA_SIZE-1:0] input_data;
                wire [NEIGHBOR_COUNT*EXPOSED_DATA_SIZE-1:0] output_data;

                wire odd;
                wire [ADDRESS_WIDTH-1 : 0] root;
                wire busy_PE;
                reg [ADDRESS_WIDTH_WITH_B-1:0] address_global;

                if(j == GRID_WIDTH_Z - 1 && (IS_LONG_ROW(i) == 1'b0) ) begin
                    assign `busy(i, j, k) = 1'b0;
                    assign `odd_clusters(i,j,k) = 1'b0;
                    assign root[Z_BIT_WIDTH-1:0] = j;
                    assign root[X_BIT_WIDTH+Z_BIT_WIDTH-1:Z_BIT_WIDTH] = i;
                    if(NUM_CONTEXTS <=2) begin
                        assign root [X_BIT_WIDTH+Z_BIT_WIDTH+U_BIT_WIDTH-1:X_BIT_WIDTH+Z_BIT_WIDTH] = (context_stage_delayed) ? (PHYSICAL_GRID_WIDTH_U - k - 1 + PHYSICAL_GRID_WIDTH_U) : (k);
                    end else begin
                        assign root [X_BIT_WIDTH+Z_BIT_WIDTH+U_BIT_WIDTH-1:X_BIT_WIDTH+Z_BIT_WIDTH] = context_stage_delayed;
                    end
                    assign `roots(i, j, k) = root[ADDRESS_WIDTH-1:0];
                    assign measurement_out = 1'b0;
                    assign `measurement_debug(i,j,k) = measurement_out;
                end else begin
                    

                    always@(*) begin
                        address_global[Z_BIT_WIDTH-1:0] = j;
                        address_global[X_BIT_WIDTH+Z_BIT_WIDTH-1:Z_BIT_WIDTH] = i;
                        address_global[ADDRESS_WIDTH_WITH_B-1:ADDRESS_WIDTH] = 1'b1;
                        if(NUM_CONTEXTS <= 2) begin
                            if(context_stage_delayed == 0) begin
                                address_global[X_BIT_WIDTH+Z_BIT_WIDTH+U_BIT_WIDTH-1:X_BIT_WIDTH+Z_BIT_WIDTH] = k;
                            end else begin
                                address_global[X_BIT_WIDTH+Z_BIT_WIDTH+U_BIT_WIDTH-1:X_BIT_WIDTH+Z_BIT_WIDTH] = PHYSICAL_GRID_WIDTH_U - k - 1 + PHYSICAL_GRID_WIDTH_U;
                            end
                        end else begin
                            address_global[X_BIT_WIDTH+Z_BIT_WIDTH+U_BIT_WIDTH-1:X_BIT_WIDTH+Z_BIT_WIDTH] = context_stage_delayed;
                        end
                    end

                    processing_unit #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH_WITH_B),
                        .NEIGHBOR_COUNT(NEIGHBOR_COUNT),
                        .NUM_CONTEXTS(NUM_CONTEXTS)
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
                        .input_address(address_global),

                        .odd(odd),
                        .root(root),
                        .busy(busy_PE),
                        .update_measurements_special(update_measurements_special)
                    );
                    assign `roots(i, j, k) = root[ADDRESS_WIDTH-1:0];
                    assign `busy(i, j, k) = busy_PE;
                    assign `odd_clusters(i,j,k) = odd;
                    assign `measurement_debug(i,j,k) = measurement_out;
                end
            end
        end
    end

    for (i=0; i < GRID_WIDTH_X; i=i+1) begin: s_pu_i
        for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: s_pu_j
            for (k=0; k < 2; k=k+1) begin: s_pu_k // For top and bottom support PEs
                wire [EXPOSED_DATA_SIZE-1:0] input_data;
                wire [EXPOSED_DATA_SIZE-1:0] output_data;
                wire local_context_switch;

                if(j == GRID_WIDTH_Z - 1 && (IS_LONG_ROW(i) == 1'b0) ) begin
                    // skip
                end else begin
                    if(NUM_CONTEXTS <= 2) begin // If there are only 2 contexts then all context switches are local context switches
                        assign local_context_switch = 1'b1;
                    end else if (k==1) begin
                        assign local_context_switch = 1'b0;
                    end
                    if(k==1) begin
                        support_processing_unit #(
                            .ADDRESS_WIDTH(ADDRESS_WIDTH_WITH_B),
                            //.NUM_CONTEXTS(NUM_CONTEXTS/2 + 1) // +1 is for ctx = d
                            .NUM_CONTEXTS(CONTEXTS_FOR_UPPER_SPU)
                        ) spu (
                            .clk(clk),
                            .reset(reset),
                            .global_stage(global_stage),
                            .input_data(input_data),
                            .output_data(output_data),
                            .do_not_store(local_context_switch)
                        );
                    end else begin
                        support_processing_unit #(
                            .ADDRESS_WIDTH(ADDRESS_WIDTH_WITH_B),
                            .NUM_CONTEXTS(1) // +1 is for ctx = d ??
                        ) spu (
                            .clk(clk),
                            .reset(reset),
                            .global_stage(global_stage),
                            .input_data(input_data),
                            .output_data(output_data),
                            .do_not_store(local_context_switch)
                        );
                    end
                end
            end
        end
    end
endgenerate
    

generate
    for (k=PHYSICAL_GRID_WIDTH_U-1; k >= 0; k=k-1) begin: pu_k_extra
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: pu_i_extra
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: pu_j_extra
                if(j == GRID_WIDTH_Z - 1 && (IS_LONG_ROW(i) == 1'b0) ) begin
                    //
                end else begin
                    if(FPGA_ID == 2) begin
                        if(k==PHYSICAL_GRID_WIDTH_U-1) begin
                            if(j==0 && (IS_LONG_ROW(i))) begin
                                assign `PU(i, j, k).local_measurement = west_border[i/2];
                            end else begin
                                assign `PU(i, j, k).local_measurement = measurements[`INDEX_PLANAR(i,j)];
                            end
                        end else begin
                            assign `PU(i, j, k).local_measurement = `PU(i, j, k+1).measurement_out;
                        end

                        if(j==0 && (IS_LONG_ROW(i))) begin
                            assign `PU(i, j, k).update_measurements_special = update_artifical_border;
                        end else begin
                            assign `PU(i, j, k).update_measurements_special = 1'b0;
                        end

                    end else if(FPGA_ID == 3) begin
                        if(k==PHYSICAL_GRID_WIDTH_U-1) begin
                            if(i==0) begin
                                assign `PU(i, j, k).local_measurement = north_border[j];
                            end else begin
                                assign `PU(i, j, k).local_measurement = measurements[`INDEX_PLANAR(i,j)];
                            end
                        end else begin
                            assign `PU(i, j, k).local_measurement = `PU(i, j, k+1).measurement_out;
                        end

                        if(i==0) begin
                            assign `PU(i, j, k).update_measurements_special = update_artifical_border;
                        end else begin
                            assign `PU(i, j, k).update_measurements_special = 1'b0;
                        end

                    end else if(FPGA_ID == 4) begin
                        if(k==PHYSICAL_GRID_WIDTH_U-1) begin
                            if(j==0 && (IS_LONG_ROW(i))) begin
                                assign `PU(i, j, k).local_measurement = west_border[i/2];
                            end else if(i==0) begin
                                assign `PU(i, j, k).local_measurement = north_border[j];
                            end else begin
                                assign `PU(i, j, k).local_measurement = measurements[`INDEX_PLANAR(i,j)];
                            end
                        end else begin
                            assign `PU(i, j, k).local_measurement = `PU(i, j, k+1).measurement_out;
                        end

                        if(j==0 && (IS_LONG_ROW(i))) begin
                            assign `PU(i, j, k).update_measurements_special = update_artifical_border;
                        end else if(i==0) begin
                            assign `PU(i, j, k).update_measurements_special = update_artifical_border;
                        end else begin
                            assign `PU(i, j, k).update_measurements_special = 1'b0;
                        end

                    end else begin //FPGA_ID ==1
                        if(k==PHYSICAL_GRID_WIDTH_U-1) begin
                            assign `PU(i, j, k).local_measurement = measurements[`INDEX_PLANAR(i,j)];
                        end else begin
                            assign `PU(i, j, k).local_measurement = `PU(i, j, k+1).measurement_out;
                        end
                        assign `PU(i, j, k).update_measurements_special = 1'b0;
                    end
                end
            end
        end
    end

endgenerate

`define SLICE_ADDRESS_VEC(vec, idx) (vec[(((idx)+1)*ADDRESS_WIDTH)-1:(idx)*ADDRESS_WIDTH])


`define CORR_INDEX_HOR(i, j) (((i / (ACTUAL_D+1))*ACTUAL_D + (i%(ACTUAL_D + 1)) - 1)*FULL_LOGICAL_QUBITS_PER_DIM*ACTUAL_D + j)
`define CORR_INDEX_UD(i, j) (i*GRID_Z_NORMAL + j + HOR_ERROR_COUNT)


`define CORRECTION_HOR(i, j) correction[`CORR_INDEX_HOR(i, j)]
`define CORRECTION_UD(i, j) correction[`CORR_INDEX_UD(i, j)]

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

`define NEIGHBOR_LINK_INTERNAL_0(ai, aj, ak, bi, bj, bk, adirection, bdirection, type, num_contexts, reset_edge_local) \
    wire is_boundary; \
    neighbor_link_internal #( \
        .ADDRESS_WIDTH(ADDRESS_WIDTH_WITH_B), \
        .MAX_WEIGHT(2), \
        .NUM_CONTEXTS(num_contexts), \
        .STORE_EXTERNAL(0) \
    ) neighbor_link ( \
        .clk(clk), \
        .reset(reset), \
        .global_stage(global_stage), \
        .fully_grown(fully_grown_data), \
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
        .weight_in(2), \
        .weight_out(), \
        .do_not_store(local_context_switch), \
        .boundary_condition_in(type), \
        .boundary_condition_out(), \
        .is_error_systolic_in(is_error_systolic_in), \
        .reset_edge(reset_edge_local) \
    );\
    assign `PU(ai, aj, ak).neighbor_fully_grown[adirection] = fully_grown_data;\
    assign `PU(bi, bj, bk).neighbor_fully_grown[bdirection] = fully_grown_data;\
    assign `PU(ai, aj, ak).neighbor_is_boundary[adirection] = is_boundary;\
    assign `PU(bi, bj, bk).neighbor_is_boundary[bdirection] = is_boundary;

`define NEIGHBOR_LINK_INTERNAL_SINGLE(ai, aj, ak, adirection, type, num_contexts, reset_edge_local) \
    neighbor_link_internal #( \
        .ADDRESS_WIDTH(ADDRESS_WIDTH_WITH_B), \
        .MAX_WEIGHT(2), \
        .NUM_CONTEXTS(num_contexts), \
        .STORE_EXTERNAL(0) \
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
        .weight_in(2), \
        .weight_out(), \
        .do_not_store(local_context_switch), \
        .boundary_condition_in(type), \
        .boundary_condition_out(), \
        .is_error_systolic_in(is_error_systolic_in), \
        .reset_edge(reset_edge_local) \
    );

`define NEIGHBOR_LINK_INTERNAL_SUPPORT(ai, aj, ak, bi, bj, bk, adirection, type, num_contexts, reset_edge_local, store_external) \
    wire is_boundary; \
    neighbor_link_internal #( \
        .ADDRESS_WIDTH(ADDRESS_WIDTH_WITH_B), \
        .MAX_WEIGHT(2), \
        .NUM_CONTEXTS(num_contexts), \
        .STORE_EXTERNAL(store_external) \
    ) neighbor_link ( \
        .clk(clk), \
        .reset(reset), \
        .global_stage(global_stage), \
        .fully_grown(fully_grown_data), \
        .a_increase(`PU(ai, aj, ak).neighbor_increase), \
        .b_increase(0), \
        .is_boundary(is_boundary), \
        .a_is_error_in(`PU(ai, aj, ak).neighbor_is_error[adirection]), \
        .b_is_error_in(0), \
        .is_error(is_error_out), \
        .a_input_data(`SLICE_VEC(`PU(ai, aj, ak).output_data, adirection, EXPOSED_DATA_SIZE)), \
        .b_input_data(`SPU(bi, bj, bk).output_data), \
        .a_output_data(`SLICE_VEC(`PU(ai, aj, ak).input_data, adirection, EXPOSED_DATA_SIZE)), \
        .b_output_data(), \
        .weight_in(2), \
        .weight_out(), \
        .do_not_store(local_context_switch), \
        .boundary_condition_in(type), \
        .boundary_condition_out(), \
        .is_error_systolic_in(0), \
        .reset_edge(reset_edge_local), \
        .context_input(context_extra_in), \
        .context_output(context_extra_out) \
    );\
        assign `PU(ai, aj, ak).neighbor_fully_grown[adirection] = fully_grown_data;\
        assign `PU(ai, aj, ak).neighbor_is_boundary[adirection] = is_boundary;


`define logic_boundary_index(i,j,horizontal_boundary)\
        (horizontal_boundary ? \
        ((i / (ACTUAL_D+1))*(logical_qubits_in_j_dim) + (j / ACTUAL_D) + borders_in_j_dim) : \
        (((i / (ACTUAL_D+1)))*(logical_qubits_in_j_dim + 1) + ((j+1) / ACTUAL_D)))


generate
    // Generate Horizontal neighbors
    for (k=0; k < PHYSICAL_GRID_WIDTH_U; k=k+1) begin: hor_k
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: hor_i
            for (j=0; j < (GRID_WIDTH_Z*2); j=j+1) begin: hor_j
                wire is_error_systolic_in;
                wire is_error_out;
                wire [LINK_BIT_WIDTH-1:0] weight_in;
                wire fully_grown_data;
                wire local_context_switch;
                assign local_context_switch = 1'b0;

                wire reset_edge_local;
                assign reset_edge_local = (global_stage == STAGE_MEASUREMENT_LOADING) ? 1'b1 : 1'b0;
                
                reg [3:0] type_for_boundary_links;

                always@(*) begin 

                    // first handle the lattice boundaries
                    if(i==0) begin // First row
                        type_for_boundary_links = `NO_EDGE; // This never exists in all 4 FPGAs
                    end else if(i==GRID_WIDTH_X) begin 
                        type_for_boundary_links = (FPGA_ID <= 2 ? `BOUNDARY_EDGE : `NO_EDGE); 
                    end else if (i < GRID_WIDTH_X && i > 0 &&  j==0 && ((i%(ACTUAL_D + 1))!=0)) begin //Leftmost column. North ones go upwards and are discarded for equivalent going down ones
                        type_for_boundary_links = (((FPGA_ID % 2) == 1) ? `BOUNDARY_EDGE : `NO_EDGE);
                    end else if(i < GRID_WIDTH_X && i > 0 && j == 2*GRID_WIDTH_Z -1 && ((i%(ACTUAL_D + 1))!=0)) begin // Last element of even rows
                        type_for_boundary_links = `BOUNDARY_EDGE; //always a boundary
                    
                    // then artificial boundaries
                    // horizontal (h=1) --
                    end else if((i%(ACTUAL_D+1))==0 && j > 0) begin
                        if((i/(ACTUAL_D+1))%2 == 1) begin //These rows start with an offset
                            if(j%2 == 0) begin
                                type_for_boundary_links = artificial_boundary ? `FUSION_EDGE : (fusion_boundary[`logic_boundary_index(i,j,1)] ? `NORMAL_EDGE : `NO_EDGE);
                            end
                        end else begin
                            if(j%2 == 1) begin
                                type_for_boundary_links = artificial_boundary ? `FUSION_EDGE : (fusion_boundary[`logic_boundary_index(i,j,1)] ? `NORMAL_EDGE : `NO_EDGE);
                            end
                        end
                    // vertical (h=0) | |
                    end else if(j > 0 && j< 2*GRID_WIDTH_Z - 1 && ((j%ACTUAL_D == (ACTUAL_D - 1)) || (j%ACTUAL_D == 0))) begin
                        // vertical (h=0) | |
                        type_for_boundary_links = artificial_boundary ? `FUSION_EDGE : (fusion_boundary[`logic_boundary_index(i,j,0)] ? `NORMAL_EDGE : `FUSION_EDGE); // This is the vertical border row. When Fusion is on it is                     
                    // then fully internal nodes
                    end else  begin
                        type_for_boundary_links = `NORMAL_EDGE; //  Internal
                    end
               end

                if(i==0) begin // First row
                    if(j%2 ==0) begin // \
                        `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j/2, k, `NEIGHBOR_IDX_NW, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local)
                    end else begin
                        `NEIGHBOR_LINK_INTERNAL_SINGLE(i, (j-1)/2, k, `NEIGHBOR_IDX_NE, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local)
                    end
                end else if(i==GRID_WIDTH_X) begin  // Last row
                    if(j%2 ==0) begin // /
                        `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j/2, k, `NEIGHBOR_IDX_SW, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local)
                    end else begin
                        `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, (j-1)/2, k, `NEIGHBOR_IDX_SE, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local)
                    end
                end else if (i < GRID_WIDTH_X && i > 0 &&  j==0 && ((i%(ACTUAL_D + 1))!=0)) begin //Left column
                    if (IS_LONG_ROW(i)) begin // \
                        `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j, k, `NEIGHBOR_IDX_NW, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local)
                    end else begin // /
                        `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j, k, `NEIGHBOR_IDX_SW, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local)
                    end
                end else if(i < GRID_WIDTH_X && i > 0 && j == 2*GRID_WIDTH_Z -1 && ((i%(ACTUAL_D + 1))!=0)) begin // Last element of even rows
                    if (IS_LONG_ROW(i)) begin // /
                        `NEIGHBOR_LINK_INTERNAL_SINGLE(i, (j-1)/2, k, `NEIGHBOR_IDX_NE, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local)
                    end else begin // /
                        `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, (j-1)/2, k, `NEIGHBOR_IDX_SE, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local)
                    end
                
                // then artificial horizontal boundaries
                // horizontal (h=1) --s
                end else if((i%(ACTUAL_D+1))==0) begin
                    if((i/(ACTUAL_D+1))%2 == 1) begin //These rows start with an offset
                        if(j%2 == 0 && j > 0) begin // actual fusion edge
                            `NEIGHBOR_LINK_INTERNAL_0(i-1, (j/2)-1, k, i, (j/2)-1, k, `NEIGHBOR_IDX_SE, `NEIGHBOR_IDX_NE, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local)
                        end else if (j%2 == 1 && j < 2*GRID_WIDTH_Z - 1) begin // fake edge to missing indice
                            `NEIGHBOR_LINK_INTERNAL_0(i-1, (j-1)/2, k, i, (j-1)/2, k, `NEIGHBOR_IDX_SW, `NEIGHBOR_IDX_NW, `NO_EDGE, NUM_CONTEXTS, reset_edge_local)
                        end
                    end else begin
                        if(j%2 == 1) begin // actual fusion edge
                            `NEIGHBOR_LINK_INTERNAL_0(i-1, (j-1)/2, k, i, (j-1)/2, k, `NEIGHBOR_IDX_SE, `NEIGHBOR_IDX_NE, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local)
                        end else begin // fake edge to missing indice
                            `NEIGHBOR_LINK_INTERNAL_0(i-1, j/2, k, i, j/2, k, `NEIGHBOR_IDX_SW, `NEIGHBOR_IDX_NW, `NO_EDGE, NUM_CONTEXTS, reset_edge_local)
                        end
                    end
                // Now all the rest inclduing vertical boundaries ||
                end else  begin
                    if(IS_LONG_ROW(i)) begin // these lines start with \
                        if(j%2 == 0) begin // \
                            `NEIGHBOR_LINK_INTERNAL_0(i-1, j/2 - 1, k, i, j/2, k, `NEIGHBOR_IDX_SE, `NEIGHBOR_IDX_NW, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local)
                        end else begin // /
                            `NEIGHBOR_LINK_INTERNAL_0(i-1, (j-1)/2, k, i, (j-1)/2, k, `NEIGHBOR_IDX_SW, `NEIGHBOR_IDX_NE, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local)
                        end
                    end else begin // / these lines start with /
                        if(j%2 == 0) begin // /
                            `NEIGHBOR_LINK_INTERNAL_0(i-1, j/2 , k, i, j/2 - 1, k, `NEIGHBOR_IDX_SW, `NEIGHBOR_IDX_NE, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local)
                        end else begin // \
                            `NEIGHBOR_LINK_INTERNAL_0(i-1, (j-1)/2, k, i, (j-1)/2, k, `NEIGHBOR_IDX_SE, `NEIGHBOR_IDX_NW, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local)
                        end
                    end
                end
            end
        end
    end


    // Generate UP DOWN link
    for (k=0; k <= PHYSICAL_GRID_WIDTH_U; k=k+1) begin: ud_k
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ud_i
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ud_j
                wire is_error_systolic_in;
                wire is_error_out;
                wire [LINK_BIT_WIDTH-1:0] weight_in;
                wire fully_grown_data;
                reg reset_edge_local;
                wire [2:0] context_extra_in;
                wire [2:0] context_extra_out;
                wire local_context_switch;

                if(j == GRID_WIDTH_Z - 1 && (IS_LONG_ROW(i) == 1'b0) ) begin
                    // 
                end else begin

                    reg [1:0] type_for_boundary_links;

                    

                    always@(*) begin
                        if(k==PHYSICAL_GRID_WIDTH_U) begin
                            reset_edge_local = reset_all_edges;
                        end else begin
                            reset_edge_local = (reset_all_edges || global_stage == STAGE_MEASUREMENT_LOADING) ? 1'b1 : 1'b0;
                        end
                    end
                    
                    assign weight_in = `WEIGHT_UD(i,j);

                    
                    if(NUM_CONTEXTS <=2) begin
                        if(k==0) begin
                            assign local_context_switch = ~continutation_from_top; 
                        end else begin //k==PHYSICAL_GRID_WIDTH_U
                            assign local_context_switch = continutation_from_top; // 0 1 2 3 4 5
                        end

                        always@(*) begin 
                            if(k==0) begin
                                if(continutation_from_top || artificial_boundary) begin // 0 1 2 3 4 5
                                    type_for_boundary_links = 2'b11; // Boundary
                                end else begin // 3 4 5 0 1 2
                                    type_for_boundary_links = 2'b00; // Internal
                                end
                            end else if(k==PHYSICAL_GRID_WIDTH_U) begin
                                if(~continutation_from_top || artificial_boundary) begin // 3 4 5 0 1 2
                                    type_for_boundary_links = 2'b11; // Boundary
                                end else begin // 0 1 2 3 4 5
                                    type_for_boundary_links = 2'b00; // Internal
                                end
                            end else begin
                                type_for_boundary_links = 2'b00; //  Internal
                            end
                        end
                    end else begin
                        assign local_context_switch = 1'b0;
                        always@(*) begin
                            if(k==0) begin
                                if((continutation_from_top || artificial_boundary) && context_stage == 0) begin
                                    type_for_boundary_links = 2'b11; // Boundary
                                end else if((~continutation_from_top || artificial_boundary) && context_stage == HALF_CONTEXT) begin
                                    type_for_boundary_links = 2'b11; // Internal
                                end else begin
                                    type_for_boundary_links = 2'b00; // Internal
                                end
                            end else if(k==PHYSICAL_GRID_WIDTH_U) begin
                                if((~continutation_from_top || artificial_boundary) && context_stage == HALF_CONTEXT-1) begin
                                    type_for_boundary_links = 2'b11; // Boundary
                                end else if((continutation_from_top || artificial_boundary) && context_stage == NUM_CONTEXTS-1) begin
                                    type_for_boundary_links = 2'b11; // Internal
                                end else begin
                                    type_for_boundary_links = 2'b00; // Internal
                                end
                            end else begin
                                type_for_boundary_links = 2'b00; //  Internal
                            end
                        end
                    end
                    if(NUM_CONTEXTS <=2) begin
                        if(k==0) begin
                            // `NEIGHBOR_LINK_INTERNAL_SUPPORT(i, j, k, i,j,0, `NEIGHBOR_IDX_DOWN, type_for_boundary_links, NUM_CONTEXTS / 2 + 1) //+1 is only for d=ctx
                            `NEIGHBOR_LINK_INTERNAL_SUPPORT(i, j, k, i,j,0, `NEIGHBOR_IDX_DOWN, type_for_boundary_links, 2, reset_edge_local, 0)
                        end else if(k==PHYSICAL_GRID_WIDTH_U) begin
                            // `NEIGHBOR_LINK_INTERNAL_SUPPORT(i, j, k-1, i,j,1, `NEIGHBOR_IDX_UP, type_for_boundary_links, NUM_CONTEXTS / 2 + 1) //+1 is for d=ctx
                            `NEIGHBOR_LINK_INTERNAL_SUPPORT(i, j, k-1, i,j,1, `NEIGHBOR_IDX_UP, type_for_boundary_links, 2, reset_edge_local, 0) //+1 is for d=ctx
                        end else if (k < PHYSICAL_GRID_WIDTH_U) begin
                            `NEIGHBOR_LINK_INTERNAL_0(i, j, k-1, i, j, k, `NEIGHBOR_IDX_UP, `NEIGHBOR_IDX_DOWN, 3'b00, 2, reset_edge_local)
                        end
                    end else begin
                        if(k==0) begin
                            `NEIGHBOR_LINK_INTERNAL_SUPPORT(i, j, k, i,j,0, `NEIGHBOR_IDX_DOWN, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local, 1) //+1 is only for d=ctx
                        end else if(k==PHYSICAL_GRID_WIDTH_U) begin
                            `NEIGHBOR_LINK_INTERNAL_SUPPORT(i, j, k-1, i,j,1, `NEIGHBOR_IDX_UP, type_for_boundary_links, NUM_CONTEXTS, reset_edge_local, 2) //+1 is for d=ctx
                        end else if (k < PHYSICAL_GRID_WIDTH_U) begin
                            `NEIGHBOR_LINK_INTERNAL_0(i, j, k-1, i, j, k, `NEIGHBOR_IDX_UP, `NEIGHBOR_IDX_DOWN, 3'b00, NUM_CONTEXTS, reset_edge_local) // Doesn't exist
                        end
                    end
                end
            end
        end
    end
    
endgenerate

generate
    for (k=0; k < PHYSICAL_GRID_WIDTH_U-1; k=k+1) begin: hor_k_extra
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: hor_i_extra
            for (j=0; j < (GRID_WIDTH_Z*2); j=j+1) begin: hor_j_extra
                // if(i> 0 && i < GRID_WIDTH_X && (i%(ACTUAL_D+1)) == 0) begin //The -- merge rows
                //     // short rows all except first and last edges. They don't exist any way
                //     if(((i/(ACTUAL_D + 1))%2 ==1) && j > 0 && j < 2*GRID_WIDTH_Z - 1) begin
                //         assign hor_k[k].hor_i[i].hor_j[j].is_error_systolic_in = hor_k[k+1].hor_i[i].hor_j[j].is_error_out;
                //     end else if ((i/(ACTUAL_D + 1))%2 ==1)  begin
                //         assign hor_k[k].hor_i[i].hor_j[j].is_error_systolic_in = hor_k[k+1].hor_i[i].hor_j[j].is_error_out;
                //     end
                // end else begin
                //     assign hor_k[k].hor_i[i].hor_j[j].is_error_systolic_in = hor_k[k+1].hor_i[i].hor_j[j].is_error_out;
                // end
                assign hor_k[k].hor_i[i].hor_j[j].is_error_systolic_in = hor_k[k+1].hor_i[i].hor_j[j].is_error_out;
            end
        end
    end

    for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: hor_i_extra_2
        for (j=0; j < (GRID_WIDTH_Z*2); j=j+1) begin: hor_j_extra_2
            assign hor_k[PHYSICAL_GRID_WIDTH_U-1].hor_i[i].hor_j[j].is_error_systolic_in = 0;
        end
    end

    for (k=0; k < PHYSICAL_GRID_WIDTH_U-1; k=k+1) begin: ud_k_extra
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ud_i_extra
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ud_j_extra
                if(j == GRID_WIDTH_Z - 1 && (IS_LONG_ROW(i) == 1'b0) ) begin
                    //
                end else begin
                    assign ud_k[k].ud_i[i].ud_j[j].is_error_systolic_in = ud_k[k+1].ud_i[i].ud_j[j].is_error_out;
                end
            end
        end
    end

    for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ud_i_extra_2
        for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ud_j_extra_2
            if(j == GRID_WIDTH_Z - 1 && (IS_LONG_ROW(i) == 1'b0) ) begin
                //
            end else begin
                assign ud_k[PHYSICAL_GRID_WIDTH_U-1].ud_i[i].ud_j[j].is_error_systolic_in = 0;
                assign ud_k[PHYSICAL_GRID_WIDTH_U].ud_i[i].ud_j[j].is_error_systolic_in = 0;
            end
        end
    end
    

    for (i=1; i < (ACTUAL_D+1)*FULL_LOGICAL_QUBITS_PER_DIM; i=i+1) begin: hor_i_output
        for (j=0; j < ACTUAL_D*FULL_LOGICAL_QUBITS_PER_DIM; j=j+1) begin: hor_j_output
            if(i%(ACTUAL_D+1) == 0) begin
                // 
            end else begin
                assign `CORRECTION_HOR(i,j) = hor_k[0].hor_i[i].hor_j[j].is_error_out;
            end
        end
    end

    for (i=0; i < GRID_X_NORMAL; i=i+1) begin: ud_i_output
        for (j=0; j < GRID_Z_NORMAL; j=j+1) begin: ud_j_output
            // The edge does not exist but the array has a space for that. So we send 0. the space is for easy indexing from row column
            if(j == GRID_Z_NORMAL - 1 && (IS_LONG_ROW(i) == 1'b0) ) begin
                assign `CORRECTION_UD(i,j) = 1'b0;
            end else begin
                assign `CORRECTION_UD(i,j) = ud_k[0].ud_i[i].ud_j[j].is_error_out;
            end
        end
    end

    if(NUM_CONTEXTS > 2) begin
        for(i=0; i<GRID_WIDTH_X; i=i+1) begin: ud_i_output_extra
            for(j=0; j<GRID_WIDTH_Z; j=j+1) begin: ud_j_output_extra
                assign ud_k[0].ud_i[i].ud_j[j].context_extra_in = ud_k[1].ud_i[i].ud_j[j].context_extra_out;
                assign ud_k[1].ud_i[i].ud_j[j].context_extra_in = ud_k[0].ud_i[i].ud_j[j].context_extra_out;
            end
        end
    end

    /*for (k=0; k < PHYSICAL_GRID_WIDTH_U; k=k+1) begin: ns_k_weight
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

    for (k=0; k < PHYSICAL_GRID_WIDTH_U; k=k+1) begin: ew_k_weight
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

    for (k=0; k <= PHYSICAL_GRID_WIDTH_U; k=k+1) begin: ud_k_weight
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ud_i_weight
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ud_j_weight
                if(k < PHYSICAL_GRID_WIDTH_U) begin
                    assign ud_k[k].ud_i[i].ud_j[j].weight_in = `WEIGHT_UD(i,j);
                end else begin // Fake edges
                    assign ud_k[k].ud_i[i].ud_j[j].weight_in = 2;
                end
            end
        end
    end*/


    for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ud_i_support
        for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ud_j_support
            if(j == GRID_WIDTH_Z - 1 && (IS_LONG_ROW(i) == 1'b0) ) begin
                // 
            end else begin
                // assign ud_k[PHYSICAL_GRID_WIDTH_U].ud_i[i].ud_j[j].fully_grown_data = ud_k[PHYSICAL_GRID_WIDTH_U-1].ud_i[i].ud_j[j].fully_grown_data;
                assign s_pu_i[i].s_pu_j[j].s_pu_k[1].input_data = `SLICE_VEC(`PU(i,j,PHYSICAL_GRID_WIDTH_U-1).output_data, `NEIGHBOR_IDX_UP, EXPOSED_DATA_SIZE);
                // assign `SLICE_VEC(`PU(i, j, PHYSICAL_GRID_WIDTH_U-1).input_data, `NEIGHBOR_IDX_UP, EXPOSED_DATA_SIZE) = s_pu_i[i].s_pu_j[j].output_data;
                // assign pu_k[PHYSICAL_GRID_WIDTH_U-1].pu_i[i].pu_j[j].input_data[5*EXPOSED_DATA_SIZE +: EXPOSED_DATA_SIZE] = s_pu_i[i].s_pu_j[j].s_pu_k[1].output_data;
                // assign pu_k[PHYSICAL_GRID_WIDTH_U-1].pu_i[i].pu_j[j].neighbor_is_boundary[5] = 1'b0;

                assign s_pu_i[i].s_pu_j[j].s_pu_k[0].input_data = `SLICE_VEC(`PU(i,j,0).output_data, `NEIGHBOR_IDX_DOWN, EXPOSED_DATA_SIZE);
                // assign `SLICE_VEC(`PU(i, j, PHYSICAL_GRID_WIDTH_U-1).input_data, `NEIGHBOR_IDX_UP, EXPOSED_DATA_SIZE) = s_pu_i[i].s_pu_j[j].output_data;
                // assign pu_k[0].pu_i[i].pu_j[j].input_data[4*EXPOSED_DATA_SIZE +: EXPOSED_DATA_SIZE] = s_pu_i[i].s_pu_j[j].s_pu_k[0].output_data;
                // if(context_stage_delayed %2 == 0) begin
                //     assign pu_k[0].pu_i[i].pu_j[j].neighbor_is_boundary[4] = 1'b0;
                // end else begin
                //     assign pu_k[0].pu_i[i].pu_j[j].neighbor_is_boundary[4] = 1'b1;
                // end
                // assign pu_k[0].pu_i[i].pu_j[j].neighbor_is_boundary[4] = 1'b0;
            end
        end
    end

    for(i=0; i < GRID_WIDTH_X; i=i+1) begin: east_border_loop
        if(FPGA_ID%2 == 1) begin
            if(IS_LONG_ROW(i)) begin
                assign east_border[i/2] = (pu_k[0].pu_i[i].pu_j[GRID_Z_NORMAL].measurement_out)^
                                            hor_k[0].hor_i[i].hor_j[ACTUAL_D*FULL_LOGICAL_QUBITS_PER_DIM].is_error_out^
                                            hor_k[0].hor_i[i+1].hor_j[ACTUAL_D*FULL_LOGICAL_QUBITS_PER_DIM].is_error_out;
            end
        end
    end
                            

    for(j=0; j < GRID_WIDTH_Z; j = j+1) begin: south_border_loop
        if(FPGA_ID < 3) begin
            assign south_border[j] = pu_k[0].pu_i[GRID_X_NORMAL].pu_j[j].measurement_out^
                                    hor_k[0].hor_i[GRID_X_NORMAL].hor_j[j*2].is_error_out^
                                    hor_k[0].hor_i[GRID_X_NORMAL].hor_j[j*2+1].is_error_out;
        end
    end


endgenerate

endmodule

