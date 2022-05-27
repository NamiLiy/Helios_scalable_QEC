`timescale 1ns / 1ps

module standard_planar_code_3d_no_fast_channel_/*$$ID*/ #(
    parameter CODE_DISTANCE_X = /*$$CODE_DISTANCE_X*/,
    parameter CODE_DISTANCE_Z = /*$$CODE_DISTANCE_Z*/,
    parameter WEIGHT_X = 1,
    parameter WEIGHT_Z = 1,
    parameter WEIGHT_UD = 1 // Weight up down
) (
    clk,
    reset,
    stage,
    is_error_syndromes,
    is_odd_clusters,
    is_odd_cardinalities,
    is_touching_boundaries,
    roots,
    has_message_flying,
    master_fifo_out_data_vector,
    master_fifo_out_valid_vector,
    master_fifo_out_ready_vector,
    master_fifo_in_data_vector,
    master_fifo_in_valid_vector,
    master_fifo_in_ready_vector
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PER_DIMENSION_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam DISTANCE_WIDTH = 1 + PER_DIMENSION_WIDTH;
//localparam WEIGHT = 1;  // the weight in MWPM graph
localparam BOUNDARY_COST_X = 2 * WEIGHT_X;
localparam BOUNDARY_COST_Z = 2 * WEIGHT_Z;
localparam BOUNDARY_COST_UD = 2 * WEIGHT_UD;
localparam NEIGHBOR_COST_X = 2 * WEIGHT_X;
localparam NEIGHBOR_COST_Z = 2 * WEIGHT_Z;
localparam NEIGHBOR_COST_UD = 2 * WEIGHT_UD;
localparam MAX_BOUNDARY_COST = `MAX(BOUNDARY_COST_X, BOUNDARY_COST_Z);
localparam BOUNDARY_WIDTH = $clog2(MAX_BOUNDARY_COST + 1);
localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]

localparam MASTER_FIFO_WIDTH = DIRECT_MESSAGE_WIDTH + 1;
//localparam FIFO_COUNT = MEASUREMENT_ROUNDS * (CODE_DISTANCE_Z);

// Generated params
localparam EDGE_COUNT = /*$$EDGE_COUNT*/;
localparam FIFO_COUNT = /*$$EDGE_COUNT*/ * MEASUREMENT_ROUNDS;
localparam X_START = /*$$X_START*/;
localparam X_END = /*$$X_END*/;
localparam FPGAID_WIDTH = /*$$FPGAID_WIDTH*/;
localparam FIFO_IDWIDTH = /*$$FIFO_IDWIDTH*/;

//
localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;

localparam FINAL_FIFO_WIDTH = /*$$HUB_FIFO_WIDTH*/;

