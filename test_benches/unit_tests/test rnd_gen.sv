`timescale 1ns / 10ps

module rnd_gen_test;

`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

localparam BIT_WIDTH = 64;

reg [BIT_WIDTH - 1 : 0] s0_initial;
reg [BIT_WIDTH - 1 : 0] s1_initial;
wire [BIT_WIDTH - 1 : 0] r;
reg next_u64;
wire valid;
reg clk;
reg reset;

rand_gen_stage rg(
    .s0_initial(s0_initial),
    .s1_initial(s1_initial),
    .s0_new(),
    .s1_new(),
    .r(r),
    .next_u64(next_u64),
    .valid,
    .clk(clk),
    .reset(reset)
);

integer i;
always #5 clk = ~clk;

initial begin
    clk = 1'b1;
    reset = 1'b1;
    s0_initial = 64'd7646591175198567294;
    s1_initial = 64'd15909465551595111888;
    next_u64 = 0;
    #107;
    reset = 1'b0;
    #100;
    next_u64 = 1;
    #10;
    next_u64 = 0;
    #100;
    next_u64 = 1;
    #10;
    next_u64 = 0;
    #100;
    next_u64 = 1;
    #10;
    next_u64 = 0;
    #100;
    next_u64 = 1;
    #10;
    next_u64 = 0;
    #100;
    next_u64 = 1;
    #10;
    next_u64 = 0;
    #100;
    next_u64 = 1;
    #10;
    next_u64 = 0;
    #100;
    next_u64 = 1;
    #10;
    next_u64 = 0;
    #100;
    next_u64 = 1;
    #10;
    next_u64 = 0;
    #100;
    next_u64 = 1;
    #10;
    next_u64 = 0;
    #100;
    next_u64 = 1;
    #10;
    next_u64 = 0;
    #100;
end

// Output verification logic
always @(posedge clk) begin
    if(valid) begin
        $display("%h" , r);
    end
end

endmodule