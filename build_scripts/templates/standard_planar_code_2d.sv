`timescale 1ns / 1ps

module standard_planar_code_3d_no_fast_channel_$$ID #(
    CODE_DISTANCE = 3  // has CODE_DISTANCE �� (CODE_DISTANCE-1) processing units
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

`include "parameters.sv"

localparam PU_COUNT = CODE_DISTANCE * CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam DISTANCE_WIDTH = 1 + PER_DIMENSION_WIDTH;
localparam WEIGHT = 1;  // the weight in MWPM graph
localparam BOUNDARY_COST = 2 * WEIGHT;
localparam NEIGHBOR_COST = 2 * WEIGHT;
localparam BOUNDARY_WIDTH = $clog2(BOUNDARY_COST + 1);
localparam UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH;  // [old_root, updated_root]
localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]
localparam MASTER_FIFO_WIDTH = UNION_MESSAGE_WIDTH + 1 + 1;
localparam FINAL_FIFO_WIDTH = MASTER_FIFO_WIDTH + ADDRESS_WIDTH;
localparam FIFO_COUNT = CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam PU_COORDS [$$PU_COORD_WIDTH-1:0] = '{$$PU_COORDS};
localparam EDGE_DIRS [$$EDGE_DIRS_WIDTH-1:0] = '{$$EDGE_DIRS};

