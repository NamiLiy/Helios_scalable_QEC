pu_arbitration_unit final_arbitration_unit (
    clk,
    reset,
    .master_fifo_out_data_vector,
    .master_fifo_out_valid_vector,
    .master_fifo_out_ready_vector,
    .master_fifo_in_data_vector,
    .master_fifo_in_valid_vector,
    .master_fifo_in_ready_vector,
    .sc_fifo_out_data,
    .sc_fifo_out_valid,
    .sc_fifo_out_ready,
    .sc_fifo_in_data,
    .sc_fifo_in_valid,
    .sc_fifo_in_ready
    .final_fifo_out_data,
    .final_fifo_out_valid,
    .final_fifo_out_ready,
    .final_fifo_in_data,
    .final_fifo_in_valid,
    .final_fifo_in_ready
);

`include "parameters.sv"

// WARNING : THIS CODE IS HARDCODED TO FIFO_COUNT = 6

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
localparam FIFO_COUNT = CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam FINAL_FIFO_WIDTH = MASTER_FIFO_WIDTH + $clog2(FIFO_COUNT+1);

input [MASTER_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_out_data_vector;
input [FIFO_COUNT - 1 :0] master_fifo_out_valid_vector;
output reg [FIFO_COUNT - 1 :0] master_fifo_out_ready_vector;
output [MASTER_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_in_data_vector;
output reg [FIFO_COUNT - 1 :0] master_fifo_in_valid_vector;
input [FIFO_COUNT - 1 :0] master_fifo_in_ready_vector;

input [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_out_data;
input sc_fifo_out_valid;
output reg sc_fifo_out_ready;
output [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_in_data;
output reg sc_fifo_in_valid;
input sc_fifo_in_ready;

output [FINAL_FIFO_WIDTH - 1 :0] final_fifo_out_data;
output final_fifo_out_valid;
input final_fifo_out_ready;
input [FINAL_FIFO_WIDTH - 1 :0] final_fifo_in_data;
input final_fifo_in_valid;
output final_fifo_in_ready;

reg [FINAL_FIFO_WIDTH-1: 0] final_fifo_out_data_internal;
wire final_fifo_out_valid_internal;
wire final_fifo_out_is_full_internal;

wire [FINAL_FIFO_WIDTH-1: 0] final_fifo_in_data_internal;
reg final_fifo_in_ready_intrernal;
wire final_fifo_in_empty_internal;

wire final_fifo_out_empty;
assign final_fifo_out_valid = ! final_fifo_out_empty;

wire final_fifo_in_full;
assign final_fifo_in_ready = ! final_fifo_in_full;

fifo_fwft #(.DEPTH(16), .WIDTH(ADDRESS_WIDTH+1)) out_fifo 
    (
    .clk(clk),
    .srst(reset),
    .wr_en(final_fifo_out_valid_internal),
    .din(final_fifo_out_data_internal),
    .full(final_fifo_out_is_full_internal),
    .empty(final_fifo_out_empty),
    .dout(final_fifo_out_data),
    .rd_en(final_fifo_out_ready)
);

always@(*) begin
    sc_fifo_out_ready = 1'b0;
    master_fifo_out_ready_vector = 6'b0;
    final_fifo_out_data = {FINAL_FIFO_WIDTH}{1'b0};
    final_fifo_out_data[MASTER_FIFO_WIDTH+ADDRESS_WIDTH - 1 : MASTER_FIFO_WIDTH] = 3'b110;
    final_fifo_out_data[MASTER_FIFO_WIDTH-1:0] = sc_fifo_out_data;
    if(!final_fifo_out_is_full_internal) begin
        if(master_fifo_out_valid[0]) begin
            master_fifo_out_ready_vector == 6'b1;
            final_fifo_out_data[MASTER_FIFO_WIDTH - 1:0] = master_fifo_out_data_vector[MASTER_FIFO_WIDTH - 1:0];
            final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b0;
        end else if(master_fifo_out_valid[1]) begin
            master_fifo_out_ready_vector == 6'b10;
            final_fifo_out_data[MASTER_FIFO_WIDTH - 1:0] = master_fifo_out_data_vector[MASTER_FIFO_WIDTH*2 - 1:MASTER_FIFO_WIDTH];
            final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b1;
        end else if(master_fifo_out_valid[2]) begin
            master_fifo_out_ready_vector == 6'b100;
            final_fifo_out_data[MASTER_FIFO_WIDTH - 1:0] = master_fifo_out_data_vector[MASTER_FIFO_WIDTH*3 - 1:MASTER_FIFO_WIDTH*2];
            final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b10;
        end else if(master_fifo_out_valid[3]) begin
            master_fifo_out_ready_vector == 6'b1000;
            final_fifo_out_data[MASTER_FIFO_WIDTH - 1:0] = master_fifo_out_data_vector[MASTER_FIFO_WIDTH*4 - 1:MASTER_FIFO_WIDTH*3];
            final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b11;
        end else if(master_fifo_out_valid[4]) begin
            master_fifo_out_ready_vector == 6'b10000;
            final_fifo_out_data[MASTER_FIFO_WIDTH - 1:0] = master_fifo_out_data_vector[MASTER_FIFO_WIDTH*5 - 1:MASTER_FIFO_WIDTH*4];
            final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b100;
        end else if(master_fifo_out_valid[5]) begin
            master_fifo_out_ready_vector == 6'b100000;
            final_fifo_out_data[MASTER_FIFO_WIDTH - 1:0] = master_fifo_out_data_vector[MASTER_FIFO_WIDTH*6 - 1:MASTER_FIFO_WIDTH*5];
            final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b101;
        end else begin
            sc_fifo_out_ready = 1'b1;
        end
    end
end

assign final_fifo_out_valid_internal = sc_fifo_out_valid | (master_fifo_out_valid != 6'b0);

fifo_fwft #(.DEPTH(16), .WIDTH(ADDRESS_WIDTH+1)) in_fifo 
    (
    .clk(clk),
    .srst(reset),
    .wr_en(final_fifo_in_valid),
    .din(final_fifo_in_data),
    .full(final_fifo_in_full),
    .empty(final_fifo_in_empty_internal),
    .dout(final_fifo_in_data_internal),
    .rd_en(final_fifo_in_ready_internal)
);

assign sc_fifo_in_data = final_fifo_in_data_internal;
assign master_fifo_in_data_vector[MASTER_FIFO_WIDTH - 1:0] = final_fifo_in_data_internal;
assign master_fifo_in_data_vector[MASTER_FIFO_WIDTH*2 - 1:MASTER_FIFO_WIDTH] = final_fifo_in_data_internal;
assign master_fifo_in_data_vector[MASTER_FIFO_WIDTH*3 - 1:MASTER_FIFO_WIDTH*2] = final_fifo_in_data_internal;
assign master_fifo_in_data_vector[MASTER_FIFO_WIDTH*4 - 1:MASTER_FIFO_WIDTH*3] = final_fifo_in_data_internal;
assign master_fifo_in_data_vector[MASTER_FIFO_WIDTH*5 - 1:MASTER_FIFO_WIDTH*4] = final_fifo_in_data_internal;
assign master_fifo_in_data_vector[MASTER_FIFO_WIDTH*6 - 1:MASTER_FIFO_WIDTH*5] = final_fifo_in_data_internal;

always@(*) begin
    master_fifo_in_valid_vector = 6'b0;
    final_fifo_in_ready_internal = 1'b0;
    sc_fifo_in_valid = 1'b0;
    if(!final_fifo_in_empty_internal) begin
        if(final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b00) begin
            final_fifo_in_ready_internal = master_fifo_in_ready_vector[0];
            master_fifo_in_valid_vector = 6'b1;
        end else if(final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b01) begin
            final_fifo_in_ready_internal = master_fifo_in_ready_vector[1];
            master_fifo_in_valid_vector = 6'b10;
        end else if(final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b10) begin
            final_fifo_in_ready_internal = master_fifo_in_ready_vector[2];
            master_fifo_in_valid_vector = 6'b100;
        end else if(final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b11) begin
            final_fifo_in_ready_internal = master_fifo_in_ready_vector[3];
            master_fifo_in_valid_vector = 6'b1000;
        end else if(final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b100) begin
            final_fifo_in_ready_internal = master_fifo_in_ready_vector[4];
            master_fifo_in_valid_vector = 6'b10000;
        end else if(final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b101) begin
            final_fifo_in_ready_internal = master_fifo_in_ready_vector[5];
            master_fifo_in_valid_vector = 6'b100000;
        end else begin
            master_fifo_in_ready_internal = sc_fifo_in_ready;
            sc_fifo_in_valid = 1'b1;
        end
    end
end

endmodule