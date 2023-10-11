`timescale 1ns / 1ps

// This PE stores the data of the missing vertex to help with the decoding process at the boundary vertex

module support_processing_unit #(
    parameter ADDRESS_WIDTH = 6
) (
    clk,
    reset,
    global_stage,

    output_data,
    input_data
);

`include "../../parameters/parameters.sv"

localparam EXPOSED_DATA_SIZE = ADDRESS_WIDTH + 1 + 1 + 1;

input clk;
input reset;

input [STAGE_WIDTH-1:0] global_stage;

input [EXPOSED_DATA_SIZE-1:0] input_data;
output reg [EXPOSED_DATA_SIZE-1:0] output_data;



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

always@(posedge clk) begin
    if(reset) begin
        output_data <= 0;
    end else begin
        if(stage == STAGE_WRITE_TO_MEM) begin
            output_data <= input_data;
        end
    end
end
            

endmodule