input clk;
input reset;
input [STAGE_WIDTH-1:0] stage;
input [PU_COUNT-1:0] is_error_syndromes;
output [PU_COUNT-1:0] is_odd_clusters;
output [PU_COUNT-1:0] is_odd_cardinalities;
output [PU_COUNT-1:0] is_touching_boundaries;
output [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
output has_message_flying;

output [MASTER_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_out_data_vector;
output [FIFO_COUNT - 1 :0] master_fifo_out_valid_vector;
input [FIFO_COUNT - 1 :0] master_fifo_out_ready_vector;
input [MASTER_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_in_data_vector;
input [FIFO_COUNT - 1 :0] master_fifo_in_valid_vector;
output [FIFO_COUNT - 1 :0] master_fifo_in_ready_vector;

wire [PU_COUNT-1:0] has_message_flyings;
reg [PU_COUNT-1:0] has_message_flyings_reg;
wire initialize_neighbors;
reg [STAGE_WIDTH-1:0] stage_internal;

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
`define CHANNEL_COUNT_IJK(i, j, k) ((i>0?1:0) + (i<(CODE_DISTANCE-1)?1:0) + (j>0?1:0) + (j<(CODE_DISTANCE-2)?1:0) + (k>0?1:0) + (k<(CODE_DISTANCE-1)?1:0))
`define CHANNEL_COUNT (`CHANNEL_COUNT_IJK(i, j,k))
`define CHANNEL_WIDTH ($clog2(`CHANNEL_COUNT))
`define NEIGHBOR_COUNT `CHANNEL_COUNT
localparam FAST_CHANNEL_COUNT = 0;
`define INDEX(i, j, k) (i * (CODE_DISTANCE-1) + j + k * (CODE_DISTANCE-1)*CODE_DISTANCE)
`define init_is_error_syndrome(i, j, k) is_error_syndromes[`INDEX(i, j, k)]
`define init_has_boundary(i, j, k) ((j==0) || (j==(CODE_DISTANCE-2)) || k==0)
`define is_odd_cluster(i, j, k) is_odd_clusters[`INDEX(i, j, k)]
`define is_odd_cardinality(i, j, k) is_odd_cardinalities[`INDEX(i, j, k)]
`define is_touching_boundary(i, j, k) is_touching_boundaries[`INDEX(i, j, k)]
`define roots(i, j, k) roots[ADDRESS_WIDTH*(`INDEX(i, j, k)+1)-1:ADDRESS_WIDTH*`INDEX(i, j, k)]
`define has_message_flying(i, j, k) has_message_flyings[`INDEX(i, j, k)]
`define DIRECT_CHANNEL_COUNT (3)
`define pu_i(x) 2*$$BIN_WIDTH*x
`define pu_j(x) 2*$$BIN_WIDTH*x + $$BIN_WIDTH
`define contained(i,j) $$PU_CONT

// generate
//     for (i=0; i < 20; i=i+1) begin
//         wire [ADDRESS_WIDTH-1:0] roots_temp;
//         assign roots_temp = roots[ADDRESS_WIDTH*(i+1)-1 : ADDRESS_WIDTH*i];
//     end
// endgenerate

// instantiate processing units and their local solver
generate
    for (x=0; x < $$PU_INST; x=x+1) begin: pu_arr
        for(k=0; k < CODE_DISTANCE-1; k=k+1) begin: pu_k
            // instantiate processing unit
            wire [`NEIGHBOR_COUNT-1:0] neighbor_is_fully_grown;
            wire [(ADDRESS_WIDTH * `NEIGHBOR_COUNT)-1:0] neighbor_old_roots;
            wire neighbor_increase;
            wire [(UNION_MESSAGE_WIDTH * `CHANNEL_COUNT)-1:0] union_out_channels_data;
            wire union_out_channels_valid;
            wire [(UNION_MESSAGE_WIDTH * `CHANNEL_COUNT)-1:0] union_in_channels_data;
            wire [`CHANNEL_COUNT-1:0] union_in_channels_valid;
            wire [DIRECT_MESSAGE_WIDTH-1:0] direct_out_channels_data_single;
            wire [`DIRECT_CHANNEL_COUNT-1:0] direct_out_channels_valid;
            wire [`DIRECT_CHANNEL_COUNT-1:0] direct_out_channels_is_full;
            wire [(DIRECT_MESSAGE_WIDTH * `DIRECT_CHANNEL_COUNT)-1:0] direct_in_channels_data;
            wire [`DIRECT_CHANNEL_COUNT-1:0] direct_in_channels_valid;
            wire [`DIRECT_CHANNEL_COUNT-1:0] direct_in_channels_is_taken;
            wire [ADDRESS_WIDTH-1:0] old_root;
            processing_unit #(
                .ADDRESS_WIDTH(ADDRESS_WIDTH),
                .DISTANCE_WIDTH(DISTANCE_WIDTH),
                .BOUNDARY_WIDTH(BOUNDARY_WIDTH),
                .NEIGHBOR_COUNT(`NEIGHBOR_COUNT),
                .FAST_CHANNEL_COUNT(FAST_CHANNEL_COUNT),
                .I(PU_COORDS[pu_i(x)+:$$BIN_WIDTH]),
                .J(PU_COORDS[pu_j(x)+:$$BIN_WIDTH]),
                .K(k),
                .CODE_DISTANCE(CODE_DISTANCE),
                .INIT_BOUNDARY_COST(BOUNDARY_COST),
                .DIRECT_CHANNEL_COUNT(`DIRECT_CHANNEL_COUNT)
            ) u_processing_unit (
                .clk(clk),
                .reset(reset),
                .init_is_error_syndrome(`init_is_error_syndrome(i, j, k)),
                .stage_in(stage),
                .neighbor_is_fully_grown(neighbor_is_fully_grown),
                .neighbor_old_roots(neighbor_old_roots),
                .neighbor_increase(neighbor_increase),
                .union_out_channels_data(union_out_channels_data),
                .union_out_channels_valid(union_out_channels_valid),
                .union_in_channels_data(union_in_channels_data),
                .union_in_channels_valid(union_in_channels_valid),
                .direct_out_channels_data_single(direct_out_channels_data_single),
                .direct_out_channels_valid(direct_out_channels_valid),
                .direct_out_channels_is_full(direct_out_channels_is_full),
                .direct_in_channels_data(direct_in_channels_data),
                .direct_in_channels_valid(direct_in_channels_valid),
                .direct_in_channels_is_taken(direct_in_channels_is_taken),
                .old_root(old_root),
                .updated_root(`roots(i, j, k)),
                .is_odd_cluster(`is_odd_cluster(i, j, k)),
                .is_odd_cardinality(`is_odd_cardinality(i, j, k)),
                .is_touching_boundary(`is_touching_boundary(i, j, k)),
                .is_processing(`has_message_flying(i, j, k)),
                .is_error_syndrome(),
                .boundary_increased(),
                .pending_tell_new_root_touching_boundary()
            );
            // assign `has_message_flying(i, j) = union_out_channels_valid | (|union_in_channels_valid) | (|direct_out_channels_valid) | (|direct_in_channels_valid);
        end
    end
endgenerate

`define FIFO_INDEX(j, k) (j + k * (CODE_DISTANCE-1))
`define MASTER_FIFO_VEC(vec, idx) (vec[(((idx)+1)*MASTER_FIFO_WIDTH)-1:(idx)*MASTER_FIFO_WIDTH])
`define MASTER_FIFO_SIGNAL_VEC(vec, idx) (vec[(idx)])

// instantiate the pu_arbitration_units
generate
    for (k=0; k < CODE_DISTANCE; k=k+1) begin: fifo_k
        for (j=0; j < CODE_DISTANCE-1; j=j+1) begin: fifo_j
            // instantiate processing unit
            wire [ADDRESS_WIDTH:0] neighbor_fifo_out_data; //not -1 to support extra signal
            wire neighbor_fifo_out_valid;
            wire neighbor_fifo_out_ready;
            wire [ADDRESS_WIDTH:0] neighbor_fifo_in_data;
            wire neighbor_fifo_in_valid;
            wire neighbor_fifo_in_ready;
            wire [UNION_MESSAGE_WIDTH-1: 0] non_blocking_fifo_out_data;
            wire non_blocking_fifo_out_valid;
            wire non_blocking_fifo_out_ready;
            wire [UNION_MESSAGE_WIDTH-1: 0] non_blocking_fifo_in_data;
            wire non_blocking_fifo_in_valid;
            wire non_blocking_fifo_in_ready;
            wire [DIRECT_MESSAGE_WIDTH-1: 0] blocking_fifo_out_data;
            wire blocking_fifo_out_valid;
            wire blocking_fifo_out_ready;
            wire [DIRECT_MESSAGE_WIDTH-1: 0] blocking_fifo_in_data;
            wire blocking_fifo_in_valid;
            wire blocking_fifo_in_ready;
            wire blocking_fifo_in_full;
            // wire [MASTER_FIFO_WIDTH-1: 0] master_fifo_out_data;
            // wire master_fifo_out_valid;
            // wire master_fifo_out_ready;
            // wire [MASTER_FIFO_WIDTH-1: 0] master_fifo_in_data;
            // wire master_fifo_in_valid;
            // wire master_fifo_in_ready;
            pu_arbitration_unit #(
                .CODE_DISTANCE(CODE_DISTANCE)
            ) u_pu_arbitration_unit (
                .clk(clk),
                .reset(reset),
                .neighbor_fifo_out_data(neighbor_fifo_out_data),
                .neighbor_fifo_out_valid(neighbor_fifo_out_valid),
                .neighbor_fifo_out_ready(neighbor_fifo_out_ready),
                .neighbor_fifo_in_data(neighbor_fifo_in_data),
                .neighbor_fifo_in_valid(neighbor_fifo_in_valid),
                .neighbor_fifo_in_ready(neighbor_fifo_in_ready),
                .non_blocking_fifo_out_data(non_blocking_fifo_out_data),
                .non_blocking_fifo_out_valid(non_blocking_fifo_out_valid),
                .non_blocking_fifo_out_ready(non_blocking_fifo_out_ready),
                .non_blocking_fifo_in_data(non_blocking_fifo_in_data),
                .non_blocking_fifo_in_valid(non_blocking_fifo_in_valid),
                .non_blocking_fifo_in_ready(non_blocking_fifo_in_ready),
                .blocking_fifo_out_data(blocking_fifo_out_data),
                .blocking_fifo_out_valid(blocking_fifo_out_valid),
                .blocking_fifo_out_ready(blocking_fifo_out_ready),
                .blocking_fifo_in_data(blocking_fifo_in_data),
                .blocking_fifo_in_valid(blocking_fifo_in_valid),
                .blocking_fifo_in_ready(blocking_fifo_in_ready),
                .master_fifo_out_data(`MASTER_FIFO_VEC(master_fifo_out_data_vector, `FIFO_INDEX(j, k))),
                .master_fifo_out_valid(`MASTER_FIFO_SIGNAL_VEC(master_fifo_out_valid_vector, `FIFO_INDEX(j, k))),
                .master_fifo_out_ready(`MASTER_FIFO_SIGNAL_VEC(master_fifo_out_ready_vector, `FIFO_INDEX(j, k))),
                .master_fifo_in_data(`MASTER_FIFO_VEC(master_fifo_in_data_vector, `FIFO_INDEX(j, k))),
                .master_fifo_in_valid(`MASTER_FIFO_SIGNAL_VEC(master_fifo_in_valid_vector, `FIFO_INDEX(j, k))),
                .master_fifo_in_ready(`MASTER_FIFO_SIGNAL_VEC(master_fifo_in_ready_vector, `FIFO_INDEX(j, k))),
                .has_flying_messages(`MASTER_FIFO_SIGNAL_VEC(arbitration_has_flying_messages, `FIFO_INDEX(j, k)))
            );

            assign blocking_fifo_in_full = ~blocking_fifo_in_ready;
        end
    end
endgenerate

`define NEIGHBOR_IDX_TOP(i, j, k) (0)
`define NEIGHBOR_IDX_BOTTOM(i, j, k) (i>0?1:0)
`define NEIGHBOR_IDX_LEFT(i, j, k) ((i>0?1:0) + (i<(CODE_DISTANCE-1)?1:0))
`define NEIGHBOR_IDX_RIGHT(i, j, k) ((i>0?1:0) + (i<(CODE_DISTANCE-1)?1:0) + (j>0?1:0))
`define NEIGHBOR_IDX_DOWN(i, j, k) ((i>0?1:0) + (i<(CODE_DISTANCE-1)?1:0) + (j>0?1:0) + (j<(CODE_DISTANCE-2)?1:0))
`define NEIGHBOR_IDX_UP(i, j, k) ((i>0?1:0) + (i<(CODE_DISTANCE-1)?1:0) + (j>0?1:0) + (j<(CODE_DISTANCE-2)?1:0) + (k>0?1:0))
`define PU(i, j, k) pu_k[k].pu_i[i].pu_j[j]
`define SLICE_ADDRESS_VEC(vec, idx) (vec[(((idx)+1)*ADDRESS_WIDTH)-1:(idx)*ADDRESS_WIDTH])
`define SLICE_UNION_MESSAGE_VEC(vec, idx) (vec[(((idx)+1)*UNION_MESSAGE_WIDTH)-1:(idx)*UNION_MESSAGE_WIDTH])
`define SLICE_DIRECT_MESSAGE_VEC(vec, idx) (vec[(((idx)+1)*DIRECT_MESSAGE_WIDTH)-1:(idx)*DIRECT_MESSAGE_WIDTH])
`define PU_FIFO(j, k) fifo_k[k].fifo_j[j]

// instantiate vertical neighbor link and connect signals properly
`define NEIGHBOR_VERTICAL_INSTANTIATE \
neighbor_link #(.LENGTH(NEIGHBOR_COST), .ADDRESS_WIDTH(ADDRESS_WIDTH)) neighbor_vertical (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), .is_fully_grown(`PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_BOTTOM(i, j, k)]),\
    .a_old_root_in(`PU(i, j, k).old_root), .a_increase(`PU(i, j, k).neighbor_increase),\
    .b_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k).neighbor_old_roots, `NEIGHBOR_IDX_BOTTOM(i, j, k))),\
    .b_old_root_in(`PU(i+1, j, k).old_root), .b_increase(`PU(i+1, j, k).neighbor_increase),\
    .a_old_root_out(`SLICE_ADDRESS_VEC(`PU(i+1, j, k).neighbor_old_roots, `NEIGHBOR_IDX_TOP(i+1, j, k)))\
);\
assign `PU(i+1, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_TOP(i+1, j, k)] = `PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_BOTTOM(i, j, k)];

`define NEIGHBOR_VERTICAL_TO_FIFO_INSTANTIATE_INPUT \
neighbor_link_to_fifo #(.LENGTH(NEIGHBOR_COST), .ADDRESS_WIDTH(ADDRESS_WIDTH)) neighbor_vertical_fifo (\
.clk(clk), .reset(reset), .initialize(initialize_neighbors), .is_fully_grown(`PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_BOTTOM(i, j, k)]), \
.a_old_root_in(`PU(i, j, k).old_root), .a_increase(`PU(i, j, k).neighbor_increase), \
.b_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k).neighbor_old_roots, `NEIGHBOR_IDX_BOTTOM(i, j, k))),\
 .neighbor_fifo_out_data(`PU_FIFO(j,k).neighbor_fifo_out_data),  \
 .neighbor_fifo_out_valid(`PU_FIFO(j,k).neighbor_fifo_out_valid), \
 .neighbor_fifo_out_ready(`PU_FIFO(j,k).neighbor_fifo_out_ready), \
 .neighbor_fifo_in_data(`PU_FIFO(j,k).neighbor_fifo_in_data), \
 .neighbor_fifo_in_valid(`PU_FIFO(j,k).neighbor_fifo_in_valid), \
 .neighbor_fifo_in_ready(`PU_FIFO(j,k).neighbor_fifo_in_ready) \
);

// Keep in mind a and b are interchanged 
`define NEIGHBOR_VERTICAL_TO_FIFO_INSTANTIATE_OUTPUT(i) \
neighbor_link_to_fifo #(.LENGTH(NEIGHBOR_COST), .ADDRESS_WIDTH(ADDRESS_WIDTH)) neighbor_vertical_fifo (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .is_fully_grown(`PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_TOP(i, j, k)]), \
    .a_old_root_in(`PU(i, j, k).old_root), .a_increase(`PU(i, j, k).neighbor_increase),\
    .b_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k).neighbor_old_roots, `NEIGHBOR_IDX_TOP(i, j, k))), \
    .neighbor_fifo_out_data(`PU_FIFO(j,k).neighbor_fifo_out_data), \
    .neighbor_fifo_out_valid(`PU_FIFO(j,k).neighbor_fifo_out_valid), \
    .neighbor_fifo_out_ready(`PU_FIFO(j,k).neighbor_fifo_out_ready), \
    .neighbor_fifo_in_data(`PU_FIFO(j,k).neighbor_fifo_in_data), \
    .neighbor_fifo_in_valid(`PU_FIFO(j,k).neighbor_fifo_in_valid), \
    .neighbor_fifo_in_ready(`PU_FIFO(j,k).neighbor_fifo_in_ready) \
);

// Uncertain about neighbor_vertical_fifo

`define NEIGHBOR_HORIZONTAL_TO_FIFO_INSTANTIATE_INPUT \
neighbor_link_to_fifo #(.LENGTH(NEIGHBOR_COST), .ADDRESS_WIDTH(ADDRESS_WIDTH)) neighbor_vertical_fifo (\
.clk(clk), .reset(reset), .initialize(initialize_neighbors), .is_fully_grown(`PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_BOTTOM(i, j, k)]), \
.a_old_root_in(`PU(i, j, k).old_root), .a_increase(`PU(i, j, k).neighbor_increase), \
.b_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k).neighbor_old_roots, `NEIGHBOR_IDX_BOTTOM(i, j, k))),\
 .neighbor_fifo_out_data(`PU_FIFO(j,k).neighbor_fifo_out_data),  \
 .neighbor_fifo_out_valid(`PU_FIFO(j,k).neighbor_fifo_out_valid), \
 .neighbor_fifo_out_ready(`PU_FIFO(j,k).neighbor_fifo_out_ready), \
 .neighbor_fifo_in_data(`PU_FIFO(j,k).neighbor_fifo_in_data), \
 .neighbor_fifo_in_valid(`PU_FIFO(j,k).neighbor_fifo_in_valid), \
 .neighbor_fifo_in_ready(`PU_FIFO(j,k).neighbor_fifo_in_ready) \
);

