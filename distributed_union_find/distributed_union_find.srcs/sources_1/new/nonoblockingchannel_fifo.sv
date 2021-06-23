`timescale 1ns / 1ps

module nonblocking_channel_to_fifo #(
    parameter WIDTH = 8  // width of data
) (
    input [WIDTH-1:0] in_data,
    input in_valid,
    // output [WIDTH-1:0] out_data,
    // output out_valid,
    output [WIDTH-1:0] nonblocking_fifo_out_data,
    output nonblocking_fifo_out_valid,
    input nonblocking_fifo_out_ready,
    input clk,
    input reset,
    input initialize
);

wire empty;
assign nonblocking_fifo_out_valid = !empty;

wire full;

assert (in_valid && full && !reset && !initialize) 
else   $error("Wrote to a full FIFO in nonblocking");


fifo_fwft #(.DEPTH(16), .WIDTH(WIDTH)) temp_fifo 
    (
    .clk(clk),
    .srst(initialize | reset),
    .wr_en(in_valid),
    .din(in_data),
    .full(full),
    .empty(empty),
    .dout(nonblocking_fifo_out_data),
    .rd_en(nonblocking_fifo_out_ready)
);

endmodule

module nonblocking_channel_from_fifo #(
    parameter WIDTH = 8  // width of data
) (
    input [ADDRESS_WIDTH:0] nonblocking_fifo_in_data,
    input nonblocking_fifo_in_valid,
    output nonblocking_fifo_in_ready,
    output [WIDTH-1:0] out_data,
    output out_valid,
    input clk,
    input reset,
    input initialize
);

assign out_valid = nonblocking_fifo_in_valid;
assign out_data = nonblocking_fifo_in_data;
assign nonblocking_fifo_in_ready = 1'b1;

endmodule
