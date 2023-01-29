`timescale 1ns / 1ps

// Right now this code is written targeting syndromes touching the X boundry
// Therefore boundry cost Z , UD , has boundry z UD is the only used parameter

module processing_unit #(
    parameter ADDRESS_WIDTH = 15,  // width of address, e.g. single measurement standard surface code under d <= 15 could be 4bit * 2 = 8bit
    parameter DISTANCE_WIDTH = 6,  // the maximum distance between two nodes should fit into DISTANCE_WIDTH bits
    parameter BOUNDARY_WIDTH = 2,  // usually boundary cost would be 2, so by default 2 bits for boundary cost
    parameter NEIGHBOR_COUNT = 6,  // the direct neighbor of a stabilizer, usually between 2 and 4 for surface code
    parameter FAST_CHANNEL_COUNT = 0,  // CHANNEL_COUNT = NEIGHBOR_COUNT + FAST_CHANNEL_COUNT
    parameter I = 1,
    parameter J = 2,
    parameter K = 6,
    parameter CODE_DISTANCE_X = 27,
    parameter CODE_DISTANCE_Z = 26,
    parameter MEASUREMENT_ROUNDS = 27,
    parameter INIT_BOUNDARY_COST_X = 2,
    parameter INIT_BOUNDARY_COST_Z = 2,
    parameter INIT_BOUNDARY_COST_UD = 2,
    parameter DIRECT_CHANNEL_COUNT = 3
) (
    clk,
    reset,
    // input data. The error syndrome read in STAGE_MEASUREMENT_LOADING
    init_is_error_syndrome,
    // stage indicator
    stage_in,
    // neighbor links
    neighbor_is_fully_grown,
    neighbor_is_odd_cluster,
    neighbor_roots,  // connect to *_old_root_out
    neighbor_increase,  // connect to *_increase
    // direct channels using `blocking_channel`
    direct_out_channels_data_single,
    direct_out_channels_valid,
    direct_out_channels_is_full,
    direct_in_channels_data,
    direct_in_channels_valid,
    direct_in_channels_is_taken,
    // internal states are also published
    old_root,
    updated_root,
    is_error_syndrome,
    is_odd_cluster,
    is_touching_boundary,
    is_odd_cardinality,
    pending_tell_new_root_touching_boundary,
    is_processing
);

`include "../../parameters/parameters.sv"

localparam CHANNEL_COUNT = NEIGHBOR_COUNT + FAST_CHANNEL_COUNT;
localparam CHANNEL_WIDTH = $clog2(CHANNEL_COUNT);  // the index of channel, both neighbor and direct ones
localparam DIRECT_CHANNEL_WIDTH = $clog2(DIRECT_CHANNEL_COUNT);
localparam UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH;  // [old_root, updated_root]
localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]
localparam PER_DIMENSION_WIDTH = DISTANCE_WIDTH - 1;

localparam CHANNEL_DEPTH = $clog2(CHANNEL_COUNT); //2
localparam DIRECT_CHANNEL_DEPTH = $clog2(DIRECT_CHANNEL_COUNT); //2
localparam CHANNEL_EXPAND_COUNT = 2 ** CHANNEL_DEPTH; //4
localparam DIRECT_CHANNEL_EXPAND_COUNT = 2 ** DIRECT_CHANNEL_DEPTH; //4
localparam CHANNEL_ALL_EXPAND_COUNT = 2 * CHANNEL_EXPAND_COUNT - 1;  // the length of tree structured gathering // 7
localparam DIRECT_CHANNEL_ALL_EXPAND_COUNT = 2 * DIRECT_CHANNEL_EXPAND_COUNT - 1;  // the length of tree structured gathering // 7

input clk;
input reset;

// initialization whether the syndrome is an error or not
input init_is_error_syndrome;

// stage indicator
input [STAGE_WIDTH-1:0] stage_in;

// neighbor links using `neighbor_link` module
input [NEIGHBOR_COUNT-1:0] neighbor_is_fully_grown;
input [NEIGHBOR_COUNT-1:0] neighbor_is_odd_cluster;
input [(ADDRESS_WIDTH * NEIGHBOR_COUNT)-1:0] neighbor_roots; 
output neighbor_increase;