// Keep in mind a and b are interchanged 
`define NEIGHBOR_HORIZONTAL_TO_FIFO_INSTANTIATE_OUTPUT(i) \
neighbor_link_to_fifo #(.LENGTH(NEIGHBOR_COST), .ADDRESS_WIDTH(ADDRESS_WIDTH)) neighbor_vertical_fifo (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .is_fully_grown(`PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_TOP(i, j, k)]), \
    .a_old_root_in(`PU(i, j, k).old_root), .a_increase(`PU(i, j, k).neighbor_increase),\
    .b_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k).neighbor_old_roots, `NEIGHBOR_IDX_TOP(i, j, k))), \
    .neighbor_fifo_out_data(`PU_FIFO(j,k).neighbor_fifo_out_data), \
    .neighbor_fifo_out_valid(`PU_FIFO(j,k).neighbor_fifo_out_valid), \
    .neighbor_fifo_out_ready(`PU_FIFO(j,k).neighbor_fifo_out_ready), \
    .neighbor_fifo_in_data(`PU_FIFO(j,k).neighbor_fifo_in_data), \
    .neighbor_fifo_in_valid(`PU_FIFO(j,k).neighbor_fifo_in_valid), \
    .neighbor_fifo_in_ready(`PU_FIFO(j,k).neighbor_fifo_in_ready) \
);

// instantiate horizontal neighbor link and connect signals properly
`define NEIGHBOR_HORIZONTAL_INSTANTIATE \
neighbor_link #(.LENGTH(NEIGHBOR_COST), .ADDRESS_WIDTH(ADDRESS_WIDTH)) neighbor_horizontal (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), .is_fully_grown(`PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_RIGHT(i, j, k)]),\
    .a_old_root_in(`PU(i, j, k).old_root), .a_increase(`PU(i, j, k).neighbor_increase),\
    .b_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k).neighbor_old_roots, `NEIGHBOR_IDX_RIGHT(i, j, k))),\
    .b_old_root_in(`PU(i, j+1, k).old_root), .b_increase(`PU(i, j+1, k).neighbor_increase),\
    .a_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j+1, k).neighbor_old_roots, `NEIGHBOR_IDX_LEFT(i, j+1, k)))\
);\
assign `PU(i, j+1, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_LEFT(i, j+1, k)] = `PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_RIGHT(i, j, k)];

