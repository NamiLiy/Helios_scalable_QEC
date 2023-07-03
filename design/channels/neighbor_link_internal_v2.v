module neighbor_link_internal #(
    parameter ADDRESS_WIDTH = 6,
    parameter MAX_WEIGHT = 2
    // parameter WEIGHT = 2,
    // parameter BOUNDARY_CONDITION = 0, //0 : No boundary 1: A boundary 2: Non existant edge 3: Connected to a FIFO
    // parameter ADDRESS_A = 0,
    // parameter ADDRESS_B = 0,
    // parameter HEADER_ID = 0,
    // parameter HEADER_WIDTH = 2
) (
    clk,
    reset,
    global_stage,

    fully_grown,

    a_increase,
    b_increase,
    is_boundary,

    a_input_data,
    b_input_data,
    a_output_data,
    b_output_data,

    a_is_error_in,
    b_is_error_in,
    is_error,

    weight_in,
    boundary_condition_in,
    is_error_systolic_in,

    weight_out,
    boundary_condition_out,
    
    erased,
    erased_out
);

`include "../../parameters/parameters.sv"

localparam LINK_BIT_WIDTH = $clog2(MAX_WEIGHT + 1);
localparam EXPOSED_DATA_SIZE = ADDRESS_WIDTH + 1 + 1 + 1 + 1 + 3;

input clk;
input reset;
input [STAGE_WIDTH-1:0] global_stage;

output fully_grown;
input a_increase;
input b_increase;

output is_boundary;
input erased;
output reg erased_out;
input a_is_error_in;
input b_is_error_in;
output reg is_error;

input [EXPOSED_DATA_SIZE-1:0] a_input_data;
input [EXPOSED_DATA_SIZE-1:0] b_input_data;
output [EXPOSED_DATA_SIZE-1:0] a_output_data;
output [EXPOSED_DATA_SIZE-1:0] b_output_data;

input [LINK_BIT_WIDTH-1:0] weight_in;
input [1:0] boundary_condition_in;
input is_error_systolic_in;

output reg [LINK_BIT_WIDTH-1:0] weight_out;
output reg [1:0] boundary_condition_out;

reg [LINK_BIT_WIDTH-1 : 0] growth;



`define MIN(a, b) (((a) < (b)) ? (a) : (b))

localparam GROWTH_CALC_WIDTH = $clog2(MAX_WEIGHT + 3);
reg [GROWTH_CALC_WIDTH-1:0] growth_new;

always@(*) begin
    if (boundary_condition_out == 0)  begin // No boundary default case 
        growth_new = growth + a_increase + b_increase;
    end else if (boundary_condition_out == 1) begin // edge touching a boundary
        growth_new = growth + a_increase;
    end else begin // Non existant edge
        growth_new = 0;
    end
    if (growth_new > weight_out) begin
        growth_new = weight_out;
    end
end


always@(posedge clk) begin
    if(reset) begin
        growth <= 0;
    end else begin
        if(global_stage == STAGE_MEASUREMENT_LOADING || global_stage == STAGE_ERASURE_LOADING) begin
            growth <= 0;
        end else begin
            growth <= (erased == 1) ? weight_out : growth_new; //new;
        end 
    end
end

always@(posedge clk) begin
    if(reset) begin
        is_error <= 0;
    end else begin
        if (boundary_condition_out == 0)  begin // No boundary default case 
            if(global_stage == STAGE_MEASUREMENT_LOADING || STAGE_ERASURE_LOADING) begin
                is_error <= 0;
            end else if(global_stage == STAGE_RESULT_VALID) begin
                is_error <= is_error_systolic_in;
            end else begin
                is_error <= a_is_error_in | b_is_error_in;
            end
        end else if (boundary_condition_out == 1) begin // edge touching a boundary
            if(global_stage == STAGE_MEASUREMENT_LOADING || STAGE_ERASURE_LOADING) begin
                is_error <= 0;
            end else if(global_stage == STAGE_RESULT_VALID) begin
                is_error <= is_error_systolic_in;
            end else begin
                is_error <= a_is_error_in;
            end
        end else begin // Non existant edge
            is_error <= 0;
        end
    end
end

assign fully_grown = growth >= weight_out;
assign is_boundary = (boundary_condition_out==1'b1) && fully_grown;

assign a_output_data = (boundary_condition_out ==0)? b_input_data : 0;
assign b_output_data = (boundary_condition_out ==0)? a_input_data : 0;

always@(posedge clk) begin
    if(reset) begin
        weight_out <= 0;
        boundary_condition_out <= 0;
        erased_out <= 0;
    end else begin
        if(global_stage == STAGE_PARAMETERS_LOADING) begin
            weight_out <= weight_in;
            boundary_condition_out <= boundary_condition_in;
        end else if(global_stage == STAGE_ERASURE_LOADING) begin
            erased_out <= erased;
        end
    end
end

endmodule