// direct channels using `blocking_channel`, each message is packed [receiver, is_odd_cardinality, is_touching_boundary]
// Each message tells to the root of the new cluster we merged into whether I'm odd or whether I'm touching the boundry

output [DIRECT_MESSAGE_WIDTH-1:0] direct_out_channels_data_single;
output [DIRECT_CHANNEL_COUNT-1:0] direct_out_channels_valid;
input [DIRECT_CHANNEL_COUNT-1:0] direct_out_channels_is_full;
input [(DIRECT_MESSAGE_WIDTH * DIRECT_CHANNEL_COUNT)-1:0] direct_in_channels_data;
input [DIRECT_CHANNEL_COUNT-1:0] direct_in_channels_valid;
output [DIRECT_CHANNEL_COUNT-1:0] direct_in_channels_is_taken;

// internal states
reg [ADDRESS_WIDTH-1:0] address;  // my address
output reg [ADDRESS_WIDTH-1:0] old_root; // My root before current iteration
output reg [ADDRESS_WIDTH-1:0] updated_root; // My root during current iteration

// REgistered stage
reg [STAGE_WIDTH-1:0] last_stage;
reg [STAGE_WIDTH-1:0] stage;
reg [STAGE_WIDTH-1:0] stage_delayed;

output reg is_error_syndrome;

reg has_boundary_x;
reg has_boundary_z;
reg has_boundary_ud;
reg [BOUNDARY_WIDTH-1:0] boundary_cost_x;
reg [BOUNDARY_WIDTH-1:0] boundary_cost_z;
reg [BOUNDARY_WIDTH-1:0] boundary_cost_ud;

output reg is_odd_cluster;
output reg is_touching_boundary;
output reg is_odd_cardinality;
output reg pending_tell_new_root_touching_boundary;
output is_processing;

reg [BOUNDARY_WIDTH-1:0] boundary_increased_x;
reg [BOUNDARY_WIDTH-1:0] boundary_increased_z;
reg [BOUNDARY_WIDTH-1:0] boundary_increased_ud;

reg neighbor_changed;
reg neighbor_changed_delayed;

wire [ADDRESS_WIDTH-1:0] compare_solver_default_addr;
wire [(ADDRESS_WIDTH * CHANNEL_COUNT)-1:0] compare_solver_addrs;
wire [CHANNEL_COUNT-1:0] compare_solver_addrs_valid;
wire [ADDRESS_WIDTH-1:0] compare_solver_result;
reg [ADDRESS_WIDTH-1:0] compare_solver_result_stored;

wire [ADDRESS_WIDTH-1:0] init_address;
assign init_address[ADDRESS_WIDTH-1:PER_DIMENSION_WIDTH*2] = K;
assign init_address[PER_DIMENSION_WIDTH*2-1:PER_DIMENSION_WIDTH] = I;
assign init_address[PER_DIMENSION_WIDTH-1:0] = J;

`define init_has_boundary_x(i, j, k) (0)
`define init_has_boundary_z(i, j, k) ((j==0) || (j==CODE_DISTANCE_Z - 1))
`define init_has_boundary_ud(i, j, k) (k==0 )
wire init_has_boundary_x;
wire init_has_boundary_z;
wire init_has_boundary_ud;
assign init_has_boundary_x = `init_has_boundary_x(I, J, K);
assign init_has_boundary_z = `init_has_boundary_z(I, J, K);
assign init_has_boundary_ud = `init_has_boundary_ud(I, J, K);

wire [BOUNDARY_WIDTH-1:0] init_boundary_cost_x;
wire [BOUNDARY_WIDTH-1:0] init_boundary_cost_z;
wire [BOUNDARY_WIDTH-1:0] init_boundary_cost_ud;
assign init_boundary_cost_x = INIT_BOUNDARY_COST_X;
assign init_boundary_cost_z = INIT_BOUNDARY_COST_Z;
assign init_boundary_cost_ud = INIT_BOUNDARY_COST_UD;

genvar i;