// instantiate updown neighbor link and connect signals properly
`define NEIGHBOR_UPDOWN_INSTANTIATE \
neighbor_link #(.LENGTH(NEIGHBOR_COST), .ADDRESS_WIDTH(ADDRESS_WIDTH)) neighbor_updown (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), .is_fully_grown(`PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_UP(i, j, k)]),\
    .a_old_root_in(`PU(i, j, k).old_root), .a_increase(`PU(i, j, k).neighbor_increase),\
    .b_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k).neighbor_old_roots, `NEIGHBOR_IDX_UP(i, j, k))),\
    .b_old_root_in(`PU(i, j, k+1).old_root), .b_increase(`PU(i, j, k+1).neighbor_increase),\
    .a_old_root_out(`SLICE_ADDRESS_VEC(`PU(i, j, k+1).neighbor_old_roots, `NEIGHBOR_IDX_DOWN(i, j, k+1)))\
);\
assign `PU(i, j, k+1).neighbor_is_fully_grown[`NEIGHBOR_IDX_DOWN(i, j, k+1)] = `PU(i, j, k).neighbor_is_fully_grown[`NEIGHBOR_IDX_UP(i, j, k)];

// instantiate vertical union channels and connect signals properly
`define UNION_CHANNEL_VERTICAL_INSTANTIATE \
nonblocking_channel #(.WIDTH(UNION_MESSAGE_WIDTH)) nonblocking_channel_bottom (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors),\
    .in_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j, k).union_out_channels_data, `NEIGHBOR_IDX_BOTTOM(i, j, k))),\
    .in_valid(`PU(i, j, k).union_out_channels_valid),\
    .out_data(`SLICE_UNION_MESSAGE_VEC(`PU(i+1, j, k).union_in_channels_data, `NEIGHBOR_IDX_TOP(i+1, j, k))),\
    .out_valid(`PU(i+1, j, k).union_in_channels_valid[`NEIGHBOR_IDX_TOP(i+1, j, k)])\
);\
nonblocking_channel #(.WIDTH(UNION_MESSAGE_WIDTH)) nonblocking_channel_top (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`SLICE_UNION_MESSAGE_VEC(`PU(i+1, j, k).union_out_channels_data, `NEIGHBOR_IDX_TOP(i+1, j, k))),\
    .in_valid(`PU(i+1, j, k).union_out_channels_valid),\
    .out_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j, k).union_in_channels_data, `NEIGHBOR_IDX_BOTTOM(i, j, k))),\
    .out_valid(`PU(i, j, k).union_in_channels_valid[`NEIGHBOR_IDX_BOTTOM(i, j, k)])\
);