input clk;
input reset;
input [STAGE_WIDTH-1:0] stage;
input [PU_COUNT-1:0] is_error_syndromes;
output [PU_COUNT-1:0] is_odd_clusters;
output [PU_COUNT-1:0] is_odd_cardinalities;
output [PU_COUNT-1:0] is_touching_boundaries;
output [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
output has_message_flying;
wire [PU_COUNT-1:0] has_message_flyings;
reg [PU_COUNT-1:0] has_message_flyings_reg;
wire initialize_neighbors;
reg [STAGE_WIDTH-1:0] stage_internal;

output [FINAL_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_out_data_vector;
output [FIFO_COUNT - 1 :0] master_fifo_out_valid_vector;
input [FIFO_COUNT - 1 :0] master_fifo_out_ready_vector;
input [FINAL_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_in_data_vector;
input [FIFO_COUNT - 1 :0] master_fifo_in_valid_vector;
output [FIFO_COUNT - 1 :0] master_fifo_in_ready_vector;


wire [FIFO_COUNT - 1 :0] arbitration_has_flying_messages;
reg [FIFO_COUNT - 1 :0] arbitration_has_flying_messages_reg;


assign  has_message_flying = (|has_message_flyings_reg) | (|arbitration_has_flying_messages_reg);

always@(posedge clk) begin
    has_message_flyings_reg <= has_message_flyings;
    arbitration_has_flying_messages_reg <= arbitration_has_flying_messages;
end

genvar i;
genvar j;
genvar k;
genvar l;
genvar m;

wire [PU_COUNT-1:0] test;

// this is to emualte the delay in the PUs
always @(posedge clk) begin
    if (reset) begin
        stage_internal <= STAGE_IDLE;
    end else begin
        stage_internal <= stage;
    end
end

assign initialize_neighbors = (stage_internal == STAGE_MEASUREMENT_LOADING);

// generate macros
`define CHANNEL_COUNT_IJK(i, j, k) ((i>0?1:0) + (i<(CODE_DISTANCE_X-1)?1:0) + (j>0?1:0) + (j<(CODE_DISTANCE_Z-1)?1:0) + (k>0?1:0) + (k<(MEASUREMENT_ROUNDS-1)?1:0))
`define CHANNEL_COUNT (`CHANNEL_COUNT_IJK(i, j,k))
`define CHANNEL_WIDTH ($clog2(`CHANNEL_COUNT))
`define NEIGHBOR_COUNT `CHANNEL_COUNT
localparam FAST_CHANNEL_COUNT = 0;
`define INDEX(i, j, k) (i * CODE_DISTANCE_Z + j + k * CODE_DISTANCE_Z*CODE_DISTANCE_X)
`define init_is_error_syndrome(i, j, k) is_error_syndromes[`INDEX(i, j, k)]
`define is_odd_cluster(i, j, k) is_odd_clusters[`INDEX(i, j, k)]
`define is_odd_cardinality(i, j, k) is_odd_cardinalities[`INDEX(i, j, k)]
`define is_touching_boundary(i, j, k) is_touching_boundaries[`INDEX(i, j, k)]
`define roots(i, j, k) roots[ADDRESS_WIDTH*(`INDEX(i, j, k)+1)-1:ADDRESS_WIDTH*`INDEX(i, j, k)]
`define has_message_flying(i, j, k) has_message_flyings[`INDEX(i, j, k)]
`define DIRECT_CHANNEL_COUNT (3)

// // Generated Functions
// `define pu_coords_i(x) \
//     PU_COORDS[2*/*$$BIN_WIDTH*/*x+:/*$$BIN_WIDTH*/]
// `define pu_coords_j(x) \
//     PU_COORDS[2*/*$$BIN_WIDTH*/*x + /*$$BIN_WIDTH*/+:/*$$BIN_WIDTH*/]
// `define fifo_x_to_y(x, dir) \
//     /*$$X_TO_Y*/
// `define is_fifo_vert_input(x) \
//     /*$$IS_FIFO_VERT_INPUT*/
// `define is_fifo_hor_input(x) \
//     /*$$IS_FIFO_HOR_INPUT*/
// `define is_fifo_vert_output(x) \
//     /*$$IS_FIFO_VERT_OUTPUT*/
// `define is_fifo_hor_output(x) \
//     /*$$IS_FIFO_HOR_OUTPUT*/
// `define is_fifo_wrap_vert(x) \
//     /*$$IS_FIFO_WRAP_VERT*/
// `define is_fifo_wrap_hor(x) \
//     /*$$IS_FIFO_WRAP_HOR*/
// `define inc_i(x) \
//     /*$$INC_I*/
// `define inc_j(x) \
//     /*$$INC_J*/



// generate
//     for (i=0; i < 20; i=i+1) begin
//         wire [ADDRESS_WIDTH-1:0] roots_temp;
//         assign roots_temp = roots[ADDRESS_WIDTH*(i+1)-1 : ADDRESS_WIDTH*i];
//     end
// endgenerate

// instantiate processing units and their local solver
// instantiate processing units and their local solver
generate
    for (k=0; k < MEASUREMENT_ROUNDS; k=k+1) begin: pu_k
        for (i=X_START; i <= X_END; i=i+1) begin: pu_i
            for (j=0; j < CODE_DISTANCE_Z; j=j+1) begin: pu_j
                // instantiate processing unit
                wire [`NEIGHBOR_COUNT-1:0] neighbor_is_fully_grown;
                wire [(ADDRESS_WIDTH * `NEIGHBOR_COUNT)-1:0] neighbor_roots;
                wire neighbor_increase;
                wire [DIRECT_MESSAGE_WIDTH-1:0] direct_out_channels_data_single;
                wire [`DIRECT_CHANNEL_COUNT-1:0] direct_out_channels_valid;
                wire [`DIRECT_CHANNEL_COUNT-1:0] direct_out_channels_is_full;
                wire [(DIRECT_MESSAGE_WIDTH * `DIRECT_CHANNEL_COUNT)-1:0] direct_in_channels_data;
                wire [`DIRECT_CHANNEL_COUNT-1:0] direct_in_channels_valid;
                wire [`DIRECT_CHANNEL_COUNT-1:0] direct_in_channels_is_taken;
                wire [ADDRESS_WIDTH-1:0] updated_root;
                wire [ADDRESS_WIDTH-1:0] old_root;
                wire is_odd_cluster;
                wire [`NEIGHBOR_COUNT-1:0] neighbor_is_odd_cluster;
                processing_unit #(
                    .ADDRESS_WIDTH(ADDRESS_WIDTH),
                    .DISTANCE_WIDTH(DISTANCE_WIDTH),
                    .BOUNDARY_WIDTH(BOUNDARY_WIDTH),
                    .NEIGHBOR_COUNT(`NEIGHBOR_COUNT),
                    .FAST_CHANNEL_COUNT(FAST_CHANNEL_COUNT),
                    .I(i),
                    .J(j),
                    .K(k),
                    .CODE_DISTANCE_X(CODE_DISTANCE_X),
                    .CODE_DISTANCE_Z(CODE_DISTANCE_Z),
                    .MEASUREMENT_ROUNDS(MEASUREMENT_ROUNDS),
                    .INIT_BOUNDARY_COST_X(BOUNDARY_COST_X),
                    .INIT_BOUNDARY_COST_Z(BOUNDARY_COST_Z),
                    .INIT_BOUNDARY_COST_UD(BOUNDARY_COST_UD),
                    .DIRECT_CHANNEL_COUNT(`DIRECT_CHANNEL_COUNT)
                ) u_processing_unit (
                    .clk(clk),
                    .reset(reset),
                    .init_is_error_syndrome(`init_is_error_syndrome(i, j, k)),
                    .stage_in(stage),
                    .neighbor_is_fully_grown(neighbor_is_fully_grown),
                    .neighbor_is_odd_cluster(neighbor_is_odd_cluster),
                    .neighbor_roots(neighbor_roots),
                    .neighbor_increase(neighbor_increase),
                    .direct_out_channels_data_single(direct_out_channels_data_single),
                    .direct_out_channels_valid(direct_out_channels_valid),
                    .direct_out_channels_is_full(direct_out_channels_is_full),
                    .direct_in_channels_data(direct_in_channels_data),
                    .direct_in_channels_valid(direct_in_channels_valid),
                    .direct_in_channels_is_taken(direct_in_channels_is_taken),
                    .old_root(old_root),
                    .updated_root(updated_root),
                    .is_odd_cluster(is_odd_cluster),
                    .is_odd_cardinality(`is_odd_cardinality(i, j, k)),
                    .is_touching_boundary(`is_touching_boundary(i, j, k)),
                    .is_processing(`has_message_flying(i, j, k))
                );
                assign `roots(i, j, k) = updated_root;
                assign `is_odd_cluster(i, j, k) = is_odd_cluster;
                // assign `has_message_flying(i, j) = union_out_channels_valid | (|union_in_channels_valid) | (|direct_out_channels_valid) | (|direct_in_channels_valid);
            end
        end
        for (i=0; i < X_START; i=i+1) begin: pu_i_extra
            for (j=0; j < CODE_DISTANCE_Z; j=j+1) begin: pu_j_extra
                assign `has_message_flying(i, j, k) = 1'b0;
                assign `is_odd_cluster(i, j, k) = 1'b0;
            end
        end
        for (i=X_END+1; i < CODE_DISTANCE_X; i=i+1) begin: pu_i_extras
            for (j=0; j < CODE_DISTANCE_Z; j=j+1) begin: pu_j_extras
                assign `has_message_flying(i, j, k) = 1'b0;
                assign `is_odd_cluster(i, j, k) = 1'b0;
            end
        end
    end
endgenerate

`define FIFO_INDEX(j, k) (j + k * (EDGE_COUNT))
`define MASTER_FIFO_VEC(vec, idx) (vec[(((idx)+1)*FINAL_FIFO_WIDTH)-1:(idx)*FINAL_FIFO_WIDTH])
`define MASTER_FIFO_SIGNAL_VEC(vec, idx) (vec[(idx)])

localparam logic [FPGAID_WIDTH + FIFO_IDWIDTH - 1:0] neighbour_route_paths[EDGE_COUNT*MEASUREMENT_ROUNDS + 1] = {/*$$NEIGBOUR_PATH*/};
localparam logic [FPGAID_WIDTH + FIFO_IDWIDTH - 1:0] direct_route_paths[EDGE_COUNT*MEASUREMENT_ROUNDS + 1] = {/*$$DIRECT_PATH*/};
// The plus one is entirely for the ease of generation

// instantiate the pu_arbitration_units
generate
    for (m=0; m < MEASUREMENT_ROUNDS; m=m+1) begin: fifo_k
        for (l=0; l < EDGE_COUNT; l=l+1) begin: fifo_j
            // instantiate processing unit
            wire [ADDRESS_WIDTH + 1:0] neighbor_fifo_out_data; //not -1 to support extra signal
            wire neighbor_fifo_out_valid;
            wire neighbor_fifo_out_ready;
            wire [ADDRESS_WIDTH + 1:0] neighbor_fifo_in_data;
            wire neighbor_fifo_in_valid;
            wire neighbor_fifo_in_ready;
            wire [DIRECT_MESSAGE_WIDTH-1: 0] blocking_fifo_out_data;
            wire blocking_fifo_out_valid;
            wire blocking_fifo_out_ready;
            wire [DIRECT_MESSAGE_WIDTH-1: 0] blocking_fifo_in_data;
            wire blocking_fifo_in_valid;
            wire blocking_fifo_in_ready;
            wire blocking_fifo_in_full;
            // wire [FINAL_FIFO_WIDTH-1: 0] master_fifo_out_data;
            // wire master_fifo_out_valid;
            // wire master_fifo_out_ready;
            // wire [FINAL_FIFO_WIDTH-1: 0] master_fifo_in_data;
            // wire master_fifo_in_valid;
            // wire master_fifo_in_ready;
            pu_arbitration_unit #(
                .CODE_DISTANCE_X(CODE_DISTANCE_X),
                .CODE_DISTANCE_Z(CODE_DISTANCE_Z),
                .FINAL_FIFO_WIDTH(FINAL_FIFO_WIDTH),
                .HEADER_WIDTH(FIFO_IDWIDTH+FPGAID_WIDTH)
            ) u_pu_arbitration_unit (
                .clk(clk),
                .reset(reset),
                .neighbor_fifo_out_data(neighbor_fifo_out_data),
                .neighbor_fifo_out_valid(neighbor_fifo_out_valid),
                .neighbor_fifo_out_ready(neighbor_fifo_out_ready),
                .neighbor_fifo_in_data(neighbor_fifo_in_data),
                .neighbor_fifo_in_valid(neighbor_fifo_in_valid),
                .neighbor_fifo_in_ready(neighbor_fifo_in_ready),
                .blocking_fifo_out_data(blocking_fifo_out_data),
                .blocking_fifo_out_valid(blocking_fifo_out_valid),
                .blocking_fifo_out_ready(blocking_fifo_out_ready),
                .blocking_fifo_in_data(blocking_fifo_in_data),
                .blocking_fifo_in_valid(blocking_fifo_in_valid),
                .blocking_fifo_in_ready(blocking_fifo_in_ready),
                .master_fifo_out_data(`MASTER_FIFO_VEC(master_fifo_out_data_vector, `FIFO_INDEX(l, m))),
                .master_fifo_out_valid(`MASTER_FIFO_SIGNAL_VEC(master_fifo_out_valid_vector, `FIFO_INDEX(l, m))),
                .master_fifo_out_ready(`MASTER_FIFO_SIGNAL_VEC(master_fifo_out_ready_vector, `FIFO_INDEX(l, m))),
                .master_fifo_in_data(`MASTER_FIFO_VEC(master_fifo_in_data_vector, `FIFO_INDEX(l, m))),
                .master_fifo_in_valid(`MASTER_FIFO_SIGNAL_VEC(master_fifo_in_valid_vector, `FIFO_INDEX(l, m))),
                .master_fifo_in_ready(`MASTER_FIFO_SIGNAL_VEC(master_fifo_in_ready_vector, `FIFO_INDEX(l, m))),
                .has_flying_messages(`MASTER_FIFO_SIGNAL_VEC(arbitration_has_flying_messages, `FIFO_INDEX(l, m))),
                .receiver_id_neighbour(neighbour_route_paths [`FIFO_INDEX(l, m)]),
                .receiver_id_direct(direct_route_paths [`FIFO_INDEX(l, m)])
            );

            assign blocking_fifo_in_ready = ~blocking_fifo_in_full;
        end
    end
endgenerate

`define NEIGHBOR_IDX_TOP(i, j, k) (0)
`define NEIGHBOR_IDX_BOTTOM(i, j, k) (i>0?1:0)
`define NEIGHBOR_IDX_LEFT(i, j, k) ((i>0?1:0) + (i<(CODE_DISTANCE_X-1)?1:0))
`define NEIGHBOR_IDX_RIGHT(i, j, k) ((i>0?1:0) + (i<(CODE_DISTANCE_X-1)?1:0) + (j>0?1:0))
`define NEIGHBOR_IDX_DOWN(i, j, k) ((i>0?1:0) + (i<(CODE_DISTANCE_X-1)?1:0) + (j>0?1:0) + (j<(CODE_DISTANCE_Z-1)?1:0))
`define NEIGHBOR_IDX_UP(i, j, k) ((i>0?1:0) + (i<(CODE_DISTANCE_X-1)?1:0) + (j>0?1:0) + (j<(CODE_DISTANCE_Z-1)?1:0) + (k>0?1:0))
`define PU(i, j, k) pu_k[k].pu_i[i].pu_j[j]
`define SLICE_ADDRESS_VEC(vec, idx) (vec[(((idx)+1)*ADDRESS_WIDTH)-1:(idx)*ADDRESS_WIDTH])
`define SLICE_DIRECT_MESSAGE_VEC(vec, idx) (vec[(((idx)+1)*DIRECT_MESSAGE_WIDTH)-1:(idx)*DIRECT_MESSAGE_WIDTH])
`define PU_FIFO(j, k) fifo_k[k].fifo_j[j]

// instantiate vertical neighbor link and connect signals properly
`define NEIGHBOR_VERTICAL_INSTANTIATE \
neighbor_link #(.LENGTH(NEIGHBOR_COST_X), .ADDRESS_WIDTH(ADDRESS_WIDTH)) neighbor_vertical (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), .is_fully_grown(`PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_BOTTOM(i, j, k)]),\
    .a_old_root_in(`PU(i, j, k).updated_root), .a_increase(`PU(i, j, k).neighbor_increase), .a_is_odd_cluster(`PU(i, j, k).is_odd_cluster),\
    .b_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k).neighbor_roots, `NEIGHBOR_IDX_BOTTOM(i, j, k))),\
    .b_old_root_in(`PU(i+1, j, k).updated_root), .b_increase(`PU(i+1, j, k).neighbor_increase), .b_is_odd_cluster(`PU(i+1, j, k).is_odd_cluster),\
    .a_old_root_out(`SLICE_ADDRESS_VEC(`PU(i+1, j, k).neighbor_roots, `NEIGHBOR_IDX_TOP(i+1, j, k))),\
    .is_odd_cluster(`PU(i, j, k).neighbor_is_odd_cluster[`NEIGHBOR_IDX_BOTTOM(i, j, k)])\
);\
assign `PU(i+1, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_TOP(i+1, j, k)] = `PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_BOTTOM(i, j, k)]; \
assign `PU(i+1, j, k).neighbor_is_odd_cluster[`NEIGHBOR_IDX_TOP(i+1, j, k)] = `PU(i, j, k).neighbor_is_odd_cluster[`NEIGHBOR_IDX_BOTTOM(i, j, k)];

// Keep in mind a and b are interchanged 
`define NEIGHBOR_VERTICAL_TO_FIFO_INSTANTIATE_TOP_BORDER(n_i, n_j, n_k, pu_i, new_j) \
neighbor_link_to_fifo #(.LENGTH(NEIGHBOR_COST_X), .PER_DIMENSION_WIDTH(PER_DIMENSION_WIDTH), .N_I(n_i), .N_J(n_j), .N_K(n_k)) neighbor_vertical_fifo (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), .is_fully_grown(`PU(pu_i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_TOP(pu_i, j, k)]),\
    .is_odd_cluster(`PU(pu_i, j, k).neighbor_is_odd_cluster[`NEIGHBOR_IDX_TOP(pu_i, j, k)]), \
    .a_old_root_in(`PU(pu_i, j, k).updated_root), .a_increase(`PU(pu_i, j, k).neighbor_increase), .a_is_odd_cluster(`PU(pu_i, j, k).is_odd_cluster),\
    .b_old_root_out(`SLICE_ADDRESS_VEC(`PU(pu_i, j, k).neighbor_roots, `NEIGHBOR_IDX_TOP(pu_i, j, k))),\
    .neighbor_fifo_out_data(`PU_FIFO(new_j,k).neighbor_fifo_out_data),  \
    .neighbor_fifo_out_valid(`PU_FIFO(new_j,k).neighbor_fifo_out_valid), \
    .neighbor_fifo_out_ready(`PU_FIFO(new_j,k).neighbor_fifo_out_ready), \
    .neighbor_fifo_in_data(`PU_FIFO(new_j,k).neighbor_fifo_in_data), \
    .neighbor_fifo_in_valid(`PU_FIFO(new_j,k).neighbor_fifo_in_valid), \
    .neighbor_fifo_in_ready(`PU_FIFO(new_j,k).neighbor_fifo_in_ready) \
);

