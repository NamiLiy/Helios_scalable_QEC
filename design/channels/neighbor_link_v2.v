module neighbor_link #(
    parameter ADDRESS_WIDTH = 6,
    parameter WEIGHT = 2,
    parameter BOUNDARY_CONDITION = 0 //0 : No boundary 1: A boundary 2: Non existant edge 
) (
    clk,
    reset,
    global_stage,

    fully_grown,

    a_root_in,
    b_root_in,
    a_root_out,
    b_root_out,

    a_parent_vector_in,
    b_parent_vector_in,
    a_parent_vector_out,
    b_parent_vector_out,

    a_increase,
    b_increase,
    is_boundary,

    a_parent_odd_in,
    b_parent_odd_in,
    a_parent_odd_out,
    b_parent_odd_out,


    a_child_cluster_parity_in,
    b_child_cluster_parity_in,
    a_child_cluster_parity_out,
    b_child_cluster_parity_out,

    a_child_touching_boundary_in,
    b_child_touching_boundary_in,
    a_child_touching_boundary_out,
    b_child_touching_boundary_out,

    a_is_error_in,
    a_child_peeling_complete_in,
    a_child_peeling_m_in,
    a_parent_peeling_parity_completed_in,

    b_is_error_in,
    b_child_peeling_complete_in,
    b_child_peeling_m_in,
    b_parent_peeling_parity_completed_in,

    a_child_peeling_complete_out,
    a_child_peeling_m_out,
    a_parent_peeling_parity_completed_out,

    b_child_peeling_complete_out,
    b_child_peeling_m_out,
    b_parent_peeling_parity_completed_out,

    is_error
);

`include "../../parameters/parameters.sv"

input clk;
input reset;
input [STAGE_WIDTH-1:0] global_stage;

output fully_grown;
input [ADDRESS_WIDTH-1:0] a_root_in;
input [ADDRESS_WIDTH-1:0] b_root_in;
output [ADDRESS_WIDTH-1:0] a_root_out;
output [ADDRESS_WIDTH-1:0] b_root_out;

input a_parent_vector_in;
input b_parent_vector_in;
output a_parent_vector_out;
output b_parent_vector_out;

input a_increase;
input b_increase;
output is_boundary;

input a_parent_odd_in;
input b_parent_odd_in;
output a_parent_odd_out;
output b_parent_odd_out;

input a_child_cluster_parity_in;
input b_child_cluster_parity_in;
output a_child_cluster_parity_out;
output b_child_cluster_parity_out;

input a_child_touching_boundary_in;
input b_child_touching_boundary_in;
output a_child_touching_boundary_out;
output b_child_touching_boundary_out;

input a_is_error_in;
input a_child_peeling_complete_in;
input a_child_peeling_m_in;
input a_parent_peeling_parity_completed_in;

input b_is_error_in;
input b_child_peeling_complete_in;
input b_child_peeling_m_in;
input b_parent_peeling_parity_completed_in;

output a_child_peeling_complete_out;
output a_child_peeling_m_out;
output a_parent_peeling_parity_completed_out;

output b_child_peeling_complete_out;
output b_child_peeling_m_out;
output b_parent_peeling_parity_completed_out;

output reg is_error;

localparam LINK_BIT_WIDTH = $clog2(WEIGHT + 1);


reg [LINK_BIT_WIDTH-1 : 0] growth;



`define MIN(a, b) (((a) < (b)) ? (a) : (b))

generate

if (BOUNDARY_CONDITION == 0)  begin // No boundary default case 
    always@(posedge clk) begin
        if(reset) begin
            growth <= 0;
        end else begin
            if(global_stage == STAGE_MEASUREMENT_LOADING) begin
                growth <= 0;
            end else begin
                growth <= `MIN(growth + a_increase + b_increase, WEIGHT);
            end
        end
    end

    always@(posedge clk) begin
        if(reset) begin
            is_error <= 0;
        end else begin
            if(global_stage == STAGE_MEASUREMENT_LOADING) begin
                is_error <= 0;
            end else begin
                is_error <= a_is_error_in | b_is_error_in;
            end
        end
    end

    assign fully_grown = growth >= WEIGHT;
    assign is_boundary = 0;

    assign a_parent_vector_out = b_parent_vector_in;
    assign b_parent_vector_out = a_parent_vector_in;
    

end else if(BOUNDARY_CONDITION == 1) begin // edge touching a boundary
    always@(posedge clk) begin
        if(reset) begin
            growth <= 0;
        end else begin
            if(global_stage == STAGE_MEASUREMENT_LOADING) begin
                growth <= 0;
            end else begin
                growth <= growth + a_increase;
            end
        end
    end

    always@(posedge clk) begin
        if(reset) begin
            is_error <= 0;
        end else begin
            if(global_stage == STAGE_MEASUREMENT_LOADING) begin
                is_error <= 0;
            end else begin
                is_error <= a_is_error_in;
            end
        end
    end

    assign fully_grown = growth >= WEIGHT;
    assign is_boundary = fully_grown;

    assign a_parent_vector_out = 0;
    assign b_parent_vector_out = 0;

end else if (BOUNDARY_CONDITION == 2) begin // A non existant edge
    assign fully_grown = 0;
    assign is_boundary = 0;

    assign a_parent_vector_out = 0;
    assign b_parent_vector_out = 0;
end

endgenerate

assign a_root_out = b_root_in;
assign b_root_out = a_root_in;

assign a_parent_odd_out = b_parent_odd_in;
assign b_parent_odd_out = a_parent_odd_in;

assign a_child_cluster_parity_out = b_child_cluster_parity_in;
assign b_child_cluster_parity_out = a_child_cluster_parity_in;

assign a_child_touching_boundary_out = b_child_touching_boundary_in;
assign b_child_touching_boundary_out = a_child_touching_boundary_in;

assign a_child_peeling_complete_out = b_child_peeling_complete_in;
assign a_child_peeling_m_out = b_child_peeling_m_in;
assign a_parent_peeling_parity_completed_out = b_parent_peeling_parity_completed_in;

assign b_child_peeling_complete_out = a_child_peeling_complete_in;
assign b_child_peeling_m_out = a_child_peeling_m_in;
assign b_parent_peeling_parity_completed_out = a_parent_peeling_parity_completed_in;




endmodule


