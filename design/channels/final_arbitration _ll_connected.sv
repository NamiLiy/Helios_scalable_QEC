module final_arbitration_ll_connected_unit#(
    // parameter CODE_DISTANCE_X = 5,
    // parameter CODE_DISTANCE_Z = 4,
    parameter HUB_FIFO_WIDTH = 32,
    parameter HUB_FIFO_PHYSICAL_WIDTH = 8, //this should exclude valid and ready or out of band signals
    parameter FPGAID_WIDTH = 4,
    // parameter MY_ID = 0 ,
    // parameter X_START = 0,
    // parameter X_END = 0,
    parameter FIFO_IDWIDTH = 8,
    parameter FIFO_COUNT = 8,
    parameter FPGA_NEIGHBORS = 2
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
    has_flying_messages,
    fpga_neighbor_array
);

`include "parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
// localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
// localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
// localparam PER_DIMENSION_WIDTH = $clog2(MEASUREMENT_ROUNDS);
// localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
// localparam DISTANCE_WIDTH = 1 + PER_DIMENSION_WIDTH;
// localparam WEIGHT = 1;  // the weight in MWPM graph
// localparam BOUNDARY_COST = 2 * WEIGHT;
// localparam NEIGHBOR_COST = 2 * WEIGHT;
// localparam BOUNDARY_WIDTH = $clog2(BOUNDARY_COST + 1);
// localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]
// localparam MASTER_FIFO_WIDTH = DIRECT_MESSAGE_WIDTH + 1;
// // localparam FIFO_COUNT = MEASUREMENT_ROUNDS * (CODE_DISTANCE_Z);
// localparam FINAL_FIFO_WIDTH = MASTER_FIFO_WIDTH + $clog2(FIFO_COUNT+1);

// localparam TOP_FPGA_ID = MY_ID - 1;
// localparam BOTTOM_FPGA_ID = MY_ID + 1;

input clk;
input reset;

input [HUB_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_out_data_vector;
input [FIFO_COUNT - 1 :0] master_fifo_out_valid_vector;
output [FIFO_COUNT - 1 :0] master_fifo_out_ready_vector;
output [HUB_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_in_data_vector;
output [FIFO_COUNT - 1 :0] master_fifo_in_valid_vector;
input [FIFO_COUNT - 1 :0] master_fifo_in_ready_vector;

input [HUB_FIFO_WIDTH - 1 :0] sc_fifo_out_data;
input sc_fifo_out_valid;
output sc_fifo_out_ready;
output [HUB_FIFO_WIDTH - 1 :0] sc_fifo_in_data;
output sc_fifo_in_valid;
input sc_fifo_in_ready;

output reg [HUB_FIFO_PHYSICAL_WIDTH*(FPGA_NEIGHBORS + 1) - 1 :0] final_fifo_out_data;
output [FPGA_NEIGHBORS : 0] final_fifo_out_valid;
input [FPGA_NEIGHBORS : 0] final_fifo_out_ready;
input [HUB_FIFO_PHYSICAL_WIDTH*(FPGA_NEIGHBORS + 1) - 1 :0] final_fifo_in_data;
input [FPGA_NEIGHBORS : 0] final_fifo_in_valid;
output [FPGA_NEIGHBORS : 0] final_fifo_in_ready;

output has_flying_messages;

input [FPGAID_WIDTH*FPGA_NEIGHBORS-1 : 0] fpga_neighbor_array;

reg [HUB_FIFO_PHYSICAL_WIDTH*(FPGA_NEIGHBORS + 1) - 1 :0] final_fifo_out_data_internal;
wire [FPGA_NEIGHBORS : 0] final_fifo_out_valid_internal;
wire [FPGA_NEIGHBORS : 0] final_fifo_out_is_full_internal;

wire [HUB_FIFO_PHYSICAL_WIDTH*(FPGA_NEIGHBORS + 1) - 1 :0] final_fifo_in_data_internal;
reg [FPGA_NEIGHBORS : 0] final_fifo_in_ready_internal;
wire [FPGA_NEIGHBORS : 0] final_fifo_in_empty_internal;

wire [FPGA_NEIGHBORS : 0] final_fifo_out_empty;
assign final_fifo_out_valid = ~final_fifo_out_empty;

wire [FPGA_NEIGHBORS : 0] final_fifo_in_full;
assign final_fifo_in_ready = ~final_fifo_in_full;

reg has_flying_messages_reg;

always@(posedge clk) begin
    if (reset) begin
        has_flying_messages_reg <= 0;
    end else begin
        has_flying_messages_reg <= sc_fifo_out_valid || (final_fifo_out_valid != 0) || (master_fifo_out_valid_vector != 0) || (final_fifo_in_valid != 0) || sc_fifo_in_valid || (master_fifo_in_valid_vector != 0) || temporal_out_valid || (final_fifo_out_valid_internal != 0) || temporal_in_valid || narrow_fifo_in_valid;
    end
end

assign has_flying_messages = has_flying_messages_reg;

genvar i;

generate
    for(i=0;i <= FPGA_NEIGHBORS; i = i+1) begin: fo
        fifo_fwft #(.DEPTH(16), .WIDTH(HUB_FIFO_PHYSICAL_WIDTH)) out_fifo 
            (
            .clk(clk),
            .srst(reset),
            .wr_en(final_fifo_out_valid_internal[i]),
            .din(final_fifo_out_data_internal[(i+1)*HUB_FIFO_PHYSICAL_WIDTH - 1 : i*HUB_FIFO_PHYSICAL_WIDTH]),
            .full(final_fifo_out_is_full_internal[i]),
            .empty(final_fifo_out_empty[i]),
            .dout(final_fifo_out_data[(i+1)*HUB_FIFO_PHYSICAL_WIDTH - 1 : i*HUB_FIFO_PHYSICAL_WIDTH]),
            .rd_en(final_fifo_out_ready[i])
        );
    end
endgenerate

localparam TRUE_FIFO_COUNT = FIFO_COUNT + 1; //+1 for the stage controller

wire [TRUE_FIFO_COUNT*HUB_FIFO_WIDTH - 1 : 0] combined_fifo_out_data_vector;
wire [TRUE_FIFO_COUNT - 1 : 0] combined_fifo_out_valid_vector;
wire [TRUE_FIFO_COUNT - 1 : 0] combined_fifo_out_ready_vector;

assign combined_fifo_out_data_vector [FIFO_COUNT*HUB_FIFO_WIDTH - 1 : 0] = master_fifo_out_data_vector;
assign combined_fifo_out_data_vector [TRUE_FIFO_COUNT*HUB_FIFO_WIDTH - 1 : FIFO_COUNT*HUB_FIFO_WIDTH] = sc_fifo_out_data;
assign combined_fifo_out_valid_vector[FIFO_COUNT - 1 : 0]  = master_fifo_out_valid_vector;
assign combined_fifo_out_valid_vector[FIFO_COUNT]  = sc_fifo_out_valid;
assign master_fifo_out_ready_vector = combined_fifo_out_ready_vector[FIFO_COUNT - 1 : 0];
assign sc_fifo_out_ready = combined_fifo_out_ready_vector[FIFO_COUNT];

wire [HUB_FIFO_WIDTH - 1:0] temporal_out_final_message;
wire gathered_message_valid;

wire all_ser_fifos_free;
wire [FPGA_NEIGHBORS : 0] temporal_out_fifo_ready;
assign all_ser_fifos_free = (temporal_out_fifo_ready == {(FPGA_NEIGHBORS + 1){1'b1}} ? 1'b1 : 1'b0);

many_to_one_mux #(
    .HUB_FIFO_WIDTH(HUB_FIFO_WIDTH),
    .TRUE_FIFO_COUNT(TRUE_FIFO_COUNT)
) output_side (
    .combined_fifo_out_data_vector(combined_fifo_out_data_vector),
    .combined_fifo_out_valid_vector(combined_fifo_out_valid_vector),
    .combined_fifo_out_ready_vector(combined_fifo_out_ready_vector),
    .elected_valid(gathered_message_valid),
    .elected_message(temporal_out_final_message),
    .next_stage_ready(all_ser_fifos_free)
);

wire [FPGA_NEIGHBORS : 0]  temporal_out_valid;

//i=0 in the array has directions for i=1 FIFO and likewise
generate
    for(i=1;i <= FPGA_NEIGHBORS; i = i+1) begin: temp_valid
        assign temporal_out_valid[i] = gathered_message_valid && (temporal_out_final_message[HUB_FIFO_WIDTH-1 : HUB_FIFO_WIDTH - FPGAID_WIDTH] == fpga_neighbor_array[(i)*FPGAID_WIDTH - 1 : (i-1)*FPGAID_WIDTH]);
    end
endgenerate

assign temporal_out_valid[0] = gathered_message_valid && (temporal_out_valid[FPGA_NEIGHBORS : 1] ==32'b0);

wire [FPGA_NEIGHBORS : 0] narrow_out_fifo_ready;
assign narrow_out_fifo_ready = ~final_fifo_out_is_full_internal;

generate
    for(i=0;i <= FPGA_NEIGHBORS; i = i+1) begin: ser_gen
        serializer #(.HUB_FIFO_WIDTH(HUB_FIFO_WIDTH), .HUB_FIFO_PHYSICAL_WIDTH(HUB_FIFO_PHYSICAL_WIDTH)) ser
        (
            .clk(clk),
            .reset(reset),
            .wide_fifo_data(temporal_out_final_message),
            .wide_fifo_valid(temporal_out_valid[i] && all_ser_fifos_free),
            .wide_fifo_ready(temporal_out_fifo_ready[i]),
            .narrow_fifo_valid(final_fifo_out_valid_internal[i]),
            .narrow_fifo_ready(narrow_out_fifo_ready[i]),
            .narrow_fifo_data(final_fifo_out_data_internal[(i+1)*HUB_FIFO_PHYSICAL_WIDTH - 1 : i*HUB_FIFO_PHYSICAL_WIDTH])
        );
    end
endgenerate


/*---------------------------- receiver side----------------------------------------*/

generate
    for(i=0;i <= FPGA_NEIGHBORS; i = i+1) begin: input_final
        fifo_fwft #(.DEPTH(16), .WIDTH(HUB_FIFO_PHYSICAL_WIDTH)) in_fifo 
            (
            .clk(clk),
            .srst(reset),
            .wr_en(final_fifo_in_valid[i]),
            .din(final_fifo_in_data[(i+1)*HUB_FIFO_PHYSICAL_WIDTH - 1 : i*HUB_FIFO_PHYSICAL_WIDTH]),
            .full(final_fifo_in_full[i]),
            .empty(final_fifo_in_empty_internal[i]),
            .dout(final_fifo_in_data_internal[(i+1)*HUB_FIFO_PHYSICAL_WIDTH - 1 : i*HUB_FIFO_PHYSICAL_WIDTH]),
            .rd_en(final_fifo_in_ready_internal[i])
        );
    end
endgenerate

wire [FPGA_NEIGHBORS : 0] narrow_fifo_in_valid;
assign narrow_fifo_in_valid = ~final_fifo_in_empty_internal;

wire [HUB_FIFO_WIDTH*(FPGA_NEIGHBORS + 1)-1 : 0] temporal_in_fifo;
wire [FPGA_NEIGHBORS : 0] temporal_in_ready;
wire [FPGA_NEIGHBORS : 0] temporal_in_valid;

wire [HUB_FIFO_WIDTH -1 : 0] temporal_in_fifo_selected;
wire temporal_in_ready_selected;
wire temporal_in_valid_selected;

generate
    for(i=0;i <= FPGA_NEIGHBORS; i = i+1) begin: des_gen
        deserializer #(.HUB_FIFO_WIDTH(HUB_FIFO_WIDTH), .HUB_FIFO_PHYSICAL_WIDTH(HUB_FIFO_PHYSICAL_WIDTH)) des
        (
            .clk(clk),
            .reset(reset),
            .wide_fifo_data(temporal_in_fifo[(i+1)*HUB_FIFO_WIDTH - 1 : i*HUB_FIFO_WIDTH]),
            .wide_fifo_valid(temporal_in_valid[i]),
            .wide_fifo_ready(temporal_in_ready[i]),
            .narrow_fifo_valid(narrow_fifo_in_valid[i]),
            .narrow_fifo_ready(final_fifo_in_ready_internal[i]),
            .narrow_fifo_data(final_fifo_in_data_internal[(i+1)*HUB_FIFO_PHYSICAL_WIDTH - 1 : i*HUB_FIFO_PHYSICAL_WIDTH])
        );
    end
endgenerate

many_to_one_mux #(
    .HUB_FIFO_WIDTH(HUB_FIFO_WIDTH),
    .TRUE_FIFO_COUNT(FPGA_NEIGHBORS + 1)
) input_side (
    .combined_fifo_out_data_vector(temporal_in_fifo),
    .combined_fifo_out_valid_vector(temporal_in_valid),
    .combined_fifo_out_ready_vector(temporal_in_ready),
    .elected_valid(temporal_in_valid_selected),
    .elected_message(temporal_in_fifo_selected),
    .next_stage_ready(temporal_in_ready_selected)
);

wire [TRUE_FIFO_COUNT*HUB_FIFO_WIDTH - 1 : 0] combined_fifo_in_data_vector;
wire [TRUE_FIFO_COUNT - 1 : 0] combined_fifo_in_valid_vector;
wire [TRUE_FIFO_COUNT - 1 : 0] combined_fifo_in_ready_vector;

assign master_fifo_in_data_vector = combined_fifo_in_data_vector [FIFO_COUNT*HUB_FIFO_WIDTH - 1 : 0];
assign sc_fifo_in_data = combined_fifo_in_data_vector [TRUE_FIFO_COUNT*HUB_FIFO_WIDTH - 1 : FIFO_COUNT*HUB_FIFO_WIDTH];
assign master_fifo_in_valid_vector = combined_fifo_in_valid_vector[FIFO_COUNT - 1 : 0];
assign sc_fifo_in_valid = combined_fifo_in_valid_vector[FIFO_COUNT];
assign combined_fifo_in_ready_vector[FIFO_COUNT - 1 : 0] = master_fifo_in_ready_vector;
assign combined_fifo_in_ready_vector[FIFO_COUNT] = sc_fifo_in_ready;

`define master_fifo_in_data(i) combined_fifo_in_data_vector[((i+1) * HUB_FIFO_WIDTH) - 1 : (i * HUB_FIFO_WIDTH)]
`define master_fifo_in_valid(i) combined_fifo_in_valid_vector[i]
`define master_fifo_in_ready(i) combined_fifo_in_ready_vector[i]
`define destination_index temporal_in_fifo_selected[HUB_FIFO_WIDTH - FPGAID_WIDTH - 1 : HUB_FIFO_WIDTH - FPGAID_WIDTH - FIFO_IDWIDTH]

generate
    for (i=0; i < TRUE_FIFO_COUNT; i=i+1) begin: writing_incoming_data
        assign `master_fifo_in_data (i) = temporal_in_fifo_selected[HUB_FIFO_WIDTH - 1 :0];
    end
endgenerate

generate
    for (i=0; i < FIFO_COUNT; i=i+1) begin: making_correct_incoming_channel_correct
//        if(i < FIFO_COUNT) begin:
            assign `master_fifo_in_valid(i) = 
                ((i == `destination_index) && temporal_in_valid_selected);
        //end else begin:
        //    assign `master_fifo_in_valid(i) = 
        //        ((`destination_index == {FIFO_IDWIDTH{1'b1}}) && !final_fifo_in_empty_internal);
        //end
    end
endgenerate

assign `master_fifo_in_valid(FIFO_COUNT) = ((`destination_index == {FIFO_IDWIDTH{1'b1}}) && temporal_in_valid_selected);


`define message_read (combined_fifo_in_ready_vector[`destination_index])
assign temporal_in_ready_selected = (`destination_index == {FIFO_IDWIDTH{1'b1}}) ?  combined_fifo_in_ready_vector[FIFO_COUNT] : `message_read;

endmodule