`define NEIGHBOR_VERTICAL_TO_FIFO_INSTANTIATE_BOTTOM_BORDER(n_i, n_j, n_k, pu_i, new_j) \
neighbor_link_to_fifo #(.LENGTH(NEIGHBOR_COST_X), .PER_DIMENSION_WIDTH(PER_DIMENSION_WIDTH), .N_I(n_i), .N_J(n_j), .N_K(n_k)) neighbor_vertical_fifo (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), .is_fully_grown(`PU(pu_i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_BOTTOM(pu_i, j, k)]),\
    .is_odd_cluster(`PU(pu_i, j, k).neighbor_is_odd_cluster[`NEIGHBOR_IDX_BOTTOM(pu_i, j, k)]), \
    .a_old_root_in(`PU(pu_i, j, k).updated_root), .a_increase(`PU(pu_i, j, k).neighbor_increase), .a_is_odd_cluster(`PU(pu_i, j, k).is_odd_cluster),\
    .b_old_root_out(`SLICE_ADDRESS_VEC(`PU(pu_i, j, k).neighbor_roots, `NEIGHBOR_IDX_BOTTOM(pu_i, j, k))),\
    .neighbor_fifo_out_data(`PU_FIFO(new_j,k).neighbor_fifo_out_data),  \
    .neighbor_fifo_out_valid(`PU_FIFO(new_j,k).neighbor_fifo_out_valid), \
    .neighbor_fifo_out_ready(`PU_FIFO(new_j,k).neighbor_fifo_out_ready), \
    .neighbor_fifo_in_data(`PU_FIFO(new_j,k).neighbor_fifo_in_data), \
    .neighbor_fifo_in_valid(`PU_FIFO(new_j,k).neighbor_fifo_in_valid), \
    .neighbor_fifo_in_ready(`PU_FIFO(new_j,k).neighbor_fifo_in_ready) \
);