// Acess individual elements from the packed array
`define compare_solver_addr(i) compare_solver_addrs[((i+1) * ADDRESS_WIDTH) - 1 : (i * ADDRESS_WIDTH)]
`define compare_solver_valid(i) compare_solver_addrs_valid[i]
`define direct_out_valid(i) direct_out_channels_valid[i]
`define direct_out_is_full(i) direct_out_channels_is_full[i]
`define direct_in_data(i) direct_in_channels_data[((i+1) * DIRECT_MESSAGE_WIDTH) - 1 : (i * DIRECT_MESSAGE_WIDTH)]
`define direct_in_data_receiver(i) direct_in_channels_data[((i+1) * DIRECT_MESSAGE_WIDTH) - 1 : (i * DIRECT_MESSAGE_WIDTH) + 2]
`define direct_in_data_is_odd_cardinality(i) direct_in_channels_data[(i * DIRECT_MESSAGE_WIDTH) + 1]
`define direct_in_data_is_touching_boundary(i) direct_in_channels_data[(i * DIRECT_MESSAGE_WIDTH)]
`define direct_in_valid(i) direct_in_channels_valid[i]
`define direct_in_is_taken(i) direct_in_channels_is_taken[i]

// i defined in range [0, NEIGHBOR_COUNT)
`define is_fully_grown(i) neighbor_is_fully_grown[i]
`define neighbor_is_odd_cluster(i) neighbor_is_odd_cluster[i]
`define neighbor_root(i) neighbor_roots[((i+1) * ADDRESS_WIDTH) - 1 : (i * ADDRESS_WIDTH)]
`define channel_addresses_k(idx) channel_addresses[(idx+1)*ADDRESS_WIDTH-1 : idx*ADDRESS_WIDTH+2*PER_DIMENSION_WIDTH]
`define channel_addresses_i(idx) channel_addresses[(idx+1)*ADDRESS_WIDTH-1-PER_DIMENSION_WIDTH : idx*ADDRESS_WIDTH+PER_DIMENSION_WIDTH]
`define channel_addresses_j(idx) channel_addresses[(idx+1)*ADDRESS_WIDTH-1-2*PER_DIMENSION_WIDTH : idx*ADDRESS_WIDTH]

// tree structured information gathering for direct channels
`define CHANNEL_LAYER_WIDTH (2 ** (CHANNEL_DEPTH - 1 - i))
`define CHANNEL_LAYERT_IDX (2 ** (CHANNEL_DEPTH + 1) - 2 ** (CHANNEL_DEPTH - i))
`define CHANNEL_LAST_LAYERT_IDX (2 ** (CHANNEL_DEPTH + 1) - 2 ** (CHANNEL_DEPTH + 1 - i))
`define CHANNEL_CURRENT_IDX (`CHANNEL_LAYERT_IDX + j)
`define CHANNEL_CHILD_1_IDX (`CHANNEL_LAST_LAYERT_IDX + 2 * j)
`define CHANNEL_CHILD_2_IDX (`CHANNEL_CHILD_1_IDX + 1)
localparam CHANNEL_ROOT_IDX = CHANNEL_ALL_EXPAND_COUNT - 1; // 6

`define DIRECT_CHANNEL_LAYER_WIDTH (2 ** (DIRECT_CHANNEL_DEPTH - 1 - i))
`define DIRECT_CHANNEL_LAYERT_IDX (2 ** (DIRECT_CHANNEL_DEPTH + 1) - 2 ** (DIRECT_CHANNEL_DEPTH - i))
`define DIRECT_CHANNEL_LAST_LAYERT_IDX (2 ** (DIRECT_CHANNEL_DEPTH + 1) - 2 ** (DIRECT_CHANNEL_DEPTH + 1 - i))
`define DIRECT_CHANNEL_CURRENT_IDX (`DIRECT_CHANNEL_LAYERT_IDX + j)
`define DIRECT_CHANNEL_CHILD_1_IDX (`DIRECT_CHANNEL_LAST_LAYERT_IDX + 2 * j)
`define DIRECT_CHANNEL_CHILD_2_IDX (`DIRECT_CHANNEL_CHILD_1_IDX + 1)
localparam DIRECT_CHANNEL_ROOT_IDX = DIRECT_CHANNEL_ALL_EXPAND_COUNT - 1; // 6

// -----------------------------STAGE_SPREAD_CLUSTER : PART A ------------------------------------------------------//
// Check whether if any of my fully connected neighbors have a better root than me.
// If so get that root and message that root that I joined him

