module unified_controller #(
    parameter GRID_WIDTH_X = 4,
    parameter GRID_WIDTH_Z = 1,
    parameter GRID_WIDTH_U = 3,
    parameter ITERATION_COUNTER_WIDTH = 8,  // counts to 255 iterations
    parameter MAXIMUM_DELAY = 2,
    parameter NUM_CONTEXTS = 2,
    parameter CTRL_FIFO_WIDTH = 64,
    parameter NUM_FPGAS = 5
) (
    clk,
    reset,

    input_data,
    input_valid,
    input_ready,

    output_data,
    output_valid,
    output_ready,

    input_ctrl_rx_data,
    input_ctrl_rx_valid,
    input_ctrl_rx_ready,

    output_ctrl_tx_data,
    output_ctrl_tx_valid,
    output_ctrl_tx_ready,

    busy_PE, 
    odd_clusters_PE,
    measurements,
    correction,
    global_stage
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

localparam X_BIT_WIDTH = $clog2(GRID_WIDTH_X);
localparam Z_BIT_WIDTH = $clog2(GRID_WIDTH_Z);
localparam U_BIT_WIDTH = $clog2(GRID_WIDTH_U);
localparam FPGA_BIT_WIDTH = $clog2(NUM_FPGAS);
localparam ADDRESS_WIDTH = X_BIT_WIDTH + Z_BIT_WIDTH + U_BIT_WIDTH + FPGA_BIT_WIDTH;

localparam BYTES_PER_ROUND = ((GRID_WIDTH_X * GRID_WIDTH_Z  + 7) >> 3);
localparam ALIGNED_PU_PER_ROUND = (BYTES_PER_ROUND << 3);

localparam PU_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam PHYSICAL_GRID_WIDTH_U = (GRID_WIDTH_U % NUM_CONTEXTS == 0) ? 
                                   (GRID_WIDTH_U / NUM_CONTEXTS) : 
                                   (GRID_WIDTH_U / NUM_CONTEXTS + 1);

localparam PU_COUNT = PU_COUNT_PER_ROUND * PHYSICAL_GRID_WIDTH_U;

localparam NS_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z;
localparam EW_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z + 1;
localparam UD_ERROR_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam CORRECTION_COUNT_PER_ROUND = NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND + UD_ERROR_COUNT_PER_ROUND;

localparam BORDER_TOP_MSB = PU_COUNT - 1;
localparam BORDER_TOP_LSB = PU_COUNT_PER_ROUND * (PHYSICAL_GRID_WIDTH_U- 1);
localparam BORDER_BOT_MSB = PU_COUNT_PER_ROUND - 1;
localparam BORDER_BOT_LSB = 0;

localparam CTRL_MSG_MSB = 47;


input clk;
input reset;
output reg [STAGE_WIDTH-1:0] global_stage;
reg [STAGE_WIDTH-1:0] global_stage_previous;
reg [STAGE_WIDTH-1:0] global_stage_d;
reg [STAGE_WIDTH-1:0] global_stage_saved;
input [PU_COUNT - 1 : 0]  odd_clusters_PE;
input [PU_COUNT - 1 : 0]  busy_PE;
output reg [ALIGNED_PU_PER_ROUND-1:0] measurements;
input [CORRECTION_COUNT_PER_ROUND-1:0] correction;

input [7 : 0] input_data;
input input_valid;
output reg input_ready;

output reg [7 : 0] output_data;
output reg output_valid;
input output_ready;

input [CTRL_FIFO_WIDTH-1:0] input_ctrl_rx_data;
input input_ctrl_rx_valid;
output reg input_ctrl_rx_ready;

output reg [CTRL_FIFO_WIDTH-1:0] output_ctrl_tx_data;
output reg output_ctrl_tx_valid;
input output_ctrl_tx_ready;

reg result_valid;
reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
reg [31:0] cycle_counter;

reg busy;
reg odd_clusters;
reg border_busy;
reg [CONTEXT_COUNTER_WIDTH-1:0] current_context;

always@(posedge clk) begin
    busy <= |busy_PE;
    odd_clusters <= |odd_clusters_PE;
    border_busy <= |(busy_PE[BORDER_TOP_MSB : BORDER_TOP_LSB]) || |(busy_PE[BORDER_BOT_MSB : BORDER_BOT_LSB]);
end

// global_stage_d delayed logic
always @(posedge clk) begin
    if (reset) begin
        global_stage_d <= STAGE_IDLE;
    end else begin
        global_stage_d <= global_stage;
    end
end

reg cycle_counter_on;
reg cycle_counter_reset;

always @(posedge clk) begin
    if (reset) begin
        cycle_counter <= 0;
    end else begin
        if(cycle_counter_reset) begin
            cycle_counter <= 2; // to account for propagation time from controller to PEs 
        end else if(cycle_counter_on) begin
            cycle_counter <= cycle_counter + 1;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        global_stage_previous <= STAGE_IDLE;
    end else begin
        global_stage_previous <= global_stage;
    end
end

always @(posedge clk) begin
    if (reset) begin
        iteration_counter <= 0;
    end else begin
        if (global_stage == STAGE_MEASUREMENT_LOADING) begin
            iteration_counter <= 0;
        end else if (global_stage == STAGE_GROW && global_stage_previous != STAGE_GROW) begin
            iteration_counter <= iteration_counter + 1;
        end
    end
end

localparam DELAY_COUNTER_WIDTH = $clog2(MAXIMUM_DELAY + 2);
reg [DELAY_COUNTER_WIDTH-1:0] delay_counter;

reg [15:0] messages_per_round_of_measurement;
reg [15:0] measurement_rounds;

wire [CORRECTION_COUNT_PER_ROUND - 1 : 0] output_fifo_data;
reg output_fifo_valid;
wire output_fifo_ready;

wire [CORRECTION_COUNT_PER_ROUND - 1 : 0] output_fifo_data_d;
wire output_fifo_valid_d;
wire output_fifo_ready_d;

reg [NUM_CONTEXTS -1 : 0] unsynced_merge;
reg [NUM_CONTEXTS -1 : 0] odd_clusters_in_context;
localparam CONTEXT_COUNTER_WIDTH = $clog2(NUM_CONTEXTS + 1);


reg growing_incomplete; //Todo : In an optimized version use this. For the current version I'm not using it.

always @(posedge clk) begin
    if (reset) begin
        global_stage <= STAGE_IDLE;
        delay_counter <= 0;
        result_valid <= 0;
        growing_incomplete <= 0;
        cycle_counter_on <= 0;
        cycle_counter_reset <= 0;
    end else begin
        case (global_stage)
            STAGE_IDLE: begin // 0
                if (input_ctrl_rx_valid && input_ctrl_rx_ready) begin
                    if(input_ctrl_rx_data [CTRL_MSG_MSB : CTRL_MSG_MSB - 7] == START_DECODING_MSG) begin
                        global_stage <= STAGE_PARAMETERS_LOADING;
                        delay_counter <= 0;
                        result_valid <= 0;
                    end else if(input_ctrl_rx_data [CTRL_MSG_MSB : CTRL_MSG_MSB - 7] == MEASUREMENT_DATA_HEADER) begin
                        global_stage <= STAGE_MEASUREMENT_PREPARING;
                        delay_counter <= 0;
                        result_valid <= 0;
                        measurement_rounds <= 0;
                    end
                end
                current_context <= 0; 
                cycle_counter_on <= 0;
                cycle_counter_reset <= 0;
            end

            STAGE_PARAMETERS_LOADING: begin // 6
                global_stage <= STAGE_IDLE;
                messages_per_round_of_measurement <= 0;
                measurement_rounds <= 0;
            end

            STAGE_MEASUREMENT_PREPARING: begin // 7
                if (input_valid && input_ready) begin
                    measurements[ALIGNED_PU_PER_ROUND-1:ALIGNED_PU_PER_ROUND-8] <= input_data;
                    if(ALIGNED_PU_PER_ROUND > 8) begin
                        measurements[ALIGNED_PU_PER_ROUND-9:0] <= measurements[ALIGNED_PU_PER_ROUND-1:8];
                    end
                    messages_per_round_of_measurement <= messages_per_round_of_measurement + 1;
                    if((messages_per_round_of_measurement + 1)*8 >= PU_COUNT_PER_ROUND) begin
                        global_stage <= STAGE_MEASUREMENT_LOADING;
                        delay_counter <= 0;
                        messages_per_round_of_measurement <= 0;
                        measurement_rounds <= measurement_rounds + 1;
                    end else begin
                        messages_per_round_of_measurement <= messages_per_round_of_measurement + 1;
                    end
                end
                unsynced_merge <= 0;
                odd_clusters_in_context <= 0;
            end

            STAGE_MEASUREMENT_LOADING: begin
                // Currently this is single cycle as only from external buffer happens.
                // In future might need multiple
                if(measurement_rounds < PHYSICAL_GRID_WIDTH_U) begin
                    global_stage <= STAGE_MEASUREMENT_PREPARING;
                    delay_counter <= 0;
                    result_valid <= 0;
                end else begin
                    global_stage_saved <= STAGE_MEASUREMENT_LOADING;
                    global_stage <= (NUM_CONTEXTS == 1 ? STAGE_GROW : STAGE_WRITE_TO_MEM);
                    measurement_rounds <= 0;
                    delay_counter <= 0;
                    result_valid <= 0;
                    if(NUM_CONTEXTS == 1) begin
                        cycle_counter_on <= 1;
                        cycle_counter_reset <= 1;
                    end
                end
            end

            STAGE_GROW: begin //2
                global_stage <= (NUM_CONTEXTS == 1 ? STAGE_MERGE : STAGE_WRITE_TO_MEM);
                global_stage_saved <= STAGE_GROW;
                delay_counter <= 0;
                measurement_rounds <= 0;
                growing_incomplete <= 1;
                cycle_counter_reset <= 0;
            end

            STAGE_MERGE: begin //3
                if (delay_counter >= MAXIMUM_DELAY) begin
                    if(!busy) begin
                        delay_counter <= 0;
                        global_stage <= STAGE_WRITE_TO_MEM;
                        if(NUM_CONTEXTS == 1) begin
                            if(|odd_clusters == 1'b0) begin // everybody is even
                                global_stage <= STAGE_PEELING;
                            end else begin // somebody is odd
                                global_stage <= STAGE_GROW;
                            end
                        end else begin
                            global_stage <= STAGE_WRITE_TO_MEM;
                        end
                        global_stage_saved <= STAGE_MERGE;
                        odd_clusters_in_context[current_context] <= odd_clusters;  
                    end
                    if(border_busy) begin
                        unsynced_merge[current_context] <= 1'b1;
                    end
                end else begin
                    delay_counter <= delay_counter + 1;
                    unsynced_merge[current_context] <= 1'b0;
                end

            end           

            STAGE_PEELING: begin //4
                global_stage <= (NUM_CONTEXTS == 1 ? STAGE_RESULT_VALID : STAGE_WRITE_TO_MEM);
                global_stage_saved <= STAGE_PEELING;
            end

            STAGE_RESULT_VALID: begin //5
                measurement_rounds <= measurement_rounds + 1;
                if(measurement_rounds >= PHYSICAL_GRID_WIDTH_U - 1) begin
                    global_stage_saved <= STAGE_RESULT_VALID;
                    if(NUM_CONTEXTS == 1) begin
                        global_stage <= STAGE_IDLE;
                    end else begin
                        global_stage <= STAGE_WRITE_TO_MEM;
                    end
                    measurement_rounds <= 0;
                end
                if(NUM_CONTEXTS == 1) begin
                    cycle_counter_on <= 0;
                end
                delay_counter <= 0;
                result_valid <= 1;
            end

            STAGE_WRITE_TO_MEM: begin //1
                    if(current_context < NUM_CONTEXTS -1 ) begin
                        if(global_stage_saved == STAGE_MERGE) begin
                            // if(growing_incomplete == 1'b1) begin
                            //     global_stage <= STAGE_GROW;
                            // end else begin
                            //     global_stage <= STAGE_MERGE;
                            // end
                            global_stage <= STAGE_MERGE;
                        end else if(global_stage_saved == STAGE_MEASUREMENT_LOADING) begin
                            global_stage <= STAGE_MEASUREMENT_PREPARING;
                        end else if(global_stage_saved == STAGE_PEELING) begin
                            global_stage <= STAGE_PEELING;
                        end else if(global_stage_saved == STAGE_RESULT_VALID) begin
                            global_stage <= STAGE_RESULT_VALID;
                        end else if(global_stage_saved == STAGE_GROW) begin
                            global_stage <= STAGE_GROW;
                        end
                        current_context <= current_context + 1;
                    end else begin
                        current_context <= 0;
                        growing_incomplete <= 0;
                        if(global_stage_saved == STAGE_MERGE) begin
                            if(|unsynced_merge == 1'b0) begin // everybody is synced
                                if(|odd_clusters_in_context == 1'b0) begin // everybody is even
                                    global_stage <= STAGE_PEELING;
                                end else begin // somebody is odd
                                    global_stage <= STAGE_GROW;
                                end
                            end else begin
                                global_stage <= STAGE_MERGE;
                            end
                        end else if(global_stage_saved == STAGE_MEASUREMENT_LOADING) begin
                            global_stage <= STAGE_GROW;
                            cycle_counter_on <= 1;
                            cycle_counter_reset <= 1;
                        end else if(global_stage_saved == STAGE_PEELING) begin
                            global_stage <= STAGE_RESULT_VALID;
                            cycle_counter_on <= 0;
                        end else if(global_stage_saved == STAGE_RESULT_VALID) begin
                            global_stage <= STAGE_IDLE;
                        end else if(global_stage_saved == STAGE_GROW) begin
                            global_stage <= STAGE_MERGE;
                        end
                    end
                // end else begin
                    delay_counter <= 0;
                // end
            end
            
            default: begin
                global_stage <= STAGE_IDLE;
            end
        endcase
    end
end

always@(*) begin
    if (reset) begin
        input_ready = 0;
    end else begin 
        if(global_stage == STAGE_MEASUREMENT_PREPARING) begin
            input_ready = 1;
        end else begin
            input_ready = 0;
        end
    end
end

always@(*) begin
    if (reset) begin
        output_fifo_valid = 0;
    end else begin 
        if(global_stage_d == STAGE_RESULT_VALID) begin
            output_fifo_valid = 1;
        end else begin
            output_fifo_valid = 0;
        end
    end
end

assign output_fifo_data = correction;

always@(*) begin
    if (reset) begin
        input_ctrl_rx_ready = 0;
    end else begin 
        if(global_stage == STAGE_IDLE) begin
            input_ctrl_rx_ready = 1;
        end else begin
            input_ctrl_rx_ready = 0;
        end
    end
end

reg send_results;

always@(posedge clk) begin
    if (reset) begin
        send_results <= 0;
    end else begin
        if(global_stage == STAGE_RESULT_VALID) begin
            send_results <= 1;
        end else begin
            send_results <= 0;
        end
    end
end

always@(*) begin
    output_ctrl_tx_valid = 0;
    output_ctrl_tx_valid = 0;
    output_ctrl_tx_data = 64'h0;
    if(reset) begin
        output_ctrl_tx_valid = 0;
    end else begin
        if(global_stage == STAGE_RESULT_VALID && send_results == 0) begin
            output_ctrl_tx_valid = 1;
            output_ctrl_tx_data [CTRL_MSG_MSB : CTRL_MSG_MSB - 7] = iteration_counter;
            output_ctrl_tx_data [CTRL_MSG_MSB - 8 : CTRL_MSG_MSB - 23] = cycle_counter;
        end else begin
            output_ctrl_tx_valid = 0;
        end
    end
end

// FIFO
fifo_wrapper #(
    .WIDTH(CORRECTION_COUNT_PER_ROUND),
    .DEPTH(32)
) output_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(output_fifo_data),
    .input_valid(output_fifo_valid),
    .input_ready(output_fifo_ready),
    .output_data(output_fifo_data_d),
    .output_valid(output_fifo_valid_d),
    .output_ready(output_fifo_ready_d)
);

wire [7 : 0] output_data_d2;
wire output_valid_d2;
reg output_ready_d2;

serializer #(
    .HUB_FIFO_WIDTH(CORRECTION_COUNT_PER_ROUND),
    .HUB_FIFO_PHYSICAL_WIDTH(8)
) output_serializer (
    .clk(clk),
    .reset(reset),
    .wide_fifo_data(output_fifo_data_d),
    .wide_fifo_valid(output_fifo_valid_d),
    .wide_fifo_ready(output_fifo_ready_d),
    .narrow_fifo_valid(output_valid_d2),
    .narrow_fifo_ready(output_ready_d2),
    .narrow_fifo_data(output_data_d2)
);

reg [31:0] output_message_counter;

always @(posedge clk) begin
    if (reset) begin
        output_message_counter <= 0;
    end else begin
        if(output_valid_d2 && output_ready) begin
            if(output_message_counter >= ((CORRECTION_COUNT_PER_ROUND + 7)>>3)*PHYSICAL_GRID_WIDTH_U*NUM_CONTEXTS + 2) begin
                output_message_counter <= 0;
            end else begin
                output_message_counter <= output_message_counter + 1;
            end
        end
    end
end

always@(*) begin
    case(output_message_counter)
        0: begin
            output_data = iteration_counter;
            output_valid = output_valid_d2;
            output_ready_d2 = 0;
        end
        1: begin
            output_data = cycle_counter[15:8];
            output_valid = output_valid_d2;
            output_ready_d2 = 0;
        end
        2: begin
            output_data = cycle_counter[7:0];
            output_valid = output_valid_d2;
            output_ready_d2 = 0;
        end
        default: begin
            output_data = output_data_d2;
            output_valid = output_valid_d2;
            output_ready_d2 = output_ready;
        end
    endcase
end



endmodule