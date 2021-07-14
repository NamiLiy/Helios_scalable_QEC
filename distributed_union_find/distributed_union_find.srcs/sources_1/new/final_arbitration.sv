module final_arbitration_unit #(
    parameter CODE_DISTANCE = 3
)(
    clk,
    reset,
    master_fifo_out_data_vector,
    master_fifo_out_valid_vector,
    master_fifo_out_ready_vector,
    master_fifo_in_data_vector,
    master_fifo_in_valid_vector,
    master_fifo_in_ready_vector,
    sc_fifo_out_data,
    sc_fifo_out_valid,
    sc_fifo_out_ready,
    sc_fifo_in_data,
    sc_fifo_in_valid,
    sc_fifo_in_ready,
    final_fifo_out_data,
    final_fifo_out_valid,
    final_fifo_out_ready,
    final_fifo_in_data,
    final_fifo_in_valid,
    final_fifo_in_ready,
    has_flying_messages
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

input clk;
input reset;

input [MASTER_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_out_data_vector;
input [FIFO_COUNT - 1 :0] master_fifo_out_valid_vector;
output [FIFO_COUNT - 1 :0] master_fifo_out_ready_vector;
output [MASTER_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_in_data_vector;
output [FIFO_COUNT - 1 :0] master_fifo_in_valid_vector;
input [FIFO_COUNT - 1 :0] master_fifo_in_ready_vector;

input [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_out_data;
input sc_fifo_out_valid;
output sc_fifo_out_ready;
output [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_in_data;
output sc_fifo_in_valid;
input sc_fifo_in_ready;

output reg [FINAL_FIFO_WIDTH - 1 :0] final_fifo_out_data;
output final_fifo_out_valid;
input final_fifo_out_ready;
input [FINAL_FIFO_WIDTH - 1 :0] final_fifo_in_data;
input final_fifo_in_valid;
output final_fifo_in_ready;

output has_flying_messages;

reg [FINAL_FIFO_WIDTH-1: 0] final_fifo_out_data_internal;
wire final_fifo_out_valid_internal;
wire final_fifo_out_is_full_internal;

wire [FINAL_FIFO_WIDTH-1: 0] final_fifo_in_data_internal;
reg final_fifo_in_ready_internal;
wire final_fifo_in_empty_inernal;

wire final_fifo_out_empty;
assign final_fifo_out_valid = ! final_fifo_out_empty;

wire final_fifo_in_full;
assign final_fifo_in_ready = ! final_fifo_in_full;

reg has_flying_messages_reg;

always@(posedge clk) begin
    if (reset) begin
        has_flying_messages_reg <= 0;
    end else begin
        has_flying_messages_reg <= sc_fifo_out_valid || final_fifo_out_valid || (master_fifo_out_valid_vector != 0);
    end
end

assign has_flying_messages = has_flying_messages_reg;

fifo_fwft #(.DEPTH(16), .WIDTH(FINAL_FIFO_WIDTH)) out_fifo 
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

localparam TRUE_FIFO_COUNT = FIFO_COUNT + 1; //2

wire [TRUE_FIFO_COUNT*MASTER_FIFO_WIDTH - 1 : 0] combined_fifo_out_data_vector;
wire [TRUE_FIFO_COUNT - 1 : 0] combined_fifo_out_valid_vector;
wire [TRUE_FIFO_COUNT - 1 : 0] combined_fifo_out_ready_vector;

assign combined_fifo_out_data_vector [FIFO_COUNT*MASTER_FIFO_WIDTH - 1 : 0] = master_fifo_out_data_vector;
assign combined_fifo_out_data_vector [TRUE_FIFO_COUNT*MASTER_FIFO_WIDTH - 1 : FIFO_COUNT*MASTER_FIFO_WIDTH] = sc_fifo_out_data;
assign combined_fifo_out_valid_vector[FIFO_COUNT - 1 : 0]  = master_fifo_out_valid_vector;
assign combined_fifo_out_valid_vector[FIFO_COUNT]  = sc_fifo_out_valid;
assign master_fifo_out_ready_vector = combined_fifo_out_ready_vector[FIFO_COUNT - 1 : 0];
assign sc_fifo_out_ready = combined_fifo_out_ready_vector[FIFO_COUNT];

`define master_coming_data(i) combined_fifo_out_data_vector[((i+1) * MASTER_FIFO_WIDTH) - 1 : (i * MASTER_FIFO_WIDTH)]
`define master_coming_valid(i) combined_fifo_out_valid_vector[i]
`define master_coming_is_taken(i) combined_fifo_out_ready_vector[i]

localparam DIRECT_CHANNEL_DEPTH = $clog2(TRUE_FIFO_COUNT); //2
localparam DIRECT_CHANNEL_EXPAND_COUNT = 2 ** DIRECT_CHANNEL_DEPTH; //4
localparam DIRECT_CHANNEL_ALL_EXPAND_COUNT = 2 * DIRECT_CHANNEL_EXPAND_COUNT - 1;  // the length of tree structured gathering // 7

wire [DIRECT_CHANNEL_ALL_EXPAND_COUNT-1:0] tree_gathering_elected_direct_message_valid;
wire [(MASTER_FIFO_WIDTH * DIRECT_CHANNEL_ALL_EXPAND_COUNT)-1:0] tree_gathering_elected_direct_message_data;
`define expanded_elected_output_message_data(i) tree_gathering_elected_direct_message_data[((i+1) * MASTER_FIFO_WIDTH) - 1 : (i * MASTER_FIFO_WIDTH)]
wire [(MASTER_FIFO_WIDTH * DIRECT_CHANNEL_ALL_EXPAND_COUNT)-1:0] tree_gathering_elected_direct_message_index;
`define expanded_elected_output_message_index(i) tree_gathering_elected_direct_message_index[((i+1) * MASTER_FIFO_WIDTH) - 1 : (i * MASTER_FIFO_WIDTH)]

`define DIRECT_CHANNEL_LAYER_WIDTH (2 ** (DIRECT_CHANNEL_DEPTH - 1 - i))
`define DIRECT_CHANNEL_LAYERT_IDX (2 ** (DIRECT_CHANNEL_DEPTH + 1) - 2 ** (DIRECT_CHANNEL_DEPTH - i))
`define DIRECT_CHANNEL_LAST_LAYERT_IDX (2 ** (DIRECT_CHANNEL_DEPTH + 1) - 2 ** (DIRECT_CHANNEL_DEPTH + 1 - i))
`define DIRECT_CHANNEL_CURRENT_IDX (`DIRECT_CHANNEL_LAYERT_IDX + j)
`define DIRECT_CHANNEL_CHILD_1_IDX (`DIRECT_CHANNEL_LAST_LAYERT_IDX + 2 * j)
`define DIRECT_CHANNEL_CHILD_2_IDX (`DIRECT_CHANNEL_CHILD_1_IDX + 1)
localparam DIRECT_CHANNEL_ROOT_IDX = DIRECT_CHANNEL_ALL_EXPAND_COUNT - 1; // 6

genvar i;

generate
    for (i=0; i < DIRECT_CHANNEL_EXPAND_COUNT; i=i+1) begin: direct_channel_gathering_initialization
        if (i < TRUE_FIFO_COUNT) begin
            assign tree_gathering_elected_direct_message_valid[i] = `master_coming_valid(i);
            assign `expanded_elected_output_message_index(i) = i;
            assign `expanded_elected_output_message_data(i) = `master_coming_data(i);
        end else begin
            assign tree_gathering_elected_direct_message_valid[i] = 0;
        end
    end
    for (i=0; i < DIRECT_CHANNEL_DEPTH; i=i+1) begin: direct_channel_gathering_election
        genvar j;
        for (j=0; j < `DIRECT_CHANNEL_LAYER_WIDTH; j=j+1) begin: direct_channel_gathering_layer_election
            assign tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CURRENT_IDX] = tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CHILD_1_IDX] | tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CHILD_2_IDX];
            assign `expanded_elected_output_message_index(`DIRECT_CHANNEL_CURRENT_IDX) = tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CHILD_1_IDX] ? (
                `expanded_elected_output_message_index(`DIRECT_CHANNEL_CHILD_1_IDX)
            ) : (
                `expanded_elected_output_message_index(`DIRECT_CHANNEL_CHILD_2_IDX)
            );
            assign `expanded_elected_output_message_data(`DIRECT_CHANNEL_CURRENT_IDX) = tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CHILD_1_IDX] ? (
                `expanded_elected_output_message_data(`DIRECT_CHANNEL_CHILD_1_IDX)
            ) : (
                `expanded_elected_output_message_data(`DIRECT_CHANNEL_CHILD_2_IDX)
            );
        end
    end
endgenerate

`define gathered_elected_output_message_valid (tree_gathering_elected_direct_message_valid[DIRECT_CHANNEL_ROOT_IDX])
`define gathered_elected_output_message_index (`expanded_elected_output_message_index(DIRECT_CHANNEL_ROOT_IDX))
`define gathered_elected_output_message_data (`expanded_elected_output_message_data(DIRECT_CHANNEL_ROOT_IDX))

assign final_fifo_out_data_internal[MASTER_FIFO_WIDTH - 1:0] = `gathered_elected_output_message_data;
assign final_fifo_out_data_internal[FINAL_FIFO_WIDTH - 1: MASTER_FIFO_WIDTH] = `gathered_elected_output_message_index;
assign final_fifo_out_valid_internal = `gathered_elected_output_message_valid;

// take the direct message from channel
generate
    for (i=0; i < TRUE_FIFO_COUNT; i=i+1) begin: taking_direct_message
        assign `master_coming_is_taken(i) = 
            ((i == `gathered_elected_output_message_index) && `gathered_elected_output_message_valid  && !final_fifo_out_is_full_internal);
    end
endgenerate

// always@(*) begin
//     sc_fifo_out_ready = 1'b0;
//     master_fifo_out_ready_vector = 6'b0;
//     final_fifo_out_data_internal = {FINAL_FIFO_WIDTH{1'b0}};
//     final_fifo_out_data_internal[MASTER_FIFO_WIDTH+3 - 1 : MASTER_FIFO_WIDTH] = 3'b110;
//     final_fifo_out_data_internal[MASTER_FIFO_WIDTH-1:0] = sc_fifo_out_data;
//     if(!final_fifo_out_is_full_internal) begin
//         if(master_fifo_out_valid_vector[0]) begin
//             master_fifo_out_ready_vector = 6'b1;
//             final_fifo_out_data_internal[MASTER_FIFO_WIDTH - 1:0] = master_fifo_out_data_vector[MASTER_FIFO_WIDTH - 1:0];
//             final_fifo_out_data_internal[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b0;
//         end else if(master_fifo_out_valid_vector[1]) begin
//             master_fifo_out_ready_vector = 6'b10;
//             final_fifo_out_data[MASTER_FIFO_WIDTH - 1:0] = master_fifo_out_data_vector[MASTER_FIFO_WIDTH*2 - 1:MASTER_FIFO_WIDTH];
//             final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b1;
//         end else if(master_fifo_out_valid_vector[2]) begin
//             master_fifo_out_ready_vector = 6'b100;
//             final_fifo_out_data[MASTER_FIFO_WIDTH - 1:0] = master_fifo_out_data_vector[MASTER_FIFO_WIDTH*3 - 1:MASTER_FIFO_WIDTH*2];
//             final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b10;
//         end else if(master_fifo_out_valid_vector[3]) begin
//             master_fifo_out_ready_vector = 6'b1000;
//             final_fifo_out_data[MASTER_FIFO_WIDTH - 1:0] = master_fifo_out_data_vector[MASTER_FIFO_WIDTH*4 - 1:MASTER_FIFO_WIDTH*3];
//             final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b11;
//         end else if(master_fifo_out_valid_vector[4]) begin
//             master_fifo_out_ready_vector = 6'b10000;
//             final_fifo_out_data[MASTER_FIFO_WIDTH - 1:0] = master_fifo_out_data_vector[MASTER_FIFO_WIDTH*5 - 1:MASTER_FIFO_WIDTH*4];
//             final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b100;
//         end else if(master_fifo_out_valid_vector[5]) begin
//             master_fifo_out_ready_vector = 6'b100000;
//             final_fifo_out_data[MASTER_FIFO_WIDTH - 1:0] = master_fifo_out_data_vector[MASTER_FIFO_WIDTH*6 - 1:MASTER_FIFO_WIDTH*5];
//             final_fifo_out_data[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] = 3'b101;
//         end else begin
//             sc_fifo_out_ready = 1'b1;
//         end
//     end
// end

// assign final_fifo_out_valid_internal = sc_fifo_out_valid | (master_fifo_out_valid_vector != 6'b0);

// receiver side

fifo_fwft #(.DEPTH(16), .WIDTH(FINAL_FIFO_WIDTH)) in_fifo 
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

wire [TRUE_FIFO_COUNT*MASTER_FIFO_WIDTH - 1 : 0] combined_fifo_in_data_vector;
wire [TRUE_FIFO_COUNT - 1 : 0] combined_fifo_in_valid_vector;
wire [TRUE_FIFO_COUNT - 1 : 0] combined_fifo_in_ready_vector;

assign master_fifo_in_data_vector = combined_fifo_in_data_vector [FIFO_COUNT*MASTER_FIFO_WIDTH - 1 : 0];
assign sc_fifo_in_data = combined_fifo_in_data_vector [TRUE_FIFO_COUNT*MASTER_FIFO_WIDTH - 1 : FIFO_COUNT*MASTER_FIFO_WIDTH];
assign master_fifo_in_valid_vector = combined_fifo_in_valid_vector[FIFO_COUNT - 1 : 0];
assign sc_fifo_in_valid = combined_fifo_in_valid_vector[FIFO_COUNT];
assign combined_fifo_in_ready_vector[FIFO_COUNT - 1 : 0] = master_fifo_in_ready_vector;
assign combined_fifo_in_ready_vector[FIFO_COUNT] = sc_fifo_in_ready;

`define master_fifo_in_data(i) combined_fifo_in_data_vector[((i+1) * MASTER_FIFO_WIDTH) - 1 : (i * MASTER_FIFO_WIDTH)]
`define master_fifo_in_valid(i) combined_fifo_in_valid_vector[TRUE_FIFO_COUNT - 1 : 0]
`define master_fifo_in_ready(i) combined_fifo_in_ready_vector[TRUE_FIFO_COUNT - 1 : 0]
`define destination_index final_fifo_in_data_internal[FINAL_FIFO_WIDTH - 1: MASTER_FIFO_WIDTH]

generate
    for (i=0; i < TRUE_FIFO_COUNT; i=i+1) begin: writing_incoming_data
        assign `master_fifo_in_data (i) = final_fifo_in_data_internal[MASTER_FIFO_WIDTH - 1 :0];
    end
endgenerate

generate
    for (i=0; i < TRUE_FIFO_COUNT; i=i+1) begin: making_correct_incoming_channel_correct
        assign `master_fifo_in_valid(i) = 
            ((i == `destination_index) && !final_fifo_in_empty_internal);
    end
endgenerate


`define message_read (combined_fifo_in_ready_vector[`destination_index])
assign final_fifo_in_ready_internal = `message_read;


// assign master_fifo_in_data_vector[MASTER_FIFO_WIDTH - 1:0] = final_fifo_in_data_internal;
// assign master_fifo_in_data_vector[MASTER_FIFO_WIDTH*2 - 1:MASTER_FIFO_WIDTH] = final_fifo_in_data_internal;
// assign master_fifo_in_data_vector[MASTER_FIFO_WIDTH*3 - 1:MASTER_FIFO_WIDTH*2] = final_fifo_in_data_internal;
// assign master_fifo_in_data_vector[MASTER_FIFO_WIDTH*4 - 1:MASTER_FIFO_WIDTH*3] = final_fifo_in_data_internal;
// assign master_fifo_in_data_vector[MASTER_FIFO_WIDTH*5 - 1:MASTER_FIFO_WIDTH*4] = final_fifo_in_data_internal;
// assign master_fifo_in_data_vector[MASTER_FIFO_WIDTH*6 - 1:MASTER_FIFO_WIDTH*5] = final_fifo_in_data_internal;

// always@(*) begin
//     master_fifo_in_valid_vector = 6'b0;
//     final_fifo_in_ready_internal = 1'b0;
//     sc_fifo_in_valid = 1'b0;
//     if(!final_fifo_in_empty_internal) begin
//         if(final_fifo_out_data_internal[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] == 3'b00) begin
//             final_fifo_in_ready_internal = master_fifo_in_ready_vector[0];
//             master_fifo_in_valid_vector = 6'b1;
//         end else if(final_fifo_out_data_internal[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] == 3'b01) begin
//             final_fifo_in_ready_internal = master_fifo_in_ready_vector[1];
//             master_fifo_in_valid_vector = 6'b10;
//         end else if(final_fifo_out_data_internal[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] == 3'b10) begin
//             final_fifo_in_ready_internal = master_fifo_in_ready_vector[2];
//             master_fifo_in_valid_vector = 6'b100;
//         end else if(final_fifo_out_data_internal[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] == 3'b11) begin
//             final_fifo_in_ready_internal = master_fifo_in_ready_vector[3];
//             master_fifo_in_valid_vector = 6'b1000;
//         end else if(final_fifo_out_data_internal[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] == 3'b100) begin
//             final_fifo_in_ready_internal = master_fifo_in_ready_vector[4];
//             master_fifo_in_valid_vector = 6'b10000;
//         end else if(final_fifo_out_data_internal[MASTER_FIFO_WIDTH+2 : MASTER_FIFO_WIDTH] == 3'b101) begin
//             final_fifo_in_ready_internal = master_fifo_in_ready_vector[5];
//             master_fifo_in_valid_vector = 6'b100000;
//         end else begin
//             final_fifo_in_ready_internal = sc_fifo_in_ready;
//             sc_fifo_in_valid = 1'b1;
//         end
//     end
// end

endmodule