`define UNION_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_INPUT \
nonblocking_channel_to_fifo #(.WIDTH(UNION_MESSAGE_WIDTH)) nonblocking_channel_bottom (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j, k).union_out_channels_data, `NEIGHBOR_IDX_BOTTOM(i, j, k))),\
    .in_valid(`PU(i, j, k).union_out_channels_valid), \
    .nonblocking_fifo_out_ready(`PU_FIFO(j,k).non_blocking_fifo_out_ready), \
    .nonblocking_fifo_out_data(`PU_FIFO(j,k).non_blocking_fifo_out_data),  \
    .nonblocking_fifo_out_valid(`PU_FIFO(j,k).non_blocking_fifo_out_valid) \
); \
nonblocking_channel_from_fifo #(.WIDTH(UNION_MESSAGE_WIDTH)) nonblocking_channel_top ( \
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    // .in_data(`SLICE_UNION_MESSAGE_VEC(`PU(i+1, j, k).union_out_channels_data, `NEIGHBOR_IDX_TOP(i+1, j, k))),\
    // .in_valid(`PU(i+1, j, k).union_out_channels_valid),\
    .out_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j, k).union_in_channels_data, `NEIGHBOR_IDX_BOTTOM(i, j, k))),\
    .out_valid(`PU(i, j, k).union_in_channels_valid[`NEIGHBOR_IDX_BOTTOM(i, j, k)]),\
    .nonblocking_fifo_in_data(`PU_FIFO(j,k).non_blocking_fifo_in_data), \
    .nonblocking_fifo_in_valid(`PU_FIFO(j,k).non_blocking_fifo_in_valid), \
    .nonblocking_fifo_in_ready(`PU_FIFO(j,k).non_blocking_fifo_in_ready) \
);

