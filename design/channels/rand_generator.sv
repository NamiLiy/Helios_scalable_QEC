module rand_gen_stage(
    s0_initial,
    s1_initial,
    s0_new,
    s1_new,
    r,
    next_u64,
    valid,
    clk,
    reset
);

localparam BIT_WIDTH = 64;

input [BIT_WIDTH - 1 : 0] s0_initial;
input [BIT_WIDTH - 1 : 0] s1_initial;
output [BIT_WIDTH - 1 : 0] s0_new;
output [BIT_WIDTH - 1 : 0] s1_new;
output [BIT_WIDTH - 1 : 0] r;
input next_u64;
output valid;

input clk;
input reset;

reg [BIT_WIDTH - 1 : 0] r1;
reg [BIT_WIDTH - 1 : 0] r2;
reg [BIT_WIDTH - 1 : 0] r3;
reg [BIT_WIDTH - 1 : 0] s1_1;
reg [BIT_WIDTH - 1 : 0] s1_2;
reg [BIT_WIDTH - 1 : 0] s0_1;
reg [BIT_WIDTH - 1 : 0] s0_2;

reg [BIT_WIDTH - 1 : 0] s0;
reg [BIT_WIDTH - 1 : 0] s1;

reg next_u64_d1;
reg next_u64_d2;
reg next_u64_d3;
reg next_u64_d4;

always @(posedge clk) begin
    if(reset) begin
        s0 <= s0_initial;
        s1 <= s1_initial;
        next_u64_d1 <= 0;
    end else begin
        if(next_u64) begin
            s0 <= s0_2;
            s1 <= s1_2;
        end
        next_u64_d1 <= next_u64; 
    end
end

always@(posedge clk) begin
    r1 <= s0*5;
    r2 [BIT_WIDTH - 1 : 7] <= r1[BIT_WIDTH - 1 -7 : 0];
    r2 [6 : 0] <= r1[BIT_WIDTH - 1 : BIT_WIDTH - 1 - 6];
    r3 <= r2*9;

    next_u64_d2 <= next_u64_d1;
    next_u64_d3 <= next_u64_d2;
    next_u64_d4 <= next_u64_d3;
    

    s1_1 <= s0^s1;

    s0_1 [BIT_WIDTH - 1 : 24] <= s0[BIT_WIDTH - 1 - 24 : 0];
    s0_1 [24-1 : 0] <= s0[BIT_WIDTH - 1 : BIT_WIDTH - 24];
    s0_2 <= s0_1^s1_1^(s1_1 << 16);

    s1_2 [BIT_WIDTH - 1 : 37] <= s1_1[BIT_WIDTH - 1 - 37 : 0];
    s1_2 [37-1 : 0] <= s1_1[BIT_WIDTH - 1 : BIT_WIDTH - 37];
end

assign r = r3;
assign s0_new = s0_2;
assign s1_new = s1_2;
assign valid = next_u64_d4;

endmodule


