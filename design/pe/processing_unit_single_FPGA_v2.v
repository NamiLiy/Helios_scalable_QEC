`timescale 1ns / 1ps

// This PEs are written for Z type ancillas

module processing_unit #(
    parameter PER_DIM_BIT_WIDTH = 2,
    parameter BOUNDARY_BIT_WIDTH = 2,
    parameter NEIGHBOR_COUNT = 6,
    parameter ADDRESS = 0, // M,X,Z, address
    parameter CODE_DISTANCE_X = 5,
    parameter CODE_DISTANCE_Z = 4
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
    neighbor_is_error,

    parent_odd,
    parent_vector,

    child_cluster_parity,
    child_touching_boundary,

    child_peeling_complete,
    peeling_complete,
    child_peeling_m, //measurement for peeling stage from children
    peeling_m,
    parent_peeling_parity_completed,
    peeling_parity_completed,

    cluster_parity,
    cluster_touching_boundary,

    odd,
    odd_to_children,
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

output [NEIGHBOR_COUNT-1:0] neighbor_is_error;

input [NEIGHBOR_COUNT-1:0] parent_odd;
input [NEIGHBOR_COUNT - 1:0] child_cluster_parity;
input [NEIGHBOR_COUNT - 1:0] child_touching_boundary;

input [NEIGHBOR_COUNT - 1:0] child_peeling_complete;
output reg peeling_complete;
input [NEIGHBOR_COUNT - 1:0] child_peeling_m;
output reg peeling_m;

output reg [NEIGHBOR_COUNT-1:0] parent_vector;
output reg cluster_parity;
output reg cluster_touching_boundary;

input [NEIGHBOR_COUNT-1:0] parent_peeling_parity_completed;
output reg peeling_parity_completed;

output reg odd;
output reg [NEIGHBOR_COUNT-1:0] odd_to_children;
output reg [ADDRESS_WIDTH-1:0] root;
output reg busy;

reg [STAGE_WIDTH - 1 : 0] stage;
reg [STAGE_WIDTH - 1 : 0] last_stage;

// stage is always equal to global_stage
always@(posedge clk) begin
    if(reset) begin
        stage <= STAGE_IDLE;
        last_stage <= STAGE_IDLE;
    end else begin
        stage <= global_stage;
        last_stage <= stage;
    end
end

// Load the measurement
reg m;
always@(posedge clk) begin
    if(reset) begin
        m <= 0;
    end else if(stage == STAGE_MEASUREMENT_LOADING) begin
        m <= measurement;
    end
end

// Increase growth during the growth stage
assign neighbor_increase = odd && (stage == STAGE_GROW) && (last_stage != STAGE_GROW);

// root is the minimum of valid roots
// when root changes : change parent vector
wire [NEIGHBOR_COUNT-1 : 0] valid_from_root_comparator;
wire [ADDRESS_WIDTH - 1 : 0] result_from_root_comparator;

min_val_less_8x_with_index #(
    .DATA_WIDTH(ADDRESS_WIDTH),
    .CHANNEL_COUNT(NEIGHBOR_COUNT)
) u_tree_compare_solver (
    .values(neighbor_root),
    .valids(neighbor_fully_grown & ~neighbor_is_boundary),
    .result(result_from_root_comparator),
    .output_valids(valid_from_root_comparator)
);

always@(posedge clk) begin
    if(stage == STAGE_MEASUREMENT_LOADING) begin
        root <= ADDRESS;
        parent_vector <= 0;
    end else begin
        if (stage == STAGE_MERGE) begin
            if( (|valid_from_root_comparator) && result_from_root_comparator < root) begin
                root <= result_from_root_comparator;
                parent_vector <= valid_from_root_comparator;
            end
        end
    end
end

// Calculate the sub-tree parity and sub_tree touching boundary

wire next_cluster_parity = (^(neighbor_parent_vector & child_cluster_parity)) ^ m;
wire next_cluster_touching_boundary = (|(neighbor_parent_vector & child_touching_boundary)) | (|neighbor_is_boundary);

always@(posedge clk) begin
    if(stage == STAGE_MEASUREMENT_LOADING) begin
        cluster_parity <= measurement;
        cluster_touching_boundary <= 0;
    end else begin
        if (stage == STAGE_MERGE) begin
            cluster_parity <= next_cluster_parity;
            cluster_touching_boundary <= next_cluster_touching_boundary;
        end
    end
end

// Calculate cluster odd if you are the root.
// If not pass parents odd data
// This function also passes odd infomration to children for peeling purposes
always@(posedge clk) begin
    if(stage == STAGE_MEASUREMENT_LOADING) begin
        odd <= measurement;
        odd_to_children <= measurement;
    end else begin
        if (stage == STAGE_MERGE) begin
            if(|parent_vector) begin
                odd <= |(parent_vector & parent_odd);
                odd_to_children <= |(parent_vector & parent_odd);
            end else begin
                odd <= next_cluster_parity & !next_cluster_touching_boundary;
                odd_to_children <= next_cluster_parity & !next_cluster_touching_boundary;
            end
        end else if(stage == STAGE_PEELING) begin
            if(~(|parent_vector)) begin
                if(next_cluster_parity) begin // The cluster has even number of vertices
                    odd <= 0;
                    odd_to_children <= 0;
                end else begin // The cluster has odd number of vertices
                    if(|neighbor_is_boundary) begin // I am the boundary
                        odd <= 1;
                    end else begin // I am not the boundary
                        casex (neighbor_parent_vector & child_touching_boundary)
                            6'b1xxxxx: odd_to_children <= 6'b100000;
                            6'b01xxxx: odd_to_children <= 6'b010000;
                            6'b001xxx: odd_to_children <= 6'b001000;
                            6'b0001xx: odd_to_children <= 6'b000100;
                            6'b00001x: odd_to_children <= 6'b000010;
                            6'b000001: odd_to_children <= 6'b000001;
                            default: odd_to_children <= 0;
                        endcase
                    end
                end
            end else begin
                if(|(parent_vector & parent_odd)) begin //My parent is odd
                    if(|neighbor_is_boundary) begin // I am the boundary
                        odd <= 1;
                        odd_to_children <= 0;
                    end else begin // I am not the boundary
                        casex (neighbor_parent_vector & child_touching_boundary)
                            6'b1xxxxx: odd_to_children <= 6'b100000;
                            6'b01xxxx: odd_to_children <= 6'b010000;
                            6'b001xxx: odd_to_children <= 6'b001000;
                            6'b0001xx: odd_to_children <= 6'b000100;
                            6'b00001x: odd_to_children <= 6'b000010;
                            6'b000001: odd_to_children <= 6'b000001;
                            default: odd_to_children <= 0;
                        endcase
                    end
                end else begin  //My parent is not odd
                    odd <= 0;
                    odd_to_children <= 0;
                end
            end
        end
    end
end

// Peeling logic.

// Calculate peeling_parity complete
always@(posedge clk) begin
    if(reset) begin
        peeling_parity_completed <= 0;
    end else begin
        if (stage == STAGE_MEASUREMENT_LOADING) begin
            peeling_parity_completed <= 0;
        end else if(stage == STAGE_PEELING) begin
            if(~(|parent_vector)) begin
                peeling_parity_completed <= 1;
            end else begin
                peeling_parity_completed <= |(parent_vector & parent_peeling_parity_completed);
            end
        end
    end
end

// Calculate peeling complete
wire some_child_is_not_peeling_complete = (|(neighbor_parent_vector & (~child_peeling_complete))) || ~peeling_parity_completed;

always@(posedge clk) begin
    if(reset) begin
        peeling_complete <= 0;
    end else begin
        if (stage == STAGE_MEASUREMENT_LOADING) begin
            peeling_complete <= 0;
        end else begin
            if(stage == STAGE_PEELING) begin
                peeling_complete <= !some_child_is_not_peeling_complete;
            end
        end
    end
end

// If peeling complete, absorb children's m while marking the errors
always@(posedge clk) begin
    if(reset) begin
        peeling_m <= 0;
    end else begin
        if (stage == STAGE_PEELING && last_stage != STAGE_PEELING) begin
            peeling_m <= m;
        end else begin
            if(stage == STAGE_PEELING && !some_child_is_not_peeling_complete) begin
                peeling_m <= m ^ (neighbor_parent_vector & child_peeling_m) ^ odd;
            end
        end
    end
end

wire [NEIGHBOR_COUNT-1:0] neighbor_is_error_internal;
wire [NEIGHBOR_COUNT-1:0] neighbor_is_error_border;
always@(*) begin
    if(stage == STAGE_PEELING && !some_child_is_not_peeling_complete) begin
        neighbor_is_error_internal = neighbor_parent_vector & child_peeling_m;
    end else begin
        neighbor_is_error_internal = 6'b0;
    end
end

always@(*) begin
    if(stage == STAGE_PEELING && !some_child_is_not_peeling_complete && odd) begin
        casex (neighbor_is_boundary)
            6'b1xxxxx: neighbor_is_error_border = 6'b100000;
            6'b01xxxx: neighbor_is_error_border = 6'b010000;
            6'b001xxx: neighbor_is_error_border = 6'b001000;
            6'b0001xx: neighbor_is_error_border = 6'b000100;
            6'b00001x: neighbor_is_error_border = 6'b000010;
            6'b000001: neighbor_is_error_border = 6'b000001;
            default: neighbor_is_error_border = 0;
        endcase
    end else begin
        neighbor_is_error_border = 6'b0;
    end
end

assign neighbor_is_error = neighbor_is_error_internal | neighbor_is_error_border;

// Calculate busy
always@(posedge clk) begin
    if(reset) begin
        busy <= 0;
    end else begin
        if (stage == STAGE_MERGE) begin
            if( ((|valid_from_root_comparator) && result_from_root_comparator < root) ||
                 next_cluster_parity != cluster_parity ||
                 next_cluster_touching_boundary != cluster_touching_boundary ||
                 (|(parent_vector) & (|(parent_vector & parent_odd) != odd)) ||
                 (~|(parent_vector) && ((next_cluster_parity & !next_cluster_touching_boundary) != odd))
            )  begin
                busy <= 1;
            end else begin
                busy <= 0;
            end
        end else if (stage == STAGE_PEELING) begin
            busy <= !peeling_complete;
        end
    end
end
            

endmodule