`define NEIGHBOR_HORIZONTAL_INSTANTIATE \
neighbor_link #(.LENGTH(NEIGHBOR_COST_Z), .ADDRESS_WIDTH(ADDRESS_WIDTH)) neighbor_horizontal (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), .is_fully_grown(`PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_RIGHT(i, j, k)]),\
    .a_old_root_in(`PU(i, j, k).updated_root), .a_increase(`PU(i, j, k).neighbor_increase), .a_is_odd_cluster(`PU(i, j, k).is_odd_cluster),\
    .b_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k).neighbor_roots, `NEIGHBOR_IDX_RIGHT(i, j, k))),\
    .b_old_root_in(`PU(i, j+1, k).updated_root), .b_increase(`PU(i, j+1, k).neighbor_increase), .b_is_odd_cluster(`PU(i, j+1, k).is_odd_cluster),\
    .a_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j+1, k).neighbor_roots, `NEIGHBOR_IDX_LEFT(i, j+1, k))), \
    .is_odd_cluster(`PU(i, j, k).neighbor_is_odd_cluster[`NEIGHBOR_IDX_RIGHT(i, j, k)])\
);\
assign `PU(i, j+1, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_LEFT(i, j+1, k)] = `PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_RIGHT(i, j, k)]; \
assign `PU(i, j+1, k).neighbor_is_odd_cluster[`NEIGHBOR_IDX_LEFT(i, j+1, k)] = `PU(i, j, k).neighbor_is_odd_cluster[`NEIGHBOR_IDX_RIGHT(i, j, k)];

