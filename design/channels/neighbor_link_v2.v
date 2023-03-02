module neighbor_link #(
    parameter ADDRESS_WIDTH = 6,
    parameter WEIGHT = 2,
    parameter BOUNDARY_CONDITION = 0, //0 : No boundary 1: A boundary 2: Non existant edge 3: Connected to a FIFO
    parameter ADDRESS_A = 0,
    parameter ADDRESS_B = 0
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

    is_error,

    input_FIFO_valid,
    input_FIFO_ready,
    input_FIFO_data,

    output_FIFO_valid,
    output_FIFO_ready,
    output_FIFO_data
);

`include "../../parameters/parameters.sv"

localparam LINK_BIT_WIDTH = $clog2(WEIGHT + 1);
localparam INTERCONNECTION_FIFO_WIDTH = ADDRESS_WIDTH + 9;

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

input input_FIFO_valid;
output input_FIFO_ready;
input [INTERCONNECTION_FIFO_WIDTH-1:0] input_FIFO_data;

input output_FIFO_ready;
output output_FIFO_valid;
output [INTERCONNECTION_FIFO_WIDTH-1:0] output_FIFO_data;


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

end else if (BOUNDARY_CONDITION == 3) begin
    //Filter FIFO data
    wire FIFO_b_increase;
    wire FIFO_b_is_error_in;
    reg b_parent_vector_saved_from_FIFO;

    reg valid_data_present;
    assign output_FIFO_valid = valid_data_present;

    reg a_increase_saved;
    reg a_is_error_saved;
    wire a_parent_vector_changed;
    reg a_parent_vector_previous;
    wire a_root_changed;
    reg [ADDRESS_WIDTH-1:0] a_root_previous;
    wire a_parent_odd_changed;
    reg a_parent_odd_previous;
    wire a_child_cluster_parity_changed;
    reg a_child_cluster_parity_previous;
    wire a_child_touching_boundary_changed;
    reg a_child_touching_boundary_previous;
    wire a_child_peeling_complete_changed;
    reg a_child_peeling_complete_previous;
    wire a_child_peeling_m_changed;
    reg a_child_peeling_m_previous;
    wire a_parent_peeling_parity_completed_changed;
    reg a_parent_peeling_parity_completed_previous;

    always@(posedge clk) begin
        if(reset) begin
            valid_data_present <= 0;
        end else if (global_stage == STAGE_MEASUREMENT_LOADING) begin
            valid_data_present <= 0;
        end else begin
            if (a_increase || a_is_error_in || a_parent_vector_changed || a_root_changed || a_parent_odd_changed || a_child_cluster_parity_changed
                || a_child_touching_boundary_changed || a_child_peeling_complete_changed || a_child_peeling_m_changed || a_parent_peeling_parity_completed_changed) begin
                valid_data_present <= 1;
            end else if(valid_data_present && output_FIFO_ready) begin
                valid_data_present <= 0;
            end
        end
    end

    always@(posedge clk) begin
        if(reset) begin
            a_increase_saved <= 0;
        end else if (global_stage == STAGE_MEASUREMENT_LOADING) begin
            a_increase_saved <= 0;
        end else begin
            if (a_increase) begin
                a_increase_saved <= a_increase;
            end
        end
    end

    always@(posedge clk) begin
        if(reset) begin
            a_is_error_saved <= 0;
        end else if (global_stage == STAGE_MEASUREMENT_LOADING) begin
            a_is_error_saved <= 0;
        end else begin
            if (a_is_error_in) begin
                a_is_error_saved <= a_is_error_in;
            end
        end
    end


    assign output_FIFO_data[0] = a_increase_saved;
    assign output_FIFO_data[1] = a_is_error_saved;
    assign output_FIFO_data[2] = a_parent_vector_in;
    assign output_FIFO_data[ADDRESS_WIDTH-1+3:3] = a_root_in;
    assign output_FIFO_data[ADDRESS_WIDTH-1+4] = a_parent_odd_in;
    assign output_FIFO_data[ADDRESS_WIDTH-1+5] = a_child_cluster_parity_in;
    assign output_FIFO_data[ADDRESS_WIDTH-1+6] = a_child_touching_boundary_in;
    assign output_FIFO_data[ADDRESS_WIDTH-1+7] = a_child_peeling_complete_in;
    assign output_FIFO_data[ADDRESS_WIDTH-1+8] = a_child_peeling_m_in;
    assign output_FIFO_data[ADDRESS_WIDTH-1+9] = a_parent_peeling_parity_completed_in;

    assign FIFO_b_increase = input_FIFO_data[0] && input_FIFO_valid && input_FIFO_ready;
    assign FIFO_b_is_error_in = input_FIFO_data[1] && input_FIFO_valid && input_FIFO_ready;
    assign input_FIFO_ready = 1'b1;

    always@(posedge clk) begin
        if(reset) begin
            a_parent_vector_previous <= 0;
            a_root_previous <= ADDRESS_A;
            a_parent_odd_previous <= 0;
            a_child_cluster_parity_previous <= 0;
            a_child_touching_boundary_previous <= 0;
            a_child_peeling_complete_previous <= 0;
            a_child_peeling_m_previous <= 0;
            a_parent_peeling_parity_completed_previous <= 0;
        end else if (global_stage == STAGE_MEASUREMENT_LOADING) begin
            a_parent_vector_previous <= 0;
            a_root_previous <= ADDRESS_A;
            a_parent_odd_previous <= 0;
            a_child_cluster_parity_previous <= 0;
            a_child_touching_boundary_previous <= 0;
            a_child_peeling_complete_previous <= 0;
            a_child_peeling_m_previous <= 0;
            a_parent_peeling_parity_completed_previous <= 0;
        end else begin
            a_parent_vector_previous <= a_parent_vector_in;
            a_root_previous <= a_root_in;
            a_parent_odd_previous <= a_parent_odd_in;
            a_child_cluster_parity_previous <= a_child_cluster_parity_in;
            a_child_touching_boundary_previous <= a_child_touching_boundary_in;
            a_child_peeling_complete_previous <= a_child_peeling_complete_in;
            a_child_peeling_m_previous <= a_child_peeling_m_in;
            a_parent_peeling_parity_completed_previous <= a_parent_peeling_parity_completed_in;
        end
    end

    assign a_parent_vector_changed = (a_parent_vector_in != a_parent_vector_previous) && (global_stage != STAGE_MEASUREMENT_LOADING);
    assign a_root_changed = (a_root_in != a_root_previous) && (global_stage != STAGE_MEASUREMENT_LOADING);
    assign a_parent_odd_changed = (a_parent_odd_in != a_parent_odd_previous) && (global_stage != STAGE_MEASUREMENT_LOADING);
    assign a_child_cluster_parity_changed = (a_child_cluster_parity_in != a_child_cluster_parity_previous) && (global_stage != STAGE_MEASUREMENT_LOADING);
    assign a_child_touching_boundary_changed = (a_child_touching_boundary_in != a_child_touching_boundary_previous) && (global_stage != STAGE_MEASUREMENT_LOADING);
    assign a_child_peeling_complete_changed = (a_child_peeling_complete_in != a_child_peeling_complete_previous) && (global_stage != STAGE_MEASUREMENT_LOADING);
    assign a_child_peeling_m_changed = (a_child_peeling_m_in != a_child_peeling_m_previous) && (global_stage != STAGE_MEASUREMENT_LOADING);
    assign a_parent_peeling_parity_completed_changed = (a_parent_peeling_parity_completed_in != a_parent_peeling_parity_completed_previous) && (global_stage != STAGE_MEASUREMENT_LOADING);

    always@(posedge clk) begin
        if(reset) begin
            b_parent_vector_saved_from_FIFO <= 0;
        end else begin
            if(input_FIFO_valid && input_FIFO_ready) begin
                b_parent_vector_saved_from_FIFO <= input_FIFO_data[2];
            end else if (global_stage == STAGE_MEASUREMENT_LOADING) begin
                b_parent_vector_saved_from_FIFO <= 0;
            end
        end
    end

    // Fill the data from FIFOs
    always@(posedge clk) begin
        if(reset) begin
            growth <= 0;
        end else begin
            if(global_stage == STAGE_MEASUREMENT_LOADING) begin
                growth <= 0;
            end else begin
                growth <= `MIN(growth + a_increase + FIFO_b_increase, WEIGHT);
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
                if(FIFO_b_is_error_in) begin
                    is_error <= 1;
                end else begin
                    is_error <= a_is_error_in;
                end
            end
        end
    end

    assign fully_grown = growth >= WEIGHT;
    assign is_boundary = 0;

    assign a_parent_vector_out = b_parent_vector_saved_from_FIFO;

    reg [ADDRESS_WIDTH-1:0]  b_root_saved_from_FIFO;
    reg b_parent_odd_saved_from_FIFO;
    reg b_child_cluster_parity_saved_from_FIFO;
    reg b_child_touching_boundary_saved_from_FIFO;
    reg b_child_peeling_complete_saved_from_FIFO;
    reg b_child_peeling_m_saved_from_FIFO;
    reg b_parent_peeling_parity_completed_saved_from_FIFO;


    always@(posedge clk) begin
        if(reset) begin
            b_root_saved_from_FIFO <= ADDRESS_B;
            b_parent_odd_saved_from_FIFO <= 0;
            b_child_cluster_parity_saved_from_FIFO <= 0;
            b_child_touching_boundary_saved_from_FIFO <= 0;
            b_child_peeling_complete_saved_from_FIFO <= 0;
            b_child_peeling_m_saved_from_FIFO <= 0;
            b_parent_peeling_parity_completed_saved_from_FIFO <= 0;
        end else begin
            if(input_FIFO_valid && input_FIFO_ready) begin
                b_root_saved_from_FIFO <= input_FIFO_data[ADDRESS_WIDTH-1+3:3];
                b_parent_odd_saved_from_FIFO <= input_FIFO_data[ADDRESS_WIDTH-1+4];
                b_child_cluster_parity_saved_from_FIFO <= input_FIFO_data[ADDRESS_WIDTH-1+5];
                b_child_touching_boundary_saved_from_FIFO <= input_FIFO_data[ADDRESS_WIDTH-1+6];
                b_child_peeling_complete_saved_from_FIFO <= input_FIFO_data[ADDRESS_WIDTH-1+7];
                b_child_peeling_m_saved_from_FIFO <= input_FIFO_data[ADDRESS_WIDTH-1+8];
                b_parent_peeling_parity_completed_saved_from_FIFO <= input_FIFO_data[ADDRESS_WIDTH-1+9];
            end else if (global_stage == STAGE_MEASUREMENT_LOADING) begin
                b_root_saved_from_FIFO <= ADDRESS_B;
                b_parent_odd_saved_from_FIFO <= 0;
                b_child_cluster_parity_saved_from_FIFO <= 0;
                b_child_touching_boundary_saved_from_FIFO <= 0;
                b_child_peeling_complete_saved_from_FIFO <= 0;
                b_child_peeling_m_saved_from_FIFO <= 0;
                b_parent_peeling_parity_completed_saved_from_FIFO <= 0;
            end
        end
    end

    assign a_root_out = b_root_saved_from_FIFO;

    assign a_parent_odd_out = b_parent_odd_saved_from_FIFO;

    assign a_child_cluster_parity_out = b_child_cluster_parity_saved_from_FIFO;

    assign a_child_touching_boundary_out = b_child_touching_boundary_saved_from_FIFO;

    assign a_child_peeling_complete_out = b_child_peeling_complete_saved_from_FIFO;
    assign a_child_peeling_m_out = b_child_peeling_m_saved_from_FIFO;
    assign a_parent_peeling_parity_completed_out = b_parent_peeling_parity_completed_saved_from_FIFO;
end

endgenerate

generate

if (BOUNDARY_CONDITION == 0 || BOUNDARY_CONDITION == 1 || BOUNDARY_CONDITION == 2 )  begin // No boundary default case 

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
    
end

endgenerate




endmodule


