module many_to_one_mux #(
    parameter HUB_FIFO_WIDTH = 32,
    parameter TRUE_FIFO_COUNT = 3
) (
    input [TRUE_FIFO_COUNT*HUB_FIFO_WIDTH - 1 : 0] combined_fifo_out_data_vector,
    input [TRUE_FIFO_COUNT - 1 : 0] combined_fifo_out_valid_vector,
    output [TRUE_FIFO_COUNT - 1 : 0] combined_fifo_out_ready_vector,
    output elected_valid,
    output [HUB_FIFO_WIDTH - 1 : 0] elected_message,
    input next_stage_ready

);
    
`define master_coming_data(i) combined_fifo_out_data_vector[((i+1) * HUB_FIFO_WIDTH) - 1 : (i * HUB_FIFO_WIDTH)]
`define master_coming_valid(i) combined_fifo_out_valid_vector[i]
`define master_coming_is_taken(i) combined_fifo_out_ready_vector[i]

localparam DIRECT_CHANNEL_DEPTH = $clog2(TRUE_FIFO_COUNT); //2
localparam DIRECT_CHANNEL_EXPAND_COUNT = 2 ** DIRECT_CHANNEL_DEPTH; //4
localparam DIRECT_CHANNEL_ALL_EXPAND_COUNT = 2 * DIRECT_CHANNEL_EXPAND_COUNT - 1;  // the length of tree structured gathering // 7

wire [DIRECT_CHANNEL_ALL_EXPAND_COUNT-1:0] tree_gathering_elected_direct_message_valid;
wire [(HUB_FIFO_WIDTH * DIRECT_CHANNEL_ALL_EXPAND_COUNT)-1:0] tree_gathering_elected_direct_message_data;
`define expanded_elected_output_message_data(i) tree_gathering_elected_direct_message_data[((i+1) * HUB_FIFO_WIDTH) - 1 : (i * HUB_FIFO_WIDTH)]
wire [(HUB_FIFO_WIDTH * DIRECT_CHANNEL_ALL_EXPAND_COUNT)-1:0] tree_gathering_elected_direct_message_index;

`define expanded_elected_output_message_index(i) tree_gathering_elected_direct_message_index[((i+1) * HUB_FIFO_WIDTH) - 1 : (i * HUB_FIFO_WIDTH)]

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

assign elected_message = `gathered_elected_output_message_data;
assign elected_valid = `gathered_elected_output_message_valid;

generate
    for (i=0; i < TRUE_FIFO_COUNT; i=i+1) begin: taking_direct_message
        assign `master_coming_is_taken(i) = 
            ((i == `gathered_elected_output_message_index) && `gathered_elected_output_message_valid  && next_stage_ready);
    end
endgenerate

endmodule