wire is_stage_spread_cluster;
assign is_stage_spread_cluster = (stage == STAGE_SPREAD_CLUSTER);
assign is_stage_spread_cluster_delayed = (stage_delayed == STAGE_SPREAD_CLUSTER);

// Step 1 : filter the fully connected roots
wire [ADDRESS_WIDTH-1:0] new_updated_root;
assign compare_solver_default_addr = updated_root;
generate
    for (i=0; i < CHANNEL_COUNT; i=i+1) begin: compare_new_updated_root
        wire [ADDRESS_WIDTH-1:0] elected_updated_root;
        wire elected_valid;
        if (i < NEIGHBOR_COUNT) begin  // first for neighbors
            // if has union message in the channel, use that one; otherwise use the old_root from neighbor link
            assign elected_valid = `is_fully_grown(i);
            assign elected_updated_root = `neighbor_root(i);
        end else begin  // then for non-neighbors (fast channels only)
            // Unsupported
        end
        assign `compare_solver_addr(i) = elected_updated_root;
        assign `compare_solver_valid(i) = elected_valid;
    end
endgenerate

// Step 2 fed them to the compare solver tree
tree_compare_solver #(
    .DATA_WIDTH(ADDRESS_WIDTH),
    .CHANNEL_COUNT(NEIGHBOR_COUNT)
) u_tree_compare_solver (
    .default_value(compare_solver_default_addr),
    .values(compare_solver_addrs),
    .valids(compare_solver_addrs_valid),
    .result(compare_solver_result)
);

assign new_updated_root = compare_solver_result;  // combinational logic that computes within a sinlge clock cycle

// Step 3 : Make the direct message to send if my root changed
// compute `intermediate_pending_tell_new_root_cardinality` and `intermediate_pending_tell_new_root_touching_boundary`
wire intermediate_pending_tell_new_root_cardinality;
wire intermediate_pending_tell_new_root_touching_boundary;
assign intermediate_pending_tell_new_root_cardinality = 
    new_updated_root != updated_root && is_error_syndrome ;
assign intermediate_pending_tell_new_root_touching_boundary = 
     ((new_updated_root != updated_root && updated_is_touching_boundary) || (updated_is_touching_boundary != is_touching_boundary));

wire generate_my_direct_message;
assign generate_my_direct_message = intermediate_pending_tell_new_root_cardinality || intermediate_pending_tell_new_root_touching_boundary;

// Step 4 : store that direct message to send later.
// We don;t send it immediately as priority is given to messages already in the grid
reg my_stored_direct_message_valid;
reg [DIRECT_MESSAGE_WIDTH-1:0] my_stored_direct_message;

always@(posedge clk) begin
    if (generate_my_direct_message) begin
        my_stored_direct_message <= { new_updated_root, intermediate_pending_tell_new_root_cardinality, intermediate_pending_tell_new_root_touching_boundary };
    end
end


// ------------------------------------------------------------------------------------------------------------------------------//

// -----------------------------STAGE_SPREAD_CLUSTER : PART B ------------------------------------------------------//
// For roots which have received that someone has joined the cluster that I'm a root of

