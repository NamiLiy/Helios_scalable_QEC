`timescale 1ns / 10ps

module test_nonblocking_channel;

`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

reg clk;
reg reset;

localparam DATA_WIDTH = 8;
reg [DATA_WIDTH-1:0] in_data;
reg in_valid;
wire [DATA_WIDTH-1:0] out_data;
wire out_valid;

// instantiate
nonblocking_channel #(.WIDTH(DATA_WIDTH)) u_nonblocking_channel(
    .in_data(in_data),
    .in_valid(in_valid),
    .out_data(out_data),
    .out_valid(out_valid),
    .clk(clk),
    .reset(reset)
);

localparam DATA1 = 8'b10101010;
localparam DATA2 = 8'b11110000;
localparam DATA3 = 8'b01010101;

initial begin
    clk = 1'b0;
    reset = 1'b1;
    in_valid = 0;
    in_data = 0;
    #200;  // delay for 200ns
    reset = 1'b0;
    #200;
    
    // start test
    `assert(out_valid == 0, "there is no valid output after reset");
    in_data = DATA1;
    in_valid = 1'b1;
    #20;
    `assert(out_valid == 1, "valid data sent through channel");
    `assert(out_data == DATA1, "valid data sent through channel");
    in_data = DATA2;
    in_valid = 1'b1;
    #20;
    `assert(out_valid == 1, "valid data sent through channel");
    `assert(out_data == DATA2, "valid data sent through channel");
    in_data = DATA3;
    in_valid = 1'b0;
    #20;
    `assert(out_valid == 0, "no data last clock cycle");
    in_valid = 1'b1;
    #20;
    `assert(out_valid == 1, "valid data sent through channel");
    `assert(out_data == DATA3, "valid data sent through channel");
    in_valid = 1'b0;
    #20;
    `assert(out_valid == 0, "no data last clock cycle");

end

always #10 clk = ~clk;  // flip every 10ns, that is 50MHz clock

endmodule
