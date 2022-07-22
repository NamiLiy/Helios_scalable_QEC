`timescale 1ns / 10ps

module error_stream_test;

`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

localparam BIT_WIDTH = 64;
localparam MEASUREMENT_ROUNDS = 5;

reg [BIT_WIDTH - 1 : 0] s0_initial;
reg [BIT_WIDTH - 1 : 0] s1_initial;
reg update_errors;
wire update_valid;
wire [MEASUREMENT_ROUNDS - 1 : 0] error_stream;
reg clk;
reg reset;

error_stream #(.MEASUREMENT_ROUNDS(MEASUREMENT_ROUNDS)) es(
    .s0_initial(s0_initial),
    .s1_initial(s1_initial),
    .update_errors(update_errors),
    .update_valid(update_valid),
    .error_stream(error_stream),
    .clk(clk),
    .reset(reset)
);

reg update_valid_d;
wire update_valid_pulse;

assign update_valid_pulse = (update_valid_d == 0 && update_valid == 1) ? 1 : 0;

always @(posedge clk) begin
    if(reset) begin
        update_valid_d <= 0;
    end else begin
        update_valid_d <= update_valid;
    end
end

integer i;
always #5 clk = ~clk;

initial begin
    clk = 1'b1;
    reset = 1'b1;
    s0_initial = 64'd7646591175198567294;
    s1_initial = 64'd15909465551595111888;
    update_errors = 0;
    #107;
    reset = 1'b0;
    #500;
    update_errors = 1;
    #10;
    update_errors = 0;
    #500;
    update_errors = 1;
    #10;
    update_errors = 0;
    #100;
end

// Output verification logic
always @(posedge clk) begin
    if(update_valid_pulse) begin
        $display("%b" , error_stream);
    end
end

endmodule