`define UNION_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_OUTPUT(i) \
nonblocking_channel_from_fifo #(.WIDTH(UNION_MESSAGE_WIDTH)) nonblocking_channel_bottom (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors),\
    // .in_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j, k).union_out_channels_data, `NEIGHBOR_IDX_BOTTOM(i, j, k))),\
    // .in_valid(`PU(i, j, k).union_out_channels_valid),\
    .out_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j, k).union_in_channels_data, `NEIGHBOR_IDX_TOP(i, j, k))),\
    .out_valid(`PU(i, j, k).union_in_channels_valid[`NEIGHBOR_IDX_TOP(i, j, k)]), \
    .nonblocking_fifo_in_data(`PU_FIFO(j,k).non_blocking_fifo_in_data), \
    .nonblocking_fifo_in_valid(`PU_FIFO(j,k).non_blocking_fifo_in_valid), \
    .nonblocking_fifo_in_ready(`PU_FIFO(j,k).non_blocking_fifo_in_ready) \
);\
nonblocking_channel_to_fifo #(.WIDTH(UNION_MESSAGE_WIDTH)) nonblocking_channel_top (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j, k).union_out_channels_data, `NEIGHBOR_IDX_TOP(i, j, k))),\
    .in_valid(`PU(i, j, k).union_out_channels_valid), \
    .nonblocking_fifo_out_data(`PU_FIFO(j,k).non_blocking_fifo_out_data), \
    .nonblocking_fifo_out_valid(`PU_FIFO(j,k).non_blocking_fifo_out_valid), \
    .nonblocking_fifo_out_ready(`PU_FIFO(j,k).non_blocking_fifo_out_ready) \
);

// instantiate horizontal union channels and connect signals properly
`define UNION_CHANNEL_HORIZONTAL_INSTANTIATE \
nonblocking_channel #(.WIDTH(UNION_MESSAGE_WIDTH)) nonblocking_channel_right (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j, k).union_out_channels_data, `NEIGHBOR_IDX_RIGHT(i, j, k))),\
    .in_valid(`PU(i, j, k).union_out_channels_valid),\
    .out_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j+1, k).union_in_channels_data, `NEIGHBOR_IDX_LEFT(i, j+1, k))),\
    .out_valid(`PU(i, j+1, k).union_in_channels_valid[`NEIGHBOR_IDX_LEFT(i, j+1, k)])\
);\
nonblocking_channel #(.WIDTH(UNION_MESSAGE_WIDTH)) nonblocking_channel_left (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j+1, k).union_out_channels_data, `NEIGHBOR_IDX_LEFT(i, j+1, k))),\
    .in_valid(`PU(i, j+1, k).union_out_channels_valid),\
    .out_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j, k).union_in_channels_data, `NEIGHBOR_IDX_RIGHT(i, j, k))),\
    .out_valid(`PU(i, j, k).union_in_channels_valid[`NEIGHBOR_IDX_RIGHT(i, j, k)])\
);

// instantiate updown union channels and connect signals properly
`define UNION_CHANNEL_UPDOWN_INSTANTIATE \
nonblocking_channel #(.WIDTH(UNION_MESSAGE_WIDTH)) nonblocking_channel_up (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j, k).union_out_channels_data, `NEIGHBOR_IDX_UP(i, j, k))),\
    .in_valid(`PU(i, j, k).union_out_channels_valid),\
    .out_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j, k+1).union_in_channels_data, `NEIGHBOR_IDX_DOWN(i, j, k+1))),\
    .out_valid(`PU(i, j, k+1).union_in_channels_valid[`NEIGHBOR_IDX_DOWN(i, j, k+1)])\
);\
nonblocking_channel #(.WIDTH(UNION_MESSAGE_WIDTH)) nonblocking_channel_down (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j, k+1).union_out_channels_data, `NEIGHBOR_IDX_DOWN(i, j, k+1))),\
    .in_valid(`PU(i, j, k+1).union_out_channels_valid),\
    .out_data(`SLICE_UNION_MESSAGE_VEC(`PU(i, j, k).union_in_channels_data, `NEIGHBOR_IDX_UP(i, j, k))),\
    .out_valid(`PU(i, j, k).union_in_channels_valid[`NEIGHBOR_IDX_UP(i, j, k)])\
);

