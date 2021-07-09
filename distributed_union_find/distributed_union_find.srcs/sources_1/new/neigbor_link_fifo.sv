`timescale 1ns / 1ps

module neighbor_link_to_fifo #(
    parameter LENGTH = 2,  // in a graph with integer edge weight, the LENGTH should be weight * 2, LENGHT > 0
    parameter ADDRESS_WIDTH = 12  // width of address, e.g. single measurement standard surface code under d <= 15 could be 4bit * 2 = 8bit
) (
    input clk,
    input reset,
    input initialize,
    output is_fully_grown,
    // used by node a
    input [ADDRESS_WIDTH-1:0] a_old_root_in,
    output [ADDRESS_WIDTH-1:0] b_old_root_out,
    input a_increase,  // should be triggered only once in the stage of STAGE_GROW_BOUNDARY
    // used by node b
    output [ADDRESS_WIDTH:0] neighbor_fifo_out_data, //No minus 1
    output neighbor_fifo_out_valid,
    input neighbor_fifo_out_ready,
    input [ADDRESS_WIDTH:0] neighbor_fifo_in_data,
    input neighbor_fifo_in_valid,
    output neighbor_fifo_in_ready
);

localparam COUNTER_WIDTH = $clog2(LENGTH + 2);  // in the worse case, counter would have a value of LENGTH + 1

reg [ADDRESS_WIDTH-1:0] a_old_root;
reg [ADDRESS_WIDTH-1:0] b_old_root;
reg [COUNTER_WIDTH-1:0] increased;
reg a_increase_stored;

assign a_old_root_out = a_old_root;
assign b_old_root_out = b_old_root;
assign is_fully_grown = increased >= LENGTH;

reg b_increase;

always @(posedge clk) begin
    if (reset) begin
        increased <= 0;
        a_old_root <= 0;
        a_increase_stored <= 0;
    end else if (initialize) begin
        increased <= 0;
        a_old_root <= 0;
        a_increase_stored <= 0;
    end else begin
        a_old_root <= a_old_root_in;
        a_increase_stored <= a_increase;
        // only increase when it's not fully grown, to reduce bits needed
        if (increased < LENGTH) begin
            increased <= increased + a_increase + b_increase;
        end
    end
end

wire [ADDRESS_WIDTH:0] neighbor_fifo_out_data_internal;
reg neighbor_fifo_out_valid_internal;
wire neighbor_fifo_out_is_full_internal;
wire [ADDRESS_WIDTH:0] neighbor_fifo_in_data;
wire neighbor_fifo_in_empty;
wire neighbor_fifo_in_ready_internal;

always @(posedge clk) begin
    if(reset) begin
        b_increase <= 0;
        b_old_root <= 0;
    end else begin
        if (initialize) begin
            b_increase <= 0;
            b_old_root <= 0;
        end else if(neighbor_fifo_in_valid) begin
            if(neighbor_fifo_in_data[ADDRESS_WIDTH] == 1'b1) begin
                b_increase <= 1;
            end
            b_old_root <= neighbor_fifo_in_data[ADDRESS_WIDTH-1 : 0];
        end
    end
end

assign neighbor_fifo_out_data_internal = {a_increase, a_old_root_in};
assign neighbor_fifo_in_ready = 1'b1;

//assert (neighbor_fifo_out_valid_internal && neighbor_fifo_out_is_full_internal && !reset && !initialize) else   $error("Wrote to a full FIFO in neighbor");

assert property(@(posedge clk) (!(neighbor_fifo_out_valid_internal && neighbor_fifo_out_is_full_internal && !reset && !initialize)))
else   $error("Wrote to a full FIFO in neighbor");

always @(*) begin
    if(a_old_root_in != a_old_root && !initialize) begin
        neighbor_fifo_out_valid_internal = 1;
    end else if (a_increase != a_increase_stored && !initialize) begin
        neighbor_fifo_out_valid_internal = 1;
    end
end

wire out_empty;
assign neighbor_fifo_out_valid = !out_empty;

fifo_fwft #(.DEPTH(16), .WIDTH(ADDRESS_WIDTH+1)) temp_fifo 
    (
    .clk(clk),
    .srst(initialize | reset),
    .wr_en(neighbor_fifo_out_valid_internal),
    .din(neighbor_fifo_out_data_internal),
    .full(neighbor_fifo_out_is_full_internal),
    .empty(empty),
    .dout(neighbor_fifo_out_data),
    .rd_en(neighbor_fifo_out_ready)
);

// wire in_full;
// assign neighbor_fifo_in_ready= !in_full;

// fifo_fwft #(.DEPTH(16), .WIDTH(ADDRESS_WIDTH+1)) temp_fifo 
//     (
//     .clk(clk),
//     .srst(initialize | reset),
//     .wr_en(neighbor_fifo_in_valid),
//     .din(neighbor_fifo_in_data),
//     .full(in_full),
//     .empty(empty),
//     .dout(neighbor_fifo_out_data),
//     .rd_en(neighbor_fifo_out_ready)
// );


endmodule
