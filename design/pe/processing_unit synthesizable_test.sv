`timescale 1ns / 1ps

module processing_unit_synthesizable_test #(
    parameter D = 51,
    parameter NEIGHBOR_COUNT = 6,
    parameter NUM_CONTEXTS = 2
) (
    clk,
    reset,
    measurement,
    measurement_out,
    global_stage,

    neighbor_fully_grown,
    neighbor_increase,
    neighbor_is_boundary, //This indicates the PE is connected by a fully grown link to a boundary
    neighbor_is_error,

    input_address, // M,X,Z, address

    input_data,
    output_data,

    odd,
    root,
    busy
 );

`include "../../parameters/parameters.sv"

localparam X_BIT_WIDTH = $clog2(D+1);
localparam Z_BIT_WIDTH = $clog2((D-1)/2);
// localparam Z_BIT_WIDTH = 0;
localparam U_BIT_WIDTH = $clog2(D);
localparam FPGA_BIT_WIDTH = 0;
localparam ADDRESS_WIDTH = X_BIT_WIDTH + Z_BIT_WIDTH + U_BIT_WIDTH + FPGA_BIT_WIDTH + 1;

localparam EXPOSED_DATA_SIZE = ADDRESS_WIDTH + 1 + 1 + 1;

input clk;
input reset;
input measurement;
output measurement_out;
input [STAGE_WIDTH-1:0] global_stage;

input [NEIGHBOR_COUNT-1:0] neighbor_fully_grown;
output neighbor_increase;
input [NEIGHBOR_COUNT-1:0] neighbor_is_boundary;
output [NEIGHBOR_COUNT-1:0] neighbor_is_error;

input [NEIGHBOR_COUNT*EXPOSED_DATA_SIZE-1:0] input_data;
output [NEIGHBOR_COUNT*EXPOSED_DATA_SIZE-1:0] output_data;

input [ADDRESS_WIDTH-1:0] input_address;

output [ADDRESS_WIDTH-1:0] root;
output odd;
output busy;

reg measurement_reg;
reg [STAGE_WIDTH-1:0] global_stage_reg;

reg [NEIGHBOR_COUNT-1:0] neighbor_is_fully_grown_reg;
reg [NEIGHBOR_COUNT-1:0] neighbor_is_boundary_reg;

reg [NEIGHBOR_COUNT*EXPOSED_DATA_SIZE-1:0] input_data_reg;

reg [ADDRESS_WIDTH-1:0] input_address_reg;

always@(posedge clk) begin
    if(reset) begin
        measurement_reg <= 0;
        global_stage_reg <= 0;
        neighbor_is_fully_grown_reg <= 0;
        neighbor_is_boundary_reg <= 0;
        input_data_reg <= 0;
        input_address_reg <= 0;
    end else begin
        measurement_reg <= measurement;
        global_stage_reg <= global_stage;
        neighbor_is_fully_grown_reg <= neighbor_fully_grown;
        neighbor_is_boundary_reg <= neighbor_is_boundary;
        input_data_reg <= input_data;
        input_address_reg <= input_address;
    end
end


processing_unit #(
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .NEIGHBOR_COUNT(NEIGHBOR_COUNT),
    .NUM_CONTEXTS(1)
) u_processing_unit (
    .clk(clk),
    .reset(reset),
    .measurement(measurement_reg),
    .measurement_out(measurement_out),
    .global_stage(global_stage_reg),

    .neighbor_fully_grown(neighbor_is_fully_grown_reg),
    .neighbor_increase(neighbor_increase),
    .neighbor_is_boundary(neighbor_is_boundary_reg),
    .neighbor_is_error(neighbor_is_error),

    .input_address(input_address_reg),

    .input_data(input_data_reg),
    .output_data(output_data),

    .odd(odd),
    .root(root),
    .busy(busy)
    
);


endmodule
 