// instantiate updown neighbor link and connect signals properly
`define NEIGHBOR_UPDOWN_INSTANTIATE \
neighbor_link #(.LENGTH(NEIGHBOR_COST_UD), .ADDRESS_WIDTH(ADDRESS_WIDTH)) neighbor_updown (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), .is_fully_grown(`PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_UP(i, j, k)]),\
    .a_old_root_in(`PU(i, j, k).updated_root), .a_increase(`PU(i, j, k).neighbor_increase), .a_is_odd_cluster(`PU(i, j, k).is_odd_cluster),\
    .b_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k).neighbor_roots, `NEIGHBOR_IDX_UP(i, j, k))),\
    .b_old_root_in(`PU(i, j, k+1).updated_root), .b_increase(`PU(i, j, k+1).neighbor_increase), .b_is_odd_cluster(`PU(i, j, k+1).is_odd_cluster),\
    .a_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k+1).neighbor_roots, `NEIGHBOR_IDX_DOWN(i, j, k+1))),\
    .is_odd_cluster(`PU(i, j, k).neighbor_is_odd_cluster[`NEIGHBOR_IDX_UP(i, j, k)])\
);\
assign `PU(i, j, k+1).neighbor_is_fully_grown[`NEIGHBOR_IDX_DOWN(i, j, k+1)] = `PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_UP(i, j, k)]; \
assign `PU(i, j, k+1).neighbor_is_odd_cluster[`NEIGHBOR_IDX_DOWN(i, j, k+1)] = `PU(i, j, k).neighbor_is_odd_cluster[`NEIGHBOR_IDX_UP(i, j, k)];

// instantiate vertical direct channels and connect signals properly
`define DIRECT_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_INPUT(pu_i, new_j) \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH)) blocking_channel_top (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU_FIFO(new_j,k).blocking_fifo_in_data),\
    .in_valid(`PU_FIFO(new_j,k).blocking_fifo_in_valid),\
    .in_is_full(`PU_FIFO(new_j,k).blocking_fifo_in_full),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(pu_i, j, k).direct_in_channels_data, 0)),\
    .out_valid(`PU(pu_i, j, k).direct_in_channels_valid[0]),\
    .out_is_taken(`PU(pu_i, j, k).direct_in_channels_is_taken[0])\
);