// instantiate vertical direct channels and connect signals properly
`define DIRECT_CHANNEL_VERTICAL_TO_FIFO_INPUT \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH)) blocking_channel_top (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU_FIFO(j,k).blocking_fifo_in_data),\
    .in_valid(`PU_FIFO(j,k).blocking_fifo_in_valid),\
    .in_is_full(`PU_FIFO(j,k).blocking_fifo_in_full),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j, k).direct_in_channels_data, 0)),\
    .out_valid(`PU(i, j, k).direct_in_channels_valid[0]),\
    .out_is_taken(`PU(i, j, k).direct_in_channels_is_taken[0])\
);

`define DIRECT_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_OUTPUT(i) \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH)) blocking_channel_top_to_fifo (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU((i)%CODE_DISTANCE, j, k).direct_out_channels_data_single),\
    .in_valid(`PU((i)%CODE_DISTANCE, j, k).direct_out_channels_valid[0]),\
    .in_is_full(`PU((i)%CODE_DISTANCE, j, k).direct_out_channels_is_full[0]),\
    .out_data(`PU_FIFO(j,k).blocking_fifo_out_data),\
    .out_valid(`PU_FIFO(j,k).blocking_fifo_out_valid),\
    .out_is_taken(`PU_FIFO(j,k).blocking_fifo_out_ready)\
);

`define DIRECT_CHANNEL_VERTICAL_INSTANTIATE \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH)) blocking_channel_top (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU((i+1)%CODE_DISTANCE, j, k).direct_out_channels_data_single),\
    .in_valid(`PU((i+1)%CODE_DISTANCE, j, k).direct_out_channels_valid[0]),\
    .in_is_full(`PU((i+1)%CODE_DISTANCE, j, k).direct_out_channels_is_full[0]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j, k).direct_in_channels_data, 0)),\
    .out_valid(`PU(i, j, k).direct_in_channels_valid[0]),\
    .out_is_taken(`PU(i, j, k).direct_in_channels_is_taken[0])\
);

`define DIRECT_CHANNEL_VERTICAL_WRAP_INSTANTIATE_INPUT(i) \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH), .DEPTH(128)) blocking_channel_top (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU((i+1)%CODE_DISTANCE, j, k).direct_out_channels_data_single),\
    .in_valid(`PU((i+1)%CODE_DISTANCE, j, k).direct_out_channels_valid[0]),\
    .in_is_full(`PU((i+1)%CODE_DISTANCE, j, k).direct_out_channels_is_full[0]), \
    .out_data(`PU_FIFO(j,k).blocking_fifo_out_data),\
    .out_valid(`PU_FIFO(j,k).blocking_fifo_out_valid),\
    .out_is_taken(`PU_FIFO(j,k).blocking_fifo_out_ready)\
);

`define DIRECT_CHANNEL_VERTICAL_WRAP_INSTANTIATE_OUTPUT(i) \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH), .DEPTH(128)) blocking_channel_top_wrap_fifo (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU_FIFO(j,k).blocking_fifo_in_data),\
    .in_valid(`PU_FIFO(j,k).blocking_fifo_in_valid),\
    .in_is_full(`PU_FIFO(j,k).blocking_fifo_in_full),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j, k).direct_in_channels_data, 0)),\
    .out_valid(`PU(i, j, k).direct_in_channels_valid[0]),\
    .out_is_taken(`PU(i, j, k).direct_in_channels_is_taken[0])\
);\
assign `PU_FIFO(j,k).blocking_fifo_in_ready = !(`PU_FIFO(j,k).blocking_fifo_in_full); 

// instantiate horizontal direct channels and connect signals properly
`define DIRECT_CHANNEL_HORIZONTAL_INSTANTIATE \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH)) blocking_channel_left (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU(i, (j+1)%(CODE_DISTANCE-1), k).direct_out_channels_data_single),\
    .in_valid(`PU(i, (j+1)%(CODE_DISTANCE-1), k).direct_out_channels_valid[1]),\
    .in_is_full(`PU(i, (j+1)%(CODE_DISTANCE-1), k).direct_out_channels_is_full[1]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j, k).direct_in_channels_data, 1)),\
    .out_valid(`PU(i, j, k).direct_in_channels_valid[1]),\
    .out_is_taken(`PU(i, j, k).direct_in_channels_is_taken[1])\
);

