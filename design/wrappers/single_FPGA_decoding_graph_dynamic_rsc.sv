`timescale 1ns / 1ps

module single_FPGA_decoding_graph_dynamic_rsc #(
    parameter GRID_WIDTH_X = 4,
    parameter GRID_WIDTH_Z = 1,
    parameter GRID_WIDTH_U = 3,
    parameter MAX_WEIGHT = 2,
    parameter NUM_CONTEXTS = 4,
    parameter NUM_FPGAS = 5 
) (
    clk,
    reset,
    measurements,
    odd_clusters,
    roots,
    busy,
    global_stage,
    correction,
    FPGA_ID,

    border_output_data,
    border_output_valid,
    border_output_ready,

    border_input_data,
    border_input_valid,
    border_input_ready,

    border_continous

);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

localparam X_BIT_WIDTH = $clog2(GRID_WIDTH_X);
localparam Z_BIT_WIDTH = $clog2(GRID_WIDTH_Z);
localparam U_BIT_WIDTH = $clog2(GRID_WIDTH_U);
localparam FPGA_BIT_WIDTH = $clog2(NUM_FPGAS);
localparam ADDRESS_WIDTH = X_BIT_WIDTH + Z_BIT_WIDTH + U_BIT_WIDTH + FPGA_BIT_WIDTH;
localparam ADDRESS_WIDTH_WITH_B = ADDRESS_WIDTH + 1;

localparam PHYSICAL_GRID_WIDTH_U = (GRID_WIDTH_U % NUM_CONTEXTS == 0) ? 
                                   (GRID_WIDTH_U / NUM_CONTEXTS) : 
                                   (GRID_WIDTH_U / NUM_CONTEXTS + 1);
localparam PU_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam PU_COUNT = PU_COUNT_PER_ROUND * PHYSICAL_GRID_WIDTH_U;
localparam NEIGHBOR_COUNT = 6;

localparam NS_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z;
localparam EW_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z + 1;
localparam UD_ERROR_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam CORRECTION_COUNT_PER_ROUND = NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND + UD_ERROR_COUNT_PER_ROUND;
localparam EXPOSED_DATA_SIZE = ADDRESS_WIDTH_WITH_B + 1 + 1 + 1;
localparam FPGA_FIFO_SIZE = EXPOSED_DATA_SIZE + 1;
localparam FPGA_FIFO_COUNT = 2*GRID_WIDTH_Z - 1;

localparam LINK_BIT_WIDTH = $clog2(MAX_WEIGHT + 1);

input clk;
input reset;
input [PU_COUNT_PER_ROUND-1:0] measurements;
input [STAGE_WIDTH-1:0] global_stage;

output [PU_COUNT - 1 : 0] odd_clusters;
output [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
output [PU_COUNT - 1 : 0] busy;
output [CORRECTION_COUNT_PER_ROUND - 1 : 0] correction;

input [FPGA_BIT_WIDTH-1:0] FPGA_ID;

output [2*FPGA_FIFO_SIZE*FPGA_FIFO_COUNT-1:0] border_output_data;
output [2*FPGA_FIFO_COUNT-1:0] border_output_valid;
input [2*FPGA_FIFO_COUNT-1:0] border_output_ready;

input [2*FPGA_FIFO_SIZE*FPGA_FIFO_COUNT-1:0] border_input_data;
input [2*FPGA_FIFO_COUNT-1:0] border_input_valid;
output [2*FPGA_FIFO_COUNT-1:0] border_input_ready;

input[1:0] border_continous;

genvar i;
genvar j;
genvar k;

//logic to calulate the context_stage
reg[$clog2(NUM_CONTEXTS):0] context_stage;
always@(posedge clk) begin
    if(reset) begin
        context_stage <= 0;
    end else begin
        if (global_stage == STAGE_WRITE_TO_MEM) begin
            if(context_stage < NUM_CONTEXTS -1) begin
                context_stage <= context_stage + 1;
            end else begin
                context_stage <= 0;
            end
        end
    end
end

//context_stage delayed
reg[$clog2(NUM_CONTEXTS):0] context_stage_delayed;
always@(posedge clk) begin
    if(reset) begin
        context_stage_delayed <= 0;
    end else begin
        context_stage_delayed <= context_stage;
    end
end

`define INDEX(i, j, k) (i * GRID_WIDTH_Z + j + k * GRID_WIDTH_Z*GRID_WIDTH_X)
`define INDEX_PLANAR(i, j) (i * GRID_WIDTH_Z + j)
`define ADDRESS(i,j,k) ( (k<< (X_BIT_WIDTH + Z_BIT_WIDTH)) + (i<< Z_BIT_WIDTH) + j)
`define roots(i, j, k) roots[ADDRESS_WIDTH*(`INDEX(i, j, k)+1)-1:ADDRESS_WIDTH*`INDEX(i, j, k)]
`define odd_clusters(i, j, k) odd_clusters[`INDEX(i, j, k)]
`define busy(i, j, k) busy[`INDEX(i, j, k)]
`define PU(i, j, k) pu_k[k].pu_i[i].pu_j[j]
`define SPU(i, j, k) s_pu_i[i].s_pu_j[j].s_pu_k[k]

generate
    for (k=PHYSICAL_GRID_WIDTH_U-1; k >= 0; k=k-1) begin: pu_k
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: pu_i
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: pu_j
                wire local_measurement;
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
                always@(*) begin
                    address_global[Z_BIT_WIDTH-1:0] = j;
                    address_global[X_BIT_WIDTH+Z_BIT_WIDTH-1:Z_BIT_WIDTH] = i;
                    address_global[ADDRESS_WIDTH - 1 : X_BIT_WIDTH+Z_BIT_WIDTH+U_BIT_WIDTH] = FPGA_ID;
                    address_global[ADDRESS_WIDTH_WITH_B-1:ADDRESS_WIDTH] = 1'b1;
                    if(context_stage_delayed%2 == 0) begin
                        address_global[ADDRESS_WIDTH-1:X_BIT_WIDTH+Z_BIT_WIDTH] = k + context_stage_delayed*PHYSICAL_GRID_WIDTH_U;
                    end else begin
                        address_global[ADDRESS_WIDTH-1:X_BIT_WIDTH+Z_BIT_WIDTH] = PHYSICAL_GRID_WIDTH_U - k - 1 + context_stage_delayed*PHYSICAL_GRID_WIDTH_U;
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
                    .busy(busy_PE)
                );
                // assign `roots(i, j, k) = root[ADDRESS_WIDTH-1:0];
                assign `busy(i, j, k) = busy_PE;
                assign `odd_clusters(i,j,k) = odd;
            end
        end
    end

    for (i=0; i < GRID_WIDTH_X; i=i+1) begin: s_pu_i
        for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: s_pu_j
            for (k=0; k < 2; k=k+1) begin: s_pu_k // For top and bottom support PEs
                wire [EXPOSED_DATA_SIZE-1:0] input_data;
                wire [EXPOSED_DATA_SIZE-1:0] output_data;
                wire local_context_switch;

                if (k==1)
                    // // This line is for d=27 ctx = 27
                    // assign local_context_switch = (context_stage_delayed %2 == 0 && context_stage_delayed < NUM_CONTEXTS - 1) ? 1'b1 : 1'b0;
                    //This line is for d=27 ctx = 4
                    assign local_context_switch = (context_stage_delayed %2 == 0 && context_stage_delayed < NUM_CONTEXTS - 1) ? 1'b1 : 1'b0;
                else if(k==0)
                    assign local_context_switch = (context_stage_delayed %2 == 1 && context_stage_delayed < NUM_CONTEXTS - 1) ? 1'b1 : 1'b0;
                else begin
                    assign local_context_switch = 1'b0;
                end
                if(k==1) begin
                    support_processing_unit #(
                        .ADDRESS_WIDTH(ADDRESS_WIDTH_WITH_B),
                        //.NUM_CONTEXTS(NUM_CONTEXTS/2 + 1) // +1 is for ctx = d
                        .NUM_CONTEXTS((NUM_CONTEXTS + 1)/2) 
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
                        .NUM_CONTEXTS(NUM_CONTEXTS/2 + 1) // +1 is for ctx = d
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
endgenerate
    

generate
    for (k=PHYSICAL_GRID_WIDTH_U-1; k >= 0; k=k-1) begin: pu_k_extra
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: pu_i_extra
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: pu_j_extra
                if(k==PHYSICAL_GRID_WIDTH_U-1) begin
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

`define SLICE_ADDRESS_VEC(vec, idx) (vec[(((idx)+1)*ADDRESS_WIDTH)-1:(idx)*ADDRESS_WIDTH])
`define SLICE_VEC(vec, idx, width) (vec[idx*width +: width])


`define CORR_INDEX_NS(i, j) ((i-1)*(GRID_WIDTH_Z) + j-1)
`define CORR_INDEX_EW(i, j) ((i-1)*(GRID_WIDTH_Z) + j + NS_ERROR_COUNT_PER_ROUND)
`define CORR_INDEX_UD(i, j) (i*GRID_WIDTH_Z + j + NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND)


`define CORRECTION_NS(i, j) correction[`CORR_INDEX_NS(i, j)]
`define CORRECTION_EW(i, j) correction[`CORR_INDEX_EW(i, j)]
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

`define NEIGHBOR_LINK_INTERNAL_0(ai, aj, ak, bi, bj, bk, adirection, bdirection, type, num_contexts) \
    wire is_boundary; \
    neighbor_link_internal #( \
        .ADDRESS_WIDTH(ADDRESS_WIDTH_WITH_B), \
        .MAX_WEIGHT(2), \
        .NUM_CONTEXTS(num_contexts) \
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
        .is_error_systolic_in(is_error_systolic_in) \
    );\
    assign `PU(ai, aj, ak).neighbor_fully_grown[adirection] = fully_grown_data;\
    assign `PU(bi, bj, bk).neighbor_fully_grown[bdirection] = fully_grown_data;\
    assign `PU(ai, aj, ak).neighbor_is_boundary[adirection] = is_boundary;\
    assign `PU(bi, bj, bk).neighbor_is_boundary[bdirection] = is_boundary;

`define NEIGHBOR_LINK_INTERNAL_SINGLE(ai, aj, ak, adirection, type, num_contexts) \
    neighbor_link_internal #( \
        .ADDRESS_WIDTH(ADDRESS_WIDTH_WITH_B), \
        .MAX_WEIGHT(2), \
        .NUM_CONTEXTS(num_contexts) \
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
        .is_error_systolic_in(is_error_systolic_in) \
    );

`define NEIGHBOR_LINK_INTERNAL_SUPPORT(ai, aj, ak, bi, bj, bk, adirection, type, num_contexts) \
    wire is_boundary; \
    neighbor_link_internal #( \
        .ADDRESS_WIDTH(ADDRESS_WIDTH_WITH_B), \
        .MAX_WEIGHT(2), \
        .NUM_CONTEXTS(num_contexts) \
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
        .is_error_systolic_in(0) \
    );\
        assign `PU(ai, aj, ak).neighbor_fully_grown[adirection] = fully_grown_data;\
        assign `PU(ai, aj, ak).neighbor_is_boundary[adirection] = is_boundary;

`define NEIGHBOR_LINK_EXTERNAL(ai, aj, ak, adirection, type, num_contexts, border, border_id, init_address) \
    neighbor_link_external #( \
        .ADDRESS_WIDTH(ADDRESS_WIDTH_WITH_B), \
        .MAX_WEIGHT(2), \
        .NUM_CONTEXTS(num_contexts) \
    ) neighbor_link ( \
        .clk(clk), \
        .reset(reset), \
        .global_stage(global_stage), \
        .fully_grown(`PU(ai, aj, ak).neighbor_fully_grown[adirection]), \
        .a_increase(`PU(ai, aj, ak).neighbor_increase), \
        .is_boundary(`PU(ai, aj, ak).neighbor_is_boundary[adirection]), \
        .a_is_error_in(`PU(ai, aj, ak).neighbor_is_error[adirection]), \
        .is_error(is_error_out), \
        .a_input_data(`SLICE_VEC(`PU(ai, aj, ak).output_data, adirection, EXPOSED_DATA_SIZE)), \
        .a_output_data(`SLICE_VEC(`PU(ai, aj, ak).input_data, adirection, EXPOSED_DATA_SIZE)), \
        .weight_in(2), \
        .weight_out(), \
        .do_not_store(local_context_switch), \
        .boundary_condition_in(type), \
        .boundary_condition_out(), \
        .is_error_systolic_in(is_error_systolic_in), \
        .fifo_output_data(`SLICE_VEC(border_output_data, border*FPGA_FIFO_COUNT +  border_id, FPGA_FIFO_SIZE)), \
        .fifo_output_valid(`SLICE_VEC(border_output_valid, border*FPGA_FIFO_COUNT +  border_id, 1)), \
        .fifo_output_ready(`SLICE_VEC(border_output_ready, border*FPGA_FIFO_COUNT +  border_id, 1)), \
        .fifo_input_data(`SLICE_VEC(border_input_data, border*FPGA_FIFO_COUNT +  border_id, FPGA_FIFO_SIZE)), \
        .fifo_input_valid(`SLICE_VEC(border_input_valid, border*FPGA_FIFO_COUNT +  border_id, 1)), \
        .fifo_input_ready(`SLICE_VEC(border_input_ready, border*FPGA_FIFO_COUNT +  border_id, 1)), \
        .b_init_address(init_address) \
    );


generate
    // Generate North South neighbors
    for (k=0; k < PHYSICAL_GRID_WIDTH_U; k=k+1) begin: ns_k
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: ns_i
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: ns_j
                wire is_error_systolic_in;
                wire is_error_out;
                wire [LINK_BIT_WIDTH-1:0] weight_in;
                wire fully_grown_data;
                wire local_context_switch;
                assign local_context_switch = 1'b0;

                wire [1:0] north_cut_type;
                wire [1:0] south_cut_type;

                assign north_cut_type = (border_continous[0]==1) ? 2'b11 : 2'b10;
                assign south_cut_type = (border_continous[1]==1) ? 2'b11 : 2'b10;

                reg [ADDRESS_WIDTH_WITH_B-1:0] init_address;
                always@(*) begin
                    init_address [ADDRESS_WIDTH-1:X_BIT_WIDTH+Z_BIT_WIDTH] = k;
                    init_address [ADDRESS_WIDTH_WITH_B-1:ADDRESS_WIDTH] = 1'b1;
                    if(i==0) begin
                        init_address [X_BIT_WIDTH+Z_BIT_WIDTH-1:Z_BIT_WIDTH] = GRID_WIDTH_X - 1;
                        init_address [Z_BIT_WIDTH-1:0] = j-1;
                        init_address [ADDRESS_WIDTH - 1 : X_BIT_WIDTH+Z_BIT_WIDTH+U_BIT_WIDTH] = FPGA_ID - 1;
                    end else begin
                        init_address[X_BIT_WIDTH+Z_BIT_WIDTH-1:Z_BIT_WIDTH] = 0;
                        init_address [Z_BIT_WIDTH-1:0] = j+1;
                        init_address [ADDRESS_WIDTH - 1 : X_BIT_WIDTH+Z_BIT_WIDTH+U_BIT_WIDTH] = FPGA_ID + 1;
                    end
                end

                // if(k==PHYSICAL_GRID_WIDTH_U-1) begin
                //     assign local_context_switch = 1'b1;
                // end else begin
                //     assign local_context_switch = 1'b0;
                // end
                if(i==0 && j == 0) begin // First row top left. always never exists
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j, k, `NEIGHBOR_IDX_NORTH, 2, NUM_CONTEXTS)
                end else if(i==0 && j < GRID_WIDTH_Z && j > 0) begin // First row
                    `NEIGHBOR_LINK_EXTERNAL(i, j, k, `NEIGHBOR_IDX_NORTH, north_cut_type, NUM_CONTEXTS, 0, j-1, init_address)
                end else if(i==GRID_WIDTH_X && j == GRID_WIDTH_Z-1) begin // Last row far right. Never exists
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j, k, `NEIGHBOR_IDX_SOUTH, 2, NUM_CONTEXTS)
                end else if(i==GRID_WIDTH_X && j < GRID_WIDTH_Z-1) begin
                    `NEIGHBOR_LINK_EXTERNAL(i-1, j, k, `NEIGHBOR_IDX_SOUTH, south_cut_type, NUM_CONTEXTS, 1, j, init_address)                 
                end else if (i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j > 0) begin // odd rows which are always internal
                    `NEIGHBOR_LINK_INTERNAL_0(i-1, j-1, k, i, j-1, k, `NEIGHBOR_IDX_SOUTH, `NEIGHBOR_IDX_NORTH, 0, NUM_CONTEXTS)
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j == 0) begin // First element of even rows
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j, k, `NEIGHBOR_IDX_NORTH, 2, NUM_CONTEXTS)
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j == GRID_WIDTH_Z) begin // Last element of even rows
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j-1, k, `NEIGHBOR_IDX_SOUTH, 1, NUM_CONTEXTS)
                end else if (i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j > 0 && j < GRID_WIDTH_Z) begin // Middle elements of even rows
                    `NEIGHBOR_LINK_INTERNAL_0(i-1, j-1, k, i, j, k, `NEIGHBOR_IDX_SOUTH, `NEIGHBOR_IDX_NORTH, 0, NUM_CONTEXTS)
                end
            end
        end
    end

    // Generate East West neighbors
    for (k=0; k < PHYSICAL_GRID_WIDTH_U; k=k+1) begin: ew_k
        for (i=0; i <= GRID_WIDTH_X; i=i+1) begin: ew_i
            for (j=0; j <= GRID_WIDTH_Z; j=j+1) begin: ew_j
                wire is_error_systolic_in;
                wire is_error_out;
                wire [LINK_BIT_WIDTH-1:0] weight_in;
                wire fully_grown_data;
                wire local_context_switch;
                assign local_context_switch = 1'b0;

                wire [1:0] north_cut_type;
                wire [1:0] south_cut_type;

                assign north_cut_type = (border_continous[0]==1) ? 2'b11 : 2'b10;
                assign south_cut_type = (border_continous[1]==1) ? 2'b11 : 2'b10;

                reg [ADDRESS_WIDTH_WITH_B-1:0] init_address;
                always@(*) begin
                    init_address [ADDRESS_WIDTH-1:X_BIT_WIDTH+Z_BIT_WIDTH] = k;
                    init_address [ADDRESS_WIDTH_WITH_B-1:ADDRESS_WIDTH] = 1'b1;
                    if(i==0) begin
                        init_address [X_BIT_WIDTH+Z_BIT_WIDTH-1:Z_BIT_WIDTH] = GRID_WIDTH_X - 1;
                        init_address [Z_BIT_WIDTH-1:0] = j;
                        init_address [ADDRESS_WIDTH - 1 : X_BIT_WIDTH+Z_BIT_WIDTH+U_BIT_WIDTH] = FPGA_ID - 1;
                    end else begin
                        init_address[X_BIT_WIDTH+Z_BIT_WIDTH-1:Z_BIT_WIDTH] = 0;
                        init_address [Z_BIT_WIDTH-1:0] = j;
                        init_address [ADDRESS_WIDTH - 1 : X_BIT_WIDTH+Z_BIT_WIDTH+U_BIT_WIDTH] = FPGA_ID + 1;
                    end
                end

                assign weight_in = `WEIGHT_EW(i,j);
                if(i==0 && j < GRID_WIDTH_Z) begin // First row
                    `NEIGHBOR_LINK_EXTERNAL(i, j, k, `NEIGHBOR_IDX_EAST, north_cut_type, NUM_CONTEXTS, 0, j + GRID_WIDTH_Z, init_address)
                end else if(i==GRID_WIDTH_X && j < GRID_WIDTH_Z) begin // Last row
                    `NEIGHBOR_LINK_EXTERNAL(i-1, j, k, `NEIGHBOR_IDX_WEST, south_cut_type, NUM_CONTEXTS, 1, j + GRID_WIDTH_Z, init_address)
                end else if (i < GRID_WIDTH_X && i > 0 && i%2 == 0 && j < GRID_WIDTH_Z) begin // even rows which are always internal
                    `NEIGHBOR_LINK_INTERNAL_0(i, j, k, i-1, j, k, `NEIGHBOR_IDX_EAST, `NEIGHBOR_IDX_WEST, 0, NUM_CONTEXTS)
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j == 0) begin // First element of odd rows
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i-1, j, k, `NEIGHBOR_IDX_WEST, 1, NUM_CONTEXTS)
                end else if(i < GRID_WIDTH_X -1 && i > 0 && i%2 == 1 && j == GRID_WIDTH_Z) begin // Last element of odd rows excluding last row
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j-1, k, `NEIGHBOR_IDX_EAST, 2, NUM_CONTEXTS)
                end else if(i == GRID_WIDTH_X -1 && j == GRID_WIDTH_Z) begin // Last element of last odd row
                    `NEIGHBOR_LINK_INTERNAL_SINGLE(i, j-1, k, `NEIGHBOR_IDX_EAST, 1, NUM_CONTEXTS)
                end else if(i < GRID_WIDTH_X && i > 0 && i%2 == 1 && j > 0 && j < GRID_WIDTH_Z) begin // Middle elements of odd rows
                    `NEIGHBOR_LINK_INTERNAL_0(i, j-1, k, i-1, j, k, `NEIGHBOR_IDX_EAST, `NEIGHBOR_IDX_WEST, 0, NUM_CONTEXTS)
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
                reg [3:0] type_for_boundary_links;
                wire fully_grown_data;
                always@(*) begin 
                     if(k==1) begin //Ugly workaround for d=11
                         if(context_stage < NUM_CONTEXTS - 1) //This is not delayed as boundary_condition must be given befoe moving to the stage
                             type_for_boundary_links = 3'b00; //  Internal
                         else
                             type_for_boundary_links = 3'b10; // Non-existant
                     end else if(k==0) begin
                        if(context_stage > 0)
                            type_for_boundary_links = 3'b00; //  Internal
                        else if(context_stage == 0)
                            type_for_boundary_links = 3'b01; // Boundary
                        else
                            type_for_boundary_links = 3'b10; //Non existant
//                    end else if(k==PHYSICAL_GRID_WIDTH_U) begin
//                        if(context_stage > 0)
//                            type_for_boundary_links = 3'b00; //  Internal
//                        else if(context_stage == 0)
//                            type_for_boundary_links = 3'b01; // Boundary
//                        else
//                            type_for_boundary_links = 3'b10; //Non existant
                    end else
                        type_for_boundary_links = 3'b00; //  Internal
                end
                assign weight_in = `WEIGHT_UD(i,j);

                wire local_context_switch;
                if(k==PHYSICAL_GRID_WIDTH_U) begin
                    // assign local_context_switch = (context_stage_delayed %2 == 0 && context_stage_delayed < NUM_CONTEXTS - 1) ? 1'b1 : 1'b0; //this is for ctx=d version
                    assign local_context_switch = (context_stage_delayed %2 == 0 && context_stage_delayed < NUM_CONTEXTS - 1) ? 1'b1 : 1'b0;
                end else if(k==0) begin
                    assign local_context_switch = (context_stage_delayed %2 == 1 && context_stage_delayed < NUM_CONTEXTS - 1) ? 1'b1 : 1'b0;
                end else begin
                    assign local_context_switch = 1'b0;
                end
                if(k==0) begin
                    // `NEIGHBOR_LINK_INTERNAL_SUPPORT(i, j, k, i,j,0, `NEIGHBOR_IDX_DOWN, type_for_boundary_links, NUM_CONTEXTS / 2 + 1) //+1 is only for d=ctx
                    `NEIGHBOR_LINK_INTERNAL_SUPPORT(i, j, k, i,j,0, `NEIGHBOR_IDX_DOWN, type_for_boundary_links, NUM_CONTEXTS / 2 + 1)
                end else if(k==PHYSICAL_GRID_WIDTH_U) begin
                    // `NEIGHBOR_LINK_INTERNAL_SUPPORT(i, j, k-1, i,j,1, `NEIGHBOR_IDX_UP, type_for_boundary_links, NUM_CONTEXTS / 2 + 1) //+1 is for d=ctx
                    `NEIGHBOR_LINK_INTERNAL_SUPPORT(i, j, k-1, i,j,1, `NEIGHBOR_IDX_UP, type_for_boundary_links, (NUM_CONTEXTS + 1)/ 2) //+1 is for d=ctx
                end else if (k < PHYSICAL_GRID_WIDTH_U) begin
                    `NEIGHBOR_LINK_INTERNAL_0(i, j, k-1, i, j, k, `NEIGHBOR_IDX_UP, `NEIGHBOR_IDX_DOWN, type_for_boundary_links, NUM_CONTEXTS)
                end
            end
        end
    end
    
endgenerate

generate
    for (k=0; k < PHYSICAL_GRID_WIDTH_U-1; k=k+1) begin: ns_k_extra
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

    for (k=0; k < PHYSICAL_GRID_WIDTH_U - 1; k=k+1) begin: ew_k_extra
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


    for (k=0; k < PHYSICAL_GRID_WIDTH_U-1; k=k+1) begin: ud_k_extra
        for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ud_i_extra
            for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ud_j_extra
                assign ud_k[k].ud_i[i].ud_j[j].is_error_systolic_in = ud_k[k+1].ud_i[i].ud_j[j].is_error_out;
            end
        end
    end

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

    for (k=0; k < PHYSICAL_GRID_WIDTH_U; k=k+1) begin: ns_k_weight
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
    end

    for (i=0; i < GRID_WIDTH_X; i=i+1) begin: ud_i_support
        for (j=0; j < GRID_WIDTH_Z; j=j+1) begin: ud_j_support
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


endgenerate

endmodule

