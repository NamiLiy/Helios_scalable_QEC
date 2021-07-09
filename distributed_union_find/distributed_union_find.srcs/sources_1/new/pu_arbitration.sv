module pu_arbitration_unit #(
    parameter CODE_DISTANCE = 3
)(
    clk,
    reset,
    neighbor_fifo_out_data,
    neighbor_fifo_out_valid,
    neighbor_fifo_out_ready,
    neighbor_fifo_in_data,
    neighbor_fifo_in_valid,
    neighbor_fifo_in_ready,
    non_blocking_fifo_out_data,
    non_blocking_fifo_out_valid,
    non_blocking_fifo_out_ready,
    non_blocking_fifo_in_data,
    non_blocking_fifo_in_valid,
    non_blocking_fifo_in_ready,
    blocking_fifo_out_data,
    blocking_fifo_out_valid,
    blocking_fifo_out_ready,
    blocking_fifo_in_data,
    blocking_fifo_in_valid,
    blocking_fifo_in_ready,
    master_fifo_out_data,
    master_fifo_out_valid,
    master_fifo_out_ready,
    master_fifo_in_data,
    master_fifo_in_valid,
    master_fifo_in_ready,
    has_flying_messages
);

`include "parameters.sv"

localparam PU_COUNT = CODE_DISTANCE * CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam DISTANCE_WIDTH = 1 + PER_DIMENSION_WIDTH;
localparam WEIGHT = 1;  // the weight in MWPM graph
localparam BOUNDARY_COST = 2 * WEIGHT;
localparam NEIGHBOR_COST = 2 * WEIGHT;
localparam BOUNDARY_WIDTH = $clog2(BOUNDARY_COST + 1);
localparam UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH;  // [old_root, updated_root]
localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]
localparam MASTER_FIFO_WIDTH = UNION_MESSAGE_WIDTH + 1 + 1;
localparam FINAL_FIFO_WIDTH = MASTER_FIFO_WIDTH + ADDRESS_WIDTH;
localparam FIFO_COUNT = CODE_DISTANCE * (CODE_DISTANCE - 1);

input clk;
input reset;

input [ADDRESS_WIDTH:0] neighbor_fifo_out_data; //not -1 to support extra signal
input neighbor_fifo_out_valid;
output reg neighbor_fifo_out_ready;
output [ADDRESS_WIDTH:0] neighbor_fifo_in_data;
output reg neighbor_fifo_in_valid;
input neighbor_fifo_in_ready;
input [UNION_MESSAGE_WIDTH-1: 0] non_blocking_fifo_out_data;
input non_blocking_fifo_out_valid;
output reg  non_blocking_fifo_out_ready;
output [UNION_MESSAGE_WIDTH-1: 0] non_blocking_fifo_in_data;
output reg non_blocking_fifo_in_valid;
input non_blocking_fifo_in_ready;
input [DIRECT_MESSAGE_WIDTH-1: 0] blocking_fifo_out_data;
input blocking_fifo_out_valid;
output reg  blocking_fifo_out_ready;
output [DIRECT_MESSAGE_WIDTH-1: 0] blocking_fifo_in_data;
output reg blocking_fifo_in_valid;
input reg blocking_fifo_in_ready;
output [MASTER_FIFO_WIDTH-1: 0] master_fifo_out_data;
output master_fifo_out_valid;
input master_fifo_out_ready;
input [MASTER_FIFO_WIDTH-1: 0] master_fifo_in_data;
input master_fifo_in_valid;
output master_fifo_in_ready;

reg [MASTER_FIFO_WIDTH-1: 0] master_fifo_out_data_internal;
wire master_fifo_out_valid_internal;
wire master_fifo_out_is_full_internal;

wire [MASTER_FIFO_WIDTH-1: 0] master_fifo_in_data_internal;
reg master_fifo_in_ready_internal;
wire master_fifo_in_empty_internal;

wire master_fifo_out_empty;
assign master_fifo_out_valid = ! master_fifo_out_empty;

wire master_fifo_in_full;
assign master_fifo_in_ready = ! master_fifo_in_full;

wire has_flying_messages;
assign has_flying_messages = neighbor_fifo_out_avalid || neighbor_fifo_in_valid || non_blocking_fifo_out_valid || non_blocking_fifo_in_valid || blocking_fifo_out_valid || blocking_fifo_in_valid || master_fifo_out_valid || master_fifo_in_valid;

fifo_fwft #(.DEPTH(16), .WIDTH(ADDRESS_WIDTH+1)) out_fifo 
    (
    .clk(clk),
    .srst(reset),
    .wr_en(master_fifo_out_valid_internal),
    .din(master_fifo_out_data_internal),
    .full(master_fifo_out_is_full_internal),
    .empty(master_fifo_out_empty),
    .dout(master_fifo_out_data),
    .rd_en(master_fifo_out_ready)
);

always@(*) begin
    neighbor_fifo_out_ready = 1'b0;
    non_blocking_fifo_out_ready = 1'b0;
    blocking_fifo_out_ready = 1'b0;
    master_fifo_out_data_internal = {(UNION_MESSAGE_WIDTH + 2){1'b0}};
    master_fifo_out_data_internal[UNION_MESSAGE_WIDTH+1 : UNION_MESSAGE_WIDTH] = 2'b11;
    master_fifo_out_data_internal[DIRECT_MESSAGE_WIDTH-1:0] = blocking_fifo_out_data;
    if(!master_fifo_out_is_full_internal) begin
        if(neighbor_fifo_out_valid) begin
            neighbor_fifo_out_ready = 1'b1;
            master_fifo_out_data_internal[ADDRESS_WIDTH:0] = neighbor_fifo_out_data;
            master_fifo_out_data_internal[UNION_MESSAGE_WIDTH+1 : UNION_MESSAGE_WIDTH] = 2'b00;
        end else if (non_blocking_fifo_out_valid) begin
            non_blocking_fifo_out_ready = 1'b1;
            master_fifo_out_data_internal[UNION_MESSAGE_WIDTH-1:0] = non_blocking_fifo_out_data;
            master_fifo_out_data_internal[UNION_MESSAGE_WIDTH+1 : UNION_MESSAGE_WIDTH] = 2'b11;
        end else begin
            blocking_fifo_out_ready = 1'b1;
        end
    end
end

assign master_fifo_out_valid_internal = neighbor_fifo_out_valid | non_blocking_fifo_out_valid | blocking_fifo_out_valid;

fifo_fwft #(.DEPTH(16), .WIDTH(ADDRESS_WIDTH+1)) in_fifo 
    (
    .clk(clk),
    .srst(reset),
    .wr_en(master_fifo_in_valid),
    .din(master_fifo_in_data),
    .full(master_fifo_in_full),
    .empty(master_fifo_in_empty_internal),
    .dout(master_fifo_in_data_internal),
    .rd_en(master_fifo_in_ready_internal)
);

assign neighbor_fifo_in_data = master_fifo_in_data_internal;
assign non_blocking_fifo_in_data = master_fifo_in_data_internal;
assign blocking_fifo_in_data = master_fifo_in_data_internal;

always@(*) begin
    master_fifo_in_ready_internal = 1'b0;
    neighbor_fifo_in_valid = 1'b0;
    non_blocking_fifo_in_valid = 1'b0;
    blocking_fifo_in_valid = 1'b0;
    if(!master_fifo_in_empty_internal) begin
        if(master_fifo_in_data_internal[UNION_MESSAGE_WIDTH+1 : UNION_MESSAGE_WIDTH] == 2'b00) begin
            master_fifo_in_ready_internal = neighbor_fifo_in_ready;
            neighbor_fifo_in_valid = 1'b1;
        end else if (master_fifo_in_data_internal[UNION_MESSAGE_WIDTH+1 : UNION_MESSAGE_WIDTH] == 2'b01) begin
            master_fifo_in_ready_internal = non_blocking_fifo_in_ready;
            non_blocking_fifo_in_valid = 1'b1;
        end else begin
            master_fifo_in_ready_internal = blocking_fifo_in_ready;
            blocking_fifo_in_valid = 1'b1;
        end
    end
end

endmodule