// Part 1 : Find whether the message is addressed to me
wire [DIRECT_CHANNEL_COUNT-1:0] direct_in_channels_local_handled;
wire [DIRECT_CHANNEL_COUNT-1:0] direct_in_channels_address_matched;
generate
    for (i=0; i < DIRECT_CHANNEL_COUNT; i=i+1) begin: direct_in_channels_local_handling
        assign direct_in_channels_address_matched[i] = (`direct_in_data_receiver(i) == address);
        assign direct_in_channels_local_handled[i] = `direct_in_valid(i) && direct_in_channels_address_matched[i];
    end
endgenerate

// Part2 : If so update my cardinality and whether I'm touching the boundry or not
wire [DIRECT_CHANNEL_COUNT-1:0] direct_in_channels_data_is_odd_cardinality;
wire [DIRECT_CHANNEL_COUNT-1:0] direct_in_channels_data_is_touching_boundary;
generate
    for (i=0; i < DIRECT_CHANNEL_COUNT; i=i+1) begin: splitting_direct_in_channel_messages
        assign direct_in_channels_data_is_odd_cardinality[i] = `direct_in_data_is_odd_cardinality(i);
        assign direct_in_channels_data_is_touching_boundary[i] = `direct_in_data_is_touching_boundary(i);
    end
endgenerate

`define gathered_is_odd_cardinality (^(direct_in_channels_local_handled & direct_in_channels_data_is_odd_cardinality))
`define gathered_is_touching_boundary (|(direct_in_channels_local_handled & direct_in_channels_data_is_touching_boundary))

// compute `updated_is_touching_boundary`
wire updated_is_touching_boundary;
assign updated_is_touching_boundary = is_touching_boundary 
    || (has_boundary_z && (boundary_increased_z == boundary_cost_z)) 
    || (has_boundary_ud && (boundary_increased_ud == boundary_cost_ud))
    || `gathered_is_touching_boundary;

// compute `updated_is_odd_cardinality`
wire updated_is_odd_cardinality;
assign updated_is_odd_cardinality = is_odd_cardinality ^ `gathered_is_odd_cardinality;

// Part 3 : If message is not addressed to me then I must propagate the message.
// So I must pick one of the messages from the direct channels
// I use a tree to pick a message among valid messages not addressed to me
wire [DIRECT_CHANNEL_ALL_EXPAND_COUNT-1:0] tree_gathering_elected_direct_message_valid;
wire [(DIRECT_MESSAGE_WIDTH * DIRECT_CHANNEL_ALL_EXPAND_COUNT)-1:0] tree_gathering_elected_direct_message_data;
`define expanded_elected_direct_message_data(i) tree_gathering_elected_direct_message_data[((i+1) * DIRECT_MESSAGE_WIDTH) - 1 : (i * DIRECT_MESSAGE_WIDTH)]
wire [(DIRECT_CHANNEL_WIDTH * DIRECT_CHANNEL_ALL_EXPAND_COUNT)-1:0] tree_gathering_elected_direct_message_index;
`define expanded_elected_direct_message_index(i) tree_gathering_elected_direct_message_index[((i+1) * DIRECT_CHANNEL_WIDTH) - 1 : (i * DIRECT_CHANNEL_WIDTH)]
generate
    for (i=0; i < DIRECT_CHANNEL_EXPAND_COUNT; i=i+1) begin: direct_channel_gathering_initialization
        if (i < DIRECT_CHANNEL_COUNT) begin
            assign tree_gathering_elected_direct_message_valid[i] = `direct_in_valid(i) && !direct_in_channels_address_matched[i];
            assign `expanded_elected_direct_message_index(i) = i;
            assign `expanded_elected_direct_message_data(i) = `direct_in_data(i);
        end else begin
            assign tree_gathering_elected_direct_message_valid[i] = 0;
        end
    end
    for (i=0; i < DIRECT_CHANNEL_DEPTH; i=i+1) begin: direct_channel_gathering_election
        genvar j;
        for (j=0; j < `DIRECT_CHANNEL_LAYER_WIDTH; j=j+1) begin: direct_channel_gathering_layer_election
            assign tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CURRENT_IDX] = tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CHILD_1_IDX] | tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CHILD_2_IDX];
            assign `expanded_elected_direct_message_index(`DIRECT_CHANNEL_CURRENT_IDX) = tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CHILD_1_IDX] ? (
                `expanded_elected_direct_message_index(`DIRECT_CHANNEL_CHILD_1_IDX)
            ) : (
                `expanded_elected_direct_message_index(`DIRECT_CHANNEL_CHILD_2_IDX)
            );
            assign `expanded_elected_direct_message_data(`DIRECT_CHANNEL_CURRENT_IDX) = tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CHILD_1_IDX] ? (
                `expanded_elected_direct_message_data(`DIRECT_CHANNEL_CHILD_1_IDX)
            ) : (
                `expanded_elected_direct_message_data(`DIRECT_CHANNEL_CHILD_2_IDX)
            );
        end
    end
endgenerate

`define gathered_elected_direct_message_valid (tree_gathering_elected_direct_message_valid[DIRECT_CHANNEL_ROOT_IDX])
`define gathered_elected_direct_message_index (`expanded_elected_direct_message_index(DIRECT_CHANNEL_ROOT_IDX))
`define gathered_elected_direct_message_data (`expanded_elected_direct_message_data(DIRECT_CHANNEL_ROOT_IDX))

// Part 5 : Pick gathered direct message or if not send the stored message from part A

wire pending_message_sent_successfully;
wire pending_direct_message_valid;
wire [DIRECT_MESSAGE_WIDTH-1:0] pending_direct_message;
wire intermediate_buffer_is_full;
wire pending_direct_message_valid_delayed;
wire [DIRECT_MESSAGE_WIDTH-1:0] pending_direct_message_delayed;
wire intermediate_buffer_is_taken;
wire intermediatre_initialize;
wire intermediate_message_sent_sucessfully;

assign pending_direct_message_valid = (`gathered_elected_direct_message_valid || my_stored_direct_message_valid);
// assign pending_direct_message_valid = (generate_my_direct_message || `gathered_elected_direct_message_valid || my_stored_direct_message_valid);
assign pending_direct_message = `gathered_elected_direct_message_valid ? (
    `gathered_elected_direct_message_data ) : (
        my_stored_direct_message
);

// When taking one or many messages from the FIFO I must also update that I took the message to the FIFO
generate
    for (i=0; i < DIRECT_CHANNEL_COUNT; i=i+1) begin: taking_direct_message
        assign `direct_in_is_taken(i) = is_stage_spread_cluster && 
            (((i == `gathered_elected_direct_message_index) && `gathered_elected_direct_message_valid  && intermediate_message_sent_sucessfully) || 
                direct_in_channels_local_handled[i]);  // either brokerd this message or handled locally
    end
endgenerate

// Part 6 : Write to the intermediate FIFO
// We use intermediate FIFO to create a pipeline stage inside the PE to avoid timing violations
assign intermediatre_initialize = stage == STAGE_MEASUREMENT_LOADING;
assign intermediate_message_sent_sucessfully = pending_direct_message_valid && !intermediate_buffer_is_full;

blocking_channel #(
    .WIDTH(DIRECT_MESSAGE_WIDTH) // width of data
) intermediate_stage (
    .in_data(pending_direct_message),
    .in_valid(pending_direct_message_valid),
    .in_is_full(intermediate_buffer_is_full),
    .out_data(pending_direct_message_delayed),
    .out_valid(pending_direct_message_valid_delayed),
    .out_is_taken(pending_message_sent_successfully),
    .clk(clk),
    .reset(reset),
    .initialize(intermediatre_initialize)
);

// Support logic to handle valid flags
always@(posedge clk) begin
    if (reset) begin
        my_stored_direct_message_valid <= 0;
    end else begin
        if (intermediatre_initialize) begin
            my_stored_direct_message_valid <= 0;
        end else if (generate_my_direct_message && is_stage_spread_cluster) begin
            my_stored_direct_message_valid <= 1;
        end else if (intermediate_message_sent_sucessfully && !`gathered_elected_direct_message_valid) begin
            my_stored_direct_message_valid <= 0;
        end
    end
end

// Part 7 : Pick the message from FIFO and select best output channel to send it
// Here we use a submodule to help us to pick the best channel
`define pending_direct_message_receiver (pending_direct_message_delayed[DIRECT_MESSAGE_WIDTH-1:2])

wire [ADDRESS_WIDTH-1:0] distance_solver_target;
wire [DIRECT_CHANNEL_WIDTH-1:0] distance_solver_result_idx;

tree_distance_3d_solver #(
    .PER_DIMENSION_WIDTH(PER_DIMENSION_WIDTH),
    .CHANNEL_COUNT(DIRECT_CHANNEL_COUNT),
    .I(I),
    .J(J),
    .K(K)
) u_tree_distance_3d_solver (
    .target(distance_solver_target),
    .result_idx(distance_solver_result_idx)
);

assign distance_solver_target = `pending_direct_message_receiver;
`define best_channel_for_pending_message_idx distance_solver_result_idx

// Part 8 : Send the direct message
assign direct_out_channels_data_single = pending_direct_message_delayed;
wire not_addressed_to_me;
assign not_addressed_to_me = `pending_direct_message_receiver != address;
generate
    for (i=0; i < DIRECT_CHANNEL_COUNT; i=i+1) begin: sending_direct_message
        assign `direct_out_valid(i) = is_stage_spread_cluster_delayed && pending_direct_message_valid_delayed && (i == `best_channel_for_pending_message_idx) && not_addressed_to_me;
    end
endgenerate

// Part 9 :check if it can be sent successfully.  We need this to update read of intermediate FIFO
wire [DIRECT_CHANNEL_ALL_EXPAND_COUNT-1:0] tree_gathering_pending_message_sent_successfully;
generate
    for (i=0; i < DIRECT_CHANNEL_EXPAND_COUNT; i=i+1) begin: pending_message_sent_successfully_gathering_initialization
        if (i < DIRECT_CHANNEL_COUNT) begin
            assign tree_gathering_pending_message_sent_successfully[i] = (i == `best_channel_for_pending_message_idx) ? (
                !`direct_out_is_full(i)
            ) : 0;
        end else begin
            assign tree_gathering_pending_message_sent_successfully[i] = 0;
        end
    end
    for (i=0; i < DIRECT_CHANNEL_DEPTH; i=i+1) begin: pending_message_sent_successfully_gathering_election
        genvar j;
        for (j=0; j < `DIRECT_CHANNEL_LAYER_WIDTH; j=j+1) begin: direct_channel_gathering_layer_election
            assign tree_gathering_pending_message_sent_successfully[`DIRECT_CHANNEL_CURRENT_IDX] =
                tree_gathering_pending_message_sent_successfully[`DIRECT_CHANNEL_CHILD_1_IDX] | tree_gathering_pending_message_sent_successfully[`DIRECT_CHANNEL_CHILD_2_IDX];
        end
    end
endgenerate
`define gathered_pending_message_sent_successfully (tree_gathering_pending_message_sent_successfully[DIRECT_CHANNEL_ROOT_IDX])
assign pending_message_sent_successfully = `gathered_pending_message_sent_successfully && pending_direct_message_valid_delayed;

//-------------------------------------------------------------------------------------------------------------------------------//

// -------------------------------------Stage Sync Odd Cluster ------------------------------------------------------------------//
// The roots of each cluster will now send each node in it;s cluster whether they are part of an odd cluster or not
// Here to be an odd cluster the cluster also has to be not touching the boundary

// Step 1 : for roots of each cluster : Calculate whether the root of each cluster is odd or not
// This is stored as odd cluster and will be accessible to the neighbor link
wire myself_is_odd_cardinality_but_not_touching_boundary;
assign myself_is_odd_cardinality_but_not_touching_boundary = (address == updated_root) && (!is_touching_boundary) && is_odd_cardinality;

// Step 2 : for roots which receive messages as odd clusters : Update each nodes as odd cluster
wire gathered_is_odd_cluster = (|neighbor_is_odd_cluster);
assign updated_is_odd_cluster = is_odd_cluster | gathered_is_odd_cluster;

//-------------------------------------------------------------------------------------------------------------------------------//


// -------------------------------------Stage grow boundry ------------------------------------------------------------------//
// If odd then grow
assign neighbor_increase = is_odd_cluster && (stage == STAGE_GROW_BOUNDARY) && (last_stage != STAGE_GROW_BOUNDARY);
//-------------------------------------------------------------------------------------------------------------------------------//


// -------------------------------------Support logic to calculate whether PE is busy or not -------------------------------//

// compute `should_broadcast_is_odd_cardinality`
wire should_broadcast_is_odd_cardinality;
assign should_broadcast_is_odd_cardinality = (stage == STAGE_SYNC_IS_ODD_CLUSTER) && 
    ((last_stage != STAGE_SYNC_IS_ODD_CLUSTER) ? (myself_is_odd_cardinality_but_not_touching_boundary) : (updated_is_odd_cluster != is_odd_cluster));

// Additional logic to indicate busy to outside : Check whether the neighbor data is processing. And hold that singal for one extra cycle
assign neighbor_changed = (is_stage_spread_cluster && (new_updated_root != updated_root)) || should_broadcast_is_odd_cardinality;
always @(posedge clk) begin
    if (reset) begin
        neighbor_changed_delayed <= 0;
    end else begin
        neighbor_changed_delayed <= neighbor_changed;
    end
end

// A signal to identify whether this PU done it;s operations
assign is_processing = neighbor_changed_delayed | neighbor_changed | (|direct_out_channels_valid) | (|direct_in_channels_valid) | pending_direct_message_valid_delayed | my_stored_direct_message_valid;

//-------------------------------------------------------------------------------------------------------------------------------//

// ------------------------------------- Main State diagram to log the stages of the PE -------------------------------//

always @(posedge clk) begin
    if (reset) begin
        address <= init_address; // constant per PU
        old_root <= init_address; // constant per PU
        updated_root <= init_address; // constant per PU
        last_stage <= STAGE_IDLE;
        is_error_syndrome <= 0;
        has_boundary_x <= init_has_boundary_x; // constant per PU
        has_boundary_z <= init_has_boundary_z; // constant per PU
        has_boundary_ud <= init_has_boundary_ud; // constant per PU
        boundary_cost_x <= init_boundary_cost_x; // constant per PU
        boundary_cost_z <= init_boundary_cost_z; // constant per PU
        boundary_cost_ud <= init_boundary_cost_ud; // constant per PU
        boundary_increased_x <= 0;
        boundary_increased_z <= 0;
        boundary_increased_ud <= 0;
        is_odd_cluster <= 0;
        is_touching_boundary <= 0;
        is_odd_cardinality <= 0;
    end else begin
        last_stage <= stage;  // record last stage
        if (stage == STAGE_IDLE) begin
            // PUs do nothing
        end else if (stage == STAGE_SPREAD_CLUSTER) begin
            is_touching_boundary <= updated_is_touching_boundary;
            is_odd_cardinality <= updated_is_odd_cardinality;
            updated_root <= new_updated_root;
            is_odd_cluster <= 0;
        end else if (stage == STAGE_GROW_BOUNDARY) begin
            // only gives a trigger to neighbor links
            // see `assign neighbor_increase = !reset && is_odd_cluster && (stage == STAGE_GROW_BOUNDARY) && (last_stage != STAGE_GROW_BOUNDARY);`
            if (is_odd_cluster && last_stage != STAGE_GROW_BOUNDARY) begin
                // only trigger once when set to STAGE_GROW_BOUNDARY
                if (has_boundary_x && (boundary_increased_x < boundary_cost_x)) begin
                    boundary_increased_x <= boundary_increased_x + 1;
                end
                if (has_boundary_z && (boundary_increased_z < boundary_cost_z)) begin
                    boundary_increased_z <= boundary_increased_z + 1;
                end
                if (has_boundary_ud && (boundary_increased_ud < boundary_cost_ud)) begin
                    boundary_increased_ud <= boundary_increased_ud + 1;
                end
            end
        end else if (stage == STAGE_SYNC_IS_ODD_CLUSTER) begin
            if (last_stage != STAGE_SYNC_IS_ODD_CLUSTER) begin
                // first set them all to even cluster, if it's not itself odd cardinality but not touching boundary
                is_odd_cluster <= myself_is_odd_cardinality_but_not_touching_boundary;
                old_root <= updated_root;  // update old_root
            end else begin
                is_odd_cluster <= updated_is_odd_cluster;
            end
        end else if (stage == STAGE_MEASUREMENT_LOADING) begin
            address <= init_address;
            old_root <= init_address;
            updated_root <= init_address;
            last_stage <= STAGE_IDLE;
            is_error_syndrome <= init_is_error_syndrome;
            has_boundary_x <= init_has_boundary_x; // constant per PU
            has_boundary_z <= init_has_boundary_z; // constant per PU
            has_boundary_ud <= init_has_boundary_ud; // constant per PU
            boundary_cost_x <= init_boundary_cost_x; // constant per PU
            boundary_cost_z <= init_boundary_cost_z; // constant per PU
            boundary_cost_ud <= init_boundary_cost_ud; // constant per PU
            boundary_increased_x <= 0;
            boundary_increased_z <= 0;
            boundary_increased_ud <= 0;
            is_odd_cluster <= init_is_error_syndrome;
            is_touching_boundary <= 0;
            is_odd_cardinality <= init_is_error_syndrome;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        stage <= STAGE_IDLE;
        stage_delayed <= STAGE_IDLE;
    end else begin
        stage <= stage_in;
        stage_delayed <= stage;
    end
end

//-------------------------------------------------------------------------------------------------------------------------------//


endmodule
