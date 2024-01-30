module neighbor_link_external #(
    parameter ADDRESS_WIDTH = 6,
    parameter MAX_WEIGHT = 2,
    parameter NUM_CONTEXTS = 2
    // parameter WEIGHT = 2,
    // parameter BOUNDARY_CONDITION = 0, //0 : No boundary 1: A boundary 2: Non existant edge 3: Connected to a FIFO
) (
    clk,
    reset,
    global_stage,

    fully_grown,

    a_increase,
    is_boundary,

    a_input_data,
    a_output_data,

    a_is_error_in,
    is_error,

    weight_in,
    boundary_condition_in,
    is_error_systolic_in,

    weight_out,
    boundary_condition_out,
    do_not_store,

    b_init_address,

    fifo_output_data,
    fifo_output_valid,
    fifo_output_ready,

    fifo_input_data,
    fifo_input_valid,
    fifo_input_ready
);

`include "../../parameters/parameters.sv"

localparam LINK_BIT_WIDTH = $clog2(MAX_WEIGHT + 1);
localparam EXPOSED_DATA_SIZE = ADDRESS_WIDTH + 1 + 1 + 1;
localparam FIFO_DATA_SIZE = EXPOSED_DATA_SIZE + 1; // +1 for the growth

input clk;
input reset;
input [STAGE_WIDTH-1:0] global_stage;

output fully_grown;
input a_increase;

output is_boundary;

input a_is_error_in;
output is_error;

input [EXPOSED_DATA_SIZE-1:0] a_input_data;
output [EXPOSED_DATA_SIZE-1:0] a_output_data;

input [LINK_BIT_WIDTH-1:0] weight_in;
input [1:0] boundary_condition_in;
input is_error_systolic_in;
input do_not_store;

output [LINK_BIT_WIDTH-1:0] weight_out;
output [1:0] boundary_condition_out;

output [FIFO_DATA_SIZE-1:0] fifo_output_data;
output fifo_output_valid;
input fifo_output_ready;

input [FIFO_DATA_SIZE-1:0] fifo_input_data;
input fifo_input_valid;
output fifo_input_ready;

input [ADDRESS_WIDTH-1:0] b_init_address;

reg [STAGE_WIDTH-1:0] stage;
reg [STAGE_WIDTH-1:0] last_stage;

wire b_increase;
reg [EXPOSED_DATA_SIZE-1:0] b_input_data;
wire [EXPOSED_DATA_SIZE-1:0] b_input_data_temp;
wire [EXPOSED_DATA_SIZE-1:0] b_initial_data;

`define MIN(a, b) (((a) < (b)) ? (a) : (b))

localparam GROWTH_CALC_WIDTH = $clog2(MAX_WEIGHT + 3);

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

reg a_increase_mem;
always@(posedge clk) begin
    if(reset) begin
        a_increase_mem <= 0;
    end else begin
        if(stage == STAGE_MEASUREMENT_LOADING) begin
            a_increase_mem <= 0;
        end else begin
            if(fifo_output_ready && fifo_output_valid) begin
                a_increase_mem <= 0;
            end else begin
                if(boundary_condition_in == 3 && stage == STAGE_GROW) begin
                    a_increase_mem <= a_increase;
                end
            end
        end
    end
end

reg [EXPOSED_DATA_SIZE-1:0] a_input_data_mem;
reg a_input_data_mem_modified;

always@(posedge clk) begin
    if(reset) begin
        a_input_data_mem_modified <= 0;
        a_input_data_mem <= a_input_data;
    end else begin
        if(stage == STAGE_MEASUREMENT_LOADING) begin
            a_input_data_mem_modified <= 0;
            a_input_data_mem <= a_input_data;
        end else begin
            if(boundary_condition_in == 3 && fully_grown && a_input_data != a_input_data_mem) begin
                a_input_data_mem <= a_input_data;
                a_input_data_mem_modified <= 1;
            end else if(fifo_output_ready && fifo_output_valid) begin
                a_input_data_mem_modified <= 0;
            end
        end
    end
end

assign fifo_output_data[EXPOSED_DATA_SIZE-1 : 0] = a_input_data_mem;
assign fifo_output_data[EXPOSED_DATA_SIZE + 1 -1] = a_increase_mem;

assign fifo_output_valid = (boundary_condition_in == 3 && (a_input_data_mem_modified || a_increase_mem));

assign fifo_input_ready = 1'b1;
assign {b_increase, b_input_data_temp} = fifo_input_valid ? fifo_input_data : 32'b0;

always@(posedge clk) begin
    if(reset) begin
        b_input_data <= b_initial_data;
    end else begin
        if(stage == STAGE_MEASUREMENT_LOADING) begin
            b_input_data <= b_initial_data;
        end else begin
            if(fifo_input_valid) begin
                b_input_data <= b_input_data_temp;
            end
        end
    end
end

assign b_initial_data [ADDRESS_WIDTH-1 : 0] = b_init_address;
assign b_initial_data [ADDRESS_WIDTH + 1 -1]  = 1'b0;
assign b_initial_data [ADDRESS_WIDTH + 2 -1]  = 1'b0;
assign b_initial_data [ADDRESS_WIDTH + 3 -1]  = 1'b0;

wire [1:0] boundary_condition_to_internal;
assign boundary_condition_to_internal = (boundary_condition_in == 3) ? 2'b0 : boundary_condition_in;

neighbor_link_internal #(
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .MAX_WEIGHT(MAX_WEIGHT),
        .NUM_CONTEXTS(NUM_CONTEXTS)
) neighbor_link (
        .clk(clk),
        .reset(reset),
        .global_stage(global_stage),
        .fully_grown(fully_grown),
        .a_increase(a_increase),
        .b_increase(b_increase),
        .is_boundary(is_boundary),
        .a_is_error_in(a_is_error_in),
        .b_is_error_in(1'b0),
        .is_error(is_error_out),
        .a_input_data(a_input_data),
        .b_input_data(b_input_data),
        .a_output_data(a_output_data),
        .b_output_data(), 
        .weight_in(weight_in), 
        .weight_out(weight_out), 
        .do_not_store(local_context_switch), 
        .boundary_condition_in(boundary_condition_to_internal), 
        .boundary_condition_out(boundary_condition_out),
        .is_error_systolic_in(is_error_systolic_in)
);



endmodule