`define DIRECT_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_OUTPUT(pu_i, new_j) \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH)) blocking_channel_top_to_fifo (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU(pu_i, j, k).direct_out_channels_data_single),\
    .in_valid(`PU(pu_i, j, k).direct_out_channels_valid[0]),\
    .in_is_full(`PU(pu_i, j, k).direct_out_channels_is_full[0]),\
    .out_data(`PU_FIFO(new_j,k).blocking_fifo_out_data),\
    .out_valid(`PU_FIFO(new_j,k).blocking_fifo_out_valid),\
    .out_is_taken(`PU_FIFO(new_j,k).blocking_fifo_out_ready)\
);

`define DIRECT_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_NULL(new_j) \
assign `PU_FIFO(new_j,k).blocking_fifo_out_valid = 1'b0;\
assign `PU_FIFO(new_j,k).blocking_fifo_in_full = 1'b0;

`define DIRECT_CHANNEL_VERTICAL_INSTANTIATE \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH)) blocking_channel_top (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU((i+1)%CODE_DISTANCE_X, j, k).direct_out_channels_data_single),\
    .in_valid(`PU((i+1)%CODE_DISTANCE_X, j, k).direct_out_channels_valid[0]),\
    .in_is_full(`PU((i+1)%CODE_DISTANCE_X, j, k).direct_out_channels_is_full[0]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j, k).direct_in_channels_data, 0)),\
    .out_valid(`PU(i, j, k).direct_in_channels_valid[0]),\
    .out_is_taken(`PU(i, j, k).direct_in_channels_is_taken[0])\
);

`define DIRECT_CHANNEL_VERTICAL_WRAP_INSTANTIATE \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH), .DEPTH(128)) blocking_channel_top (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU((i+1)%CODE_DISTANCE_X, j, k).direct_out_channels_data_single),\
    .in_valid(`PU((i+1)%CODE_DISTANCE_X, j, k).direct_out_channels_valid[0]),\
    .in_is_full(`PU((i+1)%CODE_DISTANCE_X, j, k).direct_out_channels_is_full[0]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j, k).direct_in_channels_data, 0)),\
    .out_valid(`PU(i, j, k).direct_in_channels_valid[0]),\
    .out_is_taken(`PU(i, j, k).direct_in_channels_is_taken[0])\
);

