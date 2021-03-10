
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module unit_test_fifo;

`include "parameters.v"

reg clk;
reg reset;
    // FIFO inputs interface
reg valid_in;
reg [7:0] value_in;
wire             full;
    // FIFO output interface
wire             empty;
wire [7:0] value;
reg             read_en;

fifo_fwft #(.DEPTH(8), .WIDTH(8)) fifo_uut(
  .clk(clk),
  .srst(reset),
  .din(value_in),
  .wr_en(valid_in),
  .rd_en(read_en),
  .dout(value),
  .full(full),
  .empty(empty)
);

always 
begin
    clk = 1'b1; 
    #5; // high for 20 * timescale = 20 ns

    clk = 1'b0;
    #5; // low for 20 * timescale = 20 ns
end

initial
begin
    reset = 1;
    valid_in = 0;
    value_in = 0;
    read_en = 0;
    #102;
    reset = 0;
    #20;
    value_in = 1;
    valid_in = 1;
    #10;
    valid_in = 0;
    read_en = 1;
    #10;
    read_en = 0;
    #20;
    value_in = 2;
    valid_in = 1;
    #10;
    read_en = 1;
    #10;
    value_in = 3;
    #10;
    value_in = 4;
    #10;
    value_in = 5;
    #10;
    valid_in = 0;
    #40;
    read_en = 0;
    #40;
    value_in = 6;
    valid_in = 1;
    #10;
    value_in = 7;
    #10;
    value_in = 8;
    #10;
    value_in = 9;
    #10;
    valid_in = 0;
    #40;
    read_en = 1;
    #100;
    
end

endmodule