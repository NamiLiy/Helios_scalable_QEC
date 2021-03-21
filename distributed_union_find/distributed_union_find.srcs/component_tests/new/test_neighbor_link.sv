`timescale 1ns / 10ps

module test_neighbor_link;

`define assert(condition, reason) if(!condition) begin $display(reason); $finish(1); end

reg clk;
reg reset;

localparam ADDRESS_WIDTH = 8;

wire is_fully_grown;
// used by node a
reg [ADDRESS_WIDTH-1:0] a_old_root_in;
wire [ADDRESS_WIDTH-1:0] b_old_root_out;
reg a_increase;
// used by node b
reg [ADDRESS_WIDTH-1:0] b_old_root_in;
wire [ADDRESS_WIDTH-1:0] a_old_root_out;
reg b_increase;

// instantiate
neighbor_link #(.LENGTH(2), .ADDRESS_WIDTH(ADDRESS_WIDTH)) u_neighbor_link(
    .clk(clk),
    .reset(reset),
    .is_fully_grown(is_fully_grown),
    .a_old_root_in(a_old_root_in),
    .b_old_root_out(b_old_root_out),
    .a_increase(a_increase),
    .b_old_root_in(b_old_root_in),
    .a_old_root_out(a_old_root_out),
    .b_increase(b_increase)
);

localparam ADDRESS1 = 8'b10101010;
localparam ADDRESS2 = 8'b11110000;

initial begin
    clk = 1'b0;
    reset = 1'b1;
    a_old_root_in = 0;
    a_increase = 0;
    b_old_root_in = 0;
    b_increase = 0;
    #200;  // delay for 200ns
    reset = 1'b0;
    #200;
    
    // start test
    `assert(is_fully_grown == 0, "start with not grown state");
    `assert(a_old_root_out == 0, "uninitialized");
    `assert(b_old_root_out == 0, "uninitialized");
    a_increase = 1;
    a_old_root_in = ADDRESS1;
    b_old_root_in = ADDRESS2;
    #20;
    `assert(is_fully_grown == 0, "not enough for fully grown yet");
    `assert(a_old_root_out == ADDRESS1, "old_root should be initialized");
    `assert(b_old_root_out == ADDRESS2, "old_root should be initialized");
    a_increase = 1;
    b_increase = 1;
    #20;
    `assert(is_fully_grown == 1, "fully grown");
    a_increase = 1;
    b_increase = 1;
    #20;
    `assert(is_fully_grown == 1, "still fully grown");
    a_increase = 0;
    b_increase = 0;
    #20;
    `assert(is_fully_grown == 1, "still fully grown");

end

always #10 clk = ~clk;  // flip every 10ns, that is 50MHz clock

endmodule