`define DIRECT_CHANNEL_HORIZONTAL_INSTANTIATE \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH)) blocking_channel_left (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU(i, (j+1)%(CODE_DISTANCE_Z), k).direct_out_channels_data_single),\
    .in_valid(`PU(i, (j+1)%(CODE_DISTANCE_Z), k).direct_out_channels_valid[1]),\
    .in_is_full(`PU(i, (j+1)%(CODE_DISTANCE_Z), k).direct_out_channels_is_full[1]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j, k).direct_in_channels_data, 1)),\
    .out_valid(`PU(i, j, k).direct_in_channels_valid[1]),\
    .out_is_taken(`PU(i, j, k).direct_in_channels_is_taken[1])\
);

`define DIRECT_CHANNEL_HORIZONTAL_WRAP_INSTANTIATE \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH), .DEPTH(128)) blocking_channel_left (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU(i, (j+1)%(CODE_DISTANCE_Z), k).direct_out_channels_data_single),\
    .in_valid(`PU(i, (j+1)%(CODE_DISTANCE_Z), k).direct_out_channels_valid[1]),\
    .in_is_full(`PU(i, (j+1)%(CODE_DISTANCE_Z), k).direct_out_channels_is_full[1]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j, k).direct_in_channels_data, 1)),\
    .out_valid(`PU(i, j, k).direct_in_channels_valid[1]),\
    .out_is_taken(`PU(i, j, k).direct_in_channels_is_taken[1])\
);