`define DIRECT_CHANNEL_HORIZONTAL_WRAP_INSTANTIATE \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH), .DEPTH(128)) blocking_channel_left (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU(i, (j+1)%(CODE_DISTANCE-1), k).direct_out_channels_data_single),\
    .in_valid(`PU(i, (j+1)%(CODE_DISTANCE-1), k).direct_out_channels_valid[1]),\
    .in_is_full(`PU(i, (j+1)%(CODE_DISTANCE-1), k).direct_out_channels_is_full[1]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j, k).direct_in_channels_data, 1)),\
    .out_valid(`PU(i, j, k).direct_in_channels_valid[1]),\
    .out_is_taken(`PU(i, j, k).direct_in_channels_is_taken[1])\
);

// instantiate horizontal direct channels and connect signals properly
`define DIRECT_CHANNEL_UPDOWN_INSTANTIATE \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH)) blocking_channel_down (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU(i, j, (k+1)%CODE_DISTANCE).direct_out_channels_data_single),\
    .in_valid(`PU(i, j, (k+1)%CODE_DISTANCE).direct_out_channels_valid[2]),\
    .in_is_full(`PU(i, j, (k+1)%CODE_DISTANCE).direct_out_channels_is_full[2]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j, k).direct_in_channels_data, 2)),\
    .out_valid(`PU(i, j, k).direct_in_channels_valid[2]),\
    .out_is_taken(`PU(i, j, k).direct_in_channels_is_taken[2])\
);

`define DIRECT_CHANNEL_UPDOWN_WRAP_INSTANTIATE \
blocking_channel #(.WIDTH(DIRECT_MESSAGE_WIDTH), .DEPTH(128)) blocking_channel_down (\
    .clk(clk), .reset(reset), .initialize(initialize_neighbors), \
    .in_data(`PU(i, j, (k+1)%CODE_DISTANCE).direct_out_channels_data_single),\
    .in_valid(`PU(i, j, (k+1)%CODE_DISTANCE).direct_out_channels_valid[2]),\
    .in_is_full(`PU(i, j, (k+1)%CODE_DISTANCE).direct_out_channels_is_full[2]),\
    .out_data(`SLICE_DIRECT_MESSAGE_VEC(`PU(i, j, k).direct_in_channels_data, 2)),\
    .out_valid(`PU(i, j, k).direct_in_channels_valid[2]),\
    .out_is_taken(`PU(i, j, k).direct_in_channels_is_taken[2])\
);

// instantiate vertical and horizontal links and channels
`define VERTICAL_INSTANTIATE \
`NEIGHBOR_VERTICAL_INSTANTIATE \
`UNION_CHANNEL_VERTICAL_INSTANTIATE \
`DIRECT_CHANNEL_VERTICAL_INSTANTIATE

`define HORIZONTAL_INSTANTIATE \
`NEIGHBOR_HORIZONTAL_INSTANTIATE \
`UNION_CHANNEL_HORIZONTAL_INSTANTIATE

`define UPDOWN_INSTANTIATE \
`NEIGHBOR_UPDOWN_INSTANTIATE \
`UNION_CHANNEL_UPDOWN_INSTANTIATE

// instantiate neighbor links and channels
generate
    for (k=0; k < CODE_DISTANCE; k=k+1) begin: neighbor_k
        for (i=0; i < CODE_DISTANCE; i=i+1) begin: neighbor_i
            for (j=0; j < CODE_DISTANCE-1; j=j+1) begin: neighbor_j
                if (i >= $$GEN2_LOW && i < $$GEN2_HIGH) begin
                     if (i < $$GEN2_HIGH - 1) begin
                         `VERTICAL_INSTANTIATE
                     end else if ($$GEN2_HIGH == CODE_DISTANCE-1) begin
                         `NEIGHBOR_VERTICAL_TO_FIFO_INSTANTIATE_INPUT
                         `UNION_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_INPUT
                         `DIRECT_CHANNEL_VERTICAL_TO_FIFO_INPUT
                     end
                     
                     if (j < (CODE_DISTANCE-2)) begin
                         `HORIZONTAL_INSTANTIATE
                         `DIRECT_CHANNEL_HORIZONTAL_INSTANTIATE
                     end else begin
                         `DIRECT_CHANNEL_HORIZONTAL_WRAP_INSTANTIATE
                     end
                     
                     if (k < (CODE_DISTANCE-1)) begin
                         `UPDOWN_INSTANTIATE
                         `DIRECT_CHANNEL_UPDOWN_INSTANTIATE
                     end else begin
                         `DIRECT_CHANNEL_UPDOWN_WRAP_INSTANTIATE
                     end
                end
            end
        end
    end
endgenerate

generate
    for (k=0; k < CODE_DISTANCE; k=k+1) begin: neighbor_k_extra
        for (j=0; j < CODE_DISTANCE-1; j=j+1) begin: neighbor_j_extra
            if($$GEN2_LOW != 0) begin
                EIGHBOR_VERTICAL_TO_FIFO_INSTANTIATE_OUTPUT($$GEN2_LOW)
                `UNION_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_OUTPUT($$GEN2_LOW)
                `DIRECT_CHANNEL_VERTICAL_TO_FIFO_INSTANTIATE_OUTPUT($$GEN2_LOW)
            end else begin
                `DIRECT_CHANNEL_VERTICAL_WRAP_INSTANTIATE_INPUT(CODE_DISTANCE - 1)
            end
            if($$GEN2_HIGH == CODE_DISTANCE) begin
                `DIRECT_CHANNEL_VERTICAL_WRAP_INSTANTIATE_OUTPUT(CODE_DISTANCE - 1)
            end
        end
    end
endgenerate

endmodule
