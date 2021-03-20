`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Namitha Liyanage and Yue Wu
// 
// Create Date: 03/20/2021 05:56:34 PM
// Design Name: 
// Module Name: nonblocking_channel
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module nonblocking_channel #(
    parameter WIDTH = 8  // width of data
) (
    input [WIDTH-1:0] in_data,
    input in_valid,
    output [WIDTH-1:0] out_data,
    output out_valid,
    input clk,
    input reset
);

reg [WIDTH-1:0] buffer_data;
reg buffer_valid;

assign out_data = buffer_data;
assign out_valid = buffer_valid;

always @(posedge clk) begin
    if (reset) begin
        buffer_valid <= 0;
    end else begin
        buffer_valid <= in_valid;
        buffer_data <= in_data;
    end
end

endmodule
