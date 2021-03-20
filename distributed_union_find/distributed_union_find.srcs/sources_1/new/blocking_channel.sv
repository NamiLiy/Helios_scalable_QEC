`timescale 1ns / 1ps

module blocking_channel #(
    parameter WIDTH = 8  // width of data
) (
    input [WIDTH-1:0] in_data,
    input in_valid,
    output in_is_full,
    output [WIDTH-1:0] out_data,
    output out_valid,
    input out_is_taken,
    input clk,
    input reset
);

// TODO: improve performance
// current implementation doesn't support 1 message / clock, it only supports 1 message / 2 clock cycles
// improve this later but keep the same interface
// the challenge here is that `in_is_full` should not be a combinational logic based on `out_is_taken`
// otherwise multiple processing units could have a super long path of dependency, making the clock rate of the system scaling down with code distance

reg [WIDTH-1:0] buffer_data;
reg buffer_valid;

assign out_data = buffer_data;
assign out_valid = buffer_valid;
assign in_is_full = buffer_valid;

always @(posedge clk) begin
    if (reset) begin
        buffer_valid <= 0;
    end else begin
        if (buffer_valid) begin  // do not take input data
            if (out_is_taken) begin
                buffer_valid <= 0;
            end
        end else begin
            buffer_valid <= in_valid;
            buffer_data <= in_data;
        end
    end
end

endmodule
