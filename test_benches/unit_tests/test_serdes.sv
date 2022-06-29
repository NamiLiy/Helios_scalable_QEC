`timescale 1ns / 10ps

module serdes_decoder;

`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

localparam HUB_FIFO_WIDTH = 32;
localparam HUB_FIFO_PHYSICAL_WIDTH = 4;

reg clk;
reg reset;

reg [HUB_FIFO_WIDTH - 1 : 0] input_fifo_data;
reg input_fifo_valid;

wire input_fifo_empty;
wire [HUB_FIFO_WIDTH - 1 : 0] input_fifo_internal_data;
wire input_fifo_rd_en;


fifo_fwft #(.DEPTH(128), .WIDTH(HUB_FIFO_WIDTH)) in_fifo 
    (
    .clk(clk),
    .srst(reset),
    .wr_en(input_fifo_valid),
    .din(input_fifo_data),
    .full(),
    .empty(input_fifo_empty),
    .dout(input_fifo_internal_data),
    .rd_en(input_fifo_rd_en)
);

wire ser_valid;
assign ser_valid = !input_fifo_empty;

wire narrow_fifo_valid;
wire [HUB_FIFO_PHYSICAL_WIDTH - 1 : 0] narrow_fifo_data;
wire narrow_fifo_ready;

serializer #(.HUB_FIFO_WIDTH(HUB_FIFO_WIDTH), .HUB_FIFO_PHYSICAL_WIDTH(HUB_FIFO_PHYSICAL_WIDTH)) ser
(
    .clk(clk),
    .reset(reset),
    .wide_fifo_data(input_fifo_internal_data),
    .wide_fifo_valid(ser_valid),
    .wide_fifo_ready(input_fifo_rd_en),
    .narrow_fifo_valid(narrow_fifo_valid),
    .narrow_fifo_ready(narrow_fifo_ready),
    .narrow_fifo_data(narrow_fifo_data)
);

wire narrow_fifo_full;
assign narrow_fifo_ready = !narrow_fifo_full;
wire narrow_fifo_empty;
wire [HUB_FIFO_PHYSICAL_WIDTH - 1 : 0] narrow_fifo_internal_data;
wire narrow_fifo_rd_en;

fifo_fwft #(.DEPTH(4), .WIDTH(HUB_FIFO_PHYSICAL_WIDTH)) narrow_fifo 
    (
    .clk(clk),
    .srst(reset),
    .wr_en(narrow_fifo_valid),
    .din(narrow_fifo_data),
    .full(narrow_fifo_full),
    .empty(narrow_fifo_empty),
    .dout(narrow_fifo_internal_data),
    .rd_en(narrow_fifo_rd_en)
);

wire output_fifo_valid;
wire [HUB_FIFO_WIDTH - 1 : 0] output_fifo_data;
wire output_fifo_ready;
wire narrow_fifo_des_valid;
assign narrow_fifo_des_valid = !narrow_fifo_empty;

deserializer #(.HUB_FIFO_WIDTH(HUB_FIFO_WIDTH), .HUB_FIFO_PHYSICAL_WIDTH(HUB_FIFO_PHYSICAL_WIDTH)) des
(
    .clk(clk),
    .reset(reset),
    .wide_fifo_data(output_fifo_data),
    .wide_fifo_valid(output_fifo_valid),
    .wide_fifo_ready(output_fifo_ready),
    .narrow_fifo_valid(narrow_fifo_des_valid),
    .narrow_fifo_ready(narrow_fifo_rd_en),
    .narrow_fifo_data(narrow_fifo_internal_data)
);

wire output_fifo_full;
assign output_fifo_ready = !output_fifo_full;
reg output_fifo_rd_en;
wire [HUB_FIFO_WIDTH - 1 : 0] output_fifo_final_data;
wire output_fifo_empty;

fifo_fwft #(.DEPTH(4), .WIDTH(HUB_FIFO_WIDTH)) out_fifo 
    (
    .clk(clk),
    .srst(reset),
    .wr_en(output_fifo_valid),
    .din(output_fifo_data),
    .full(output_fifo_full),
    .empty(output_fifo_empty),
    .dout(output_fifo_final_data),
    .rd_en(output_fifo_rd_en)
);

wire [HUB_FIFO_WIDTH - 1 : 0] output_fifo_verify_data;

fifo_fwft #(.DEPTH(128), .WIDTH(HUB_FIFO_WIDTH)) verify_fifo 
    (
    .clk(clk),
    .srst(reset),
    .wr_en(input_fifo_valid),
    .din(input_fifo_data),
    .full(),
    .empty(),
    .dout(output_fifo_verify_data),
    .rd_en(output_fifo_rd_en && !output_fifo_empty)
);

integer i;
always #5 clk = ~clk;

initial begin
    clk = 1'b1;
    reset = 1'b1;
    output_fifo_rd_en = 1'b0;
    input_fifo_data = 32'b0;
    input_fifo_valid = 0;
    #107;
    reset = 1'b0;
    #100;
    input_fifo_data = 32'h12345678;
    input_fifo_valid = 1;
    #10;
    input_fifo_data = 32'h9abcdef0;
    #10;
    input_fifo_data = 32'h11223344;
    #10;
    input_fifo_data = 32'h55667788;
    #10;
    input_fifo_data = 32'h99aabbcc;
    #10;
    input_fifo_data = 32'hddeeff11;
    #10;
    input_fifo_data = 32'h9abcdef0;
    #10;
    input_fifo_data = 32'h11223344;
    #10;
    input_fifo_data = 32'h55667788;
    #10;
    #10;
    input_fifo_data = 32'h99aabbcc;
    #10;
    input_fifo_data = 32'hddeeff11;
    #10;
    input_fifo_data = 32'h9abcdef0;
    #10;
    input_fifo_data = 32'h11223344;
    #10;
    input_fifo_data = 32'h55667788;
    #10;
    input_fifo_data = 32'h99aabbcc;
    #10;
    input_fifo_data = 32'hddeeff11;
    #10;
    input_fifo_valid = 0;
    #200;
    output_fifo_rd_en = 1'b1;
    #1000;
end
endmodule