// instantiate horizontal direct channels and connect signals properly
`define DIRECT_CHANNEL_UPDOWN_INSTANTIATE \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH)) blocking_channel_down (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU(i, j, (k+1)%MEASUREMENT_ROUNDS).direct_out_channels_data_single),\
    .in_valid(`PU(i, j, (k+1)%MEASUREMENT_ROUNDS).direct_out_channels_valid[2]),\
    .in_is_full(`PU(i, j, (k+1)%MEASUREMENT_ROUNDS).direct_out_channels_is_full[2]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j, k).direct_in_channels_data, 2)),\
    .out_valid(`PU(i, j, k).direct_in_channels_valid[2]),\
    .out_is_taken(`PU(i, j, k).direct_in_channels_is_taken[2])\
);

`define DIRECT_CHANNEL_UPDOWN_WRAP_INSTANTIATE \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH), .DEPTH(128)) blocking_channel_down (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU(i, j, (k+1)%MEASUREMENT_ROUNDS).direct_out_channels_data_single),\
    .in_valid(`PU(i, j, (k+1)%MEASUREMENT_ROUNDS).direct_out_channels_valid[2]),\
    .in_is_full(`PU(i, j, (k+1)%MEASUREMENT_ROUNDS).direct_out_channels_is_full[2]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j, k).direct_in_channels_data, 2)),\
    .out_valid(`PU(i, j, k).direct_in_channels_valid[2]),\
    .out_is_taken(`PU(i, j, k).direct_in_channels_is_taken[2])\
);

generate
    for (k=0; k < MEASUREMENT_ROUNDS; k=k+1) begin: neighbor_k
        for (i=0; i < CODE_DISTANCE_X; i=i+1) begin: neighbor_i
            for (j=0; j < CODE_DISTANCE_Z; j=j+1) begin: neighbor_j
                if ( i >= X_START && i <= X_END) begin
                     if (i < X_END) begin
                         `NEIGHBOR_VERTICAL_INSTANTIATE
                         `DIRECT_CHANNEL_VERTICAL_INSTANTIATE
                     end
                     if(X_START == 0 && X_END == CODE_DISTANCE_X - 1) begin
                         `DIRECT_CHANNEL_VERTICAL_WRAP_INSTANTIATE
                     end
                     if (j < (CODE_DISTANCE_Z-1)) begin
                         `NEIGHBOR_HORIZONTAL_INSTANTIATE
                         `DIRECT_CHANNEL_HORIZONTAL_INSTANTIATE
                     end else begin
                         `DIRECT_CHANNEL_HORIZONTAL_WRAP_INSTANTIATE
                     end
                     
                     if (k < (MEASUREMENT_ROUNDS-1)) begin
                         `NEIGHBOR_UPDOWN_INSTANTIATE
                         `DIRECT_CHANNEL_UPDOWN_INSTANTIATE
                     end else begin
                         `DIRECT_CHANNEL_UPDOWN_WRAP_INSTANTIATE
                     end
                end
            end
        end
    end
endgenerate

genvar s;

generate
    for (k=0; k < MEASUREMENT_ROUNDS; k=k+1) begin: neighbor_k_extra
        for (j=0; j < CODE_DISTANCE_Z; j=j+1) begin: neighbor_j_extra
            if (X_START == 0 && X_END < CODE_DISTANCE_X-1) begin
                `NEIGHBOR_VERTICAL_TO_FIFO_INSTANTIATE_BOTTOM_BORDER(X_END+1, j, k, X_END, j)
                `DIRECT_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_INPUT(X_END, j)
                `DIRECT_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_OUTPUT(X_START, j)
            end else if  (X_START > 0 && X_END == CODE_DISTANCE_X-1) begin
                `NEIGHBOR_VERTICAL_TO_FIFO_INSTANTIATE_TOP_BORDER(X_START-1, j, k, X_START, j)
                `DIRECT_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_INPUT(X_END, j)
                `DIRECT_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_OUTPUT(X_START, j)
            end else if  (X_START > 0 && X_END < CODE_DISTANCE_X-1) begin // This is the hard one as it is a split in the middle
                for(s=0; s <2; s++) begin : s_value
                    if(s==0) begin
                        `NEIGHBOR_VERTICAL_TO_FIFO_INSTANTIATE_TOP_BORDER(X_START-1, j, k, X_START, j)
                    end else begin
                        `NEIGHBOR_VERTICAL_TO_FIFO_INSTANTIATE_BOTTOM_BORDER(X_END+1, j, k, X_END, j + CODE_DISTANCE_Z)
                    end
                end
                `DIRECT_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_INPUT(X_END , j)
                `DIRECT_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_OUTPUT(X_START, j)
                `DIRECT_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_NULL(j+ CODE_DISTANCE_Z)
            end
        end
    end
endgenerate

endmodule
