`timescale 1ns / 1ps

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

always_ff @(posedge clk) begin
    if (reset) begin
        buffer_valid <= 0;
    end else begin
        buffer_valid <= in_valid;
        buffer_data <= in_data;
    end
end

endmodule
