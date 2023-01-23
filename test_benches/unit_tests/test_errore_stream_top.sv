`timescale 1ns / 10ps

module error_stream_top_test;

`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

localparam BIT_WIDTH = 64;
localparam CODE_DISTANCE_X = 5;
localparam CODE_DISTANCE_Z = 4;

reg update_errors;
wire [100 - 1 : 0] measurement_values;
reg clk;
reg reset;

rand_gen_top #(.CODE_DISTANCE_X(CODE_DISTANCE_X), .CODE_DISTANCE_Z(CODE_DISTANCE_Z)) rgt(
    .next(update_errors),
    .measurement_values(measurement_values),
    .clk(clk),
    .reset(reset)
);


integer i;
always #5 clk = ~clk;

initial begin
    clk = 1'b1;
    reset = 1'b1;
    update_errors = 0;
    #107;
    reset = 1'b0;
end

always begin
    #500;
    update_errors = 1;
    #10;
    update_errors = 0;
end

// Output verification logic
always @(posedge clk) begin
    if(update_errors) begin
        $display("%h" , measurement_values);
    end
end

endmodule