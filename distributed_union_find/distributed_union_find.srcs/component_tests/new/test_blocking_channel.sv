`timescale 1ns / 10ps

module test_blocking_channel;

`define assert(condition, reason) if(!condition) begin $display(reason); $finish(1); end

reg clk;
reg reset;

localparam DATA_WIDTH = 8;
reg [DATA_WIDTH-1:0] in_data;
reg in_valid;
wire in_is_full;
wire [DATA_WIDTH-1:0] out_data;
wire out_valid;
reg out_is_taken;


// instantiate
blocking_channel #(.WIDTH(DATA_WIDTH)) u_blocking_channel(
    .in_data(in_data),
    .in_valid(in_valid),
    .in_is_full(in_is_full),
    .out_data(out_data),
    .out_valid(out_valid),
    .out_is_taken(out_is_taken),
    .clk(clk),
    .reset(reset)
);

localparam DATA1 = 8'b10101010;
localparam DATA2 = 8'b11110000;
localparam DATA3 = 8'b01010101;

initial begin
    clk = 0;
    reset = 1;
    in_valid = 0;
    in_data = 0;
    out_is_taken = 0;
    #200;  // delay for 200ns
    reset = 0;
    #200;
    
    // start test
    `assert(out_valid == 0, "there is no valid output after reset");
    `assert(in_is_full == 0, "initial state should not be full");
    in_data = DATA1;
    in_valid = 1;
    #20;
    `assert(out_valid == 1, "valid data sent through channel");
    `assert(out_data == DATA1, "valid data sent through channel");
    `assert(in_is_full == 1, "data inserted into the channel with capacity of 1, so it's full");
    #20;
    `assert(out_valid == 1, "valid data sent through channel");
    `assert(out_data == DATA1, "valid data sent through channel");
    `assert(in_is_full == 1, "data inserted into the channel with capacity of 1, so it's full");
    // take data from the channel
    out_is_taken = 1;
    #20;
    `assert(out_valid == 0, "data should be taken");
    `assert(in_is_full == 0, "data should be taken");
    // insert another one
    out_is_taken = 0;
    in_data = DATA2;
    in_valid = 1;
    #20;
    `assert(out_valid == 1, "valid data sent through channel");
    `assert(out_data == DATA2, "valid data sent through channel");
    `assert(in_is_full == 1, "data inserted into the channel with capacity of 1, so it's full");
    // try to insert when `in_is_full` is 1, should fail to insert even though the peer is taking the last message
    in_data = DATA3;
    in_valid = 1;
    out_is_taken = 1;
    #20;
    `assert(out_valid == 0, "data is taken without DATA3 inserted");
    `assert(in_is_full == 0, "data is taken without DATA3 inserted");
    in_data = DATA3;
    in_valid = 1;
    out_is_taken = 0;
    #20;
    `assert(out_valid == 1, "valid data sent through channel");
    `assert(out_data == DATA3, "valid data sent through channel");
    out_is_taken = 1;
    in_valid = 0;
    #20;
    `assert(out_valid == 0, "data is taken");
    `assert(in_is_full == 0, "data is taken");
    out_is_taken = 0;

end

always #10 clk = ~clk;  // flip every 10ns, that is 50MHz clock

endmodule
