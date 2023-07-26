module unified_controller #(
    parameter GRID_WIDTH_X = 4,
    parameter GRID_WIDTH_Z = 1,
    parameter GRID_WIDTH_U = 3,
    parameter ITERATION_COUNTER_WIDTH = 8,  // counts to 255 iterations
    parameter MAXIMUM_DELAY = 2
) (
    clk,
    reset,

    input_data,
    input_valid,
    input_ready,

    output_data,
    output_valid,
    output_ready,

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
localparam ADDRESS_WIDTH = X_BIT_WIDTH + Z_BIT_WIDTH + U_BIT_WIDTH;

localparam BYTES_PER_ROUND = ((GRID_WIDTH_X * GRID_WIDTH_Z  + 7) >> 3);
localparam ALIGNED_PU_PER_ROUND = (BYTES_PER_ROUND << 3);

localparam PU_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam PU_COUNT = PU_COUNT_PER_ROUND * GRID_WIDTH_U;

localparam NS_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z;
localparam EW_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z + 1;
localparam UD_ERROR_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam DIAG_NS_ERROR_COUNT_PER_ROUND = ((GRID_WIDTH_X-1) * GRID_WIDTH_Z) - GRID_WIDTH_Z;
localparam DIAG_EW_ERROR_COUNT_PER_ROUND = ((GRID_WIDTH_X-1) * GRID_WIDTH_Z) - (GRID_WIDTH_Z + 1);
localparam DIAG_HOOK_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_U > 3) ? GRID_WIDTH_U-1 : 0;
localparam CORRECTION_COUNT_PER_ROUND = NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND + UD_ERROR_COUNT_PER_ROUND + DIAG_NS_ERROR_COUNT_PER_ROUND + DIAG_EW_ERROR_COUNT_PER_ROUND + DIAG_HOOK_ERROR_COUNT_PER_ROUND;



input clk;
input reset;
output reg [STAGE_WIDTH-1:0] global_stage;
reg [STAGE_WIDTH-1:0] global_stage_previous;

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

reg result_valid;
reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
reg [31:0] cycle_counter;

reg busy;
reg odd_clusters;

always@(posedge clk) begin
    busy <= |busy_PE;
    odd_clusters <= |odd_clusters_PE;
end

always @(posedge clk) begin
    if (reset) begin
        cycle_counter <= 0;
    end else begin
        if (global_stage == STAGE_MEASUREMENT_LOADING) begin
            cycle_counter <= 1;
        end else if (global_stage == STAGE_GROW || global_stage == STAGE_MERGE || global_stage == STAGE_PEELING) begin
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

localparam DELAY_COUNTER_WIDTH = $clog2(MAXIMUM_DELAY + 1);
reg [DELAY_COUNTER_WIDTH-1:0] delay_counter;

reg [15:0] messages_per_round_of_measurement;
reg [15:0] measurement_rounds;

wire [CORRECTION_COUNT_PER_ROUND - 1 : 0] output_fifo_data;
reg output_fifo_valid;
wire output_fifo_ready;

wire [CORRECTION_COUNT_PER_ROUND - 1 : 0] output_fifo_data_d;
wire output_fifo_valid_d;
wire output_fifo_ready_d;

always @(posedge clk) begin
    if (reset) begin
        global_stage <= STAGE_IDLE;
        delay_counter <= 0;
        result_valid <= 0;
    end else begin
        case (global_stage)
            STAGE_IDLE: begin // 0
                if (input_valid && input_ready) begin
                    if(input_data == START_DECODING_MSG) begin
                        global_stage <= STAGE_PARAMETERS_LOADING;
                        delay_counter <= 0;
                        result_valid <= 0;
                    end else if(input_data == MEASUREMENT_DATA_HEADER) begin
                        global_stage <= STAGE_MEASUREMENT_PREPARING;
                        delay_counter <= 0;
                        result_valid <= 0;
                        measurement_rounds <= 0;
                    end
                end 
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
            end

            STAGE_MEASUREMENT_LOADING: begin
                // Currently this is single cycle as only from external buffer happens.
                // In future might need multiple
                if(measurement_rounds < GRID_WIDTH_U) begin
                    global_stage <= STAGE_MEASUREMENT_PREPARING;
                    delay_counter <= 0;
                    result_valid <= 0;
                end else begin
                    global_stage <= STAGE_GROW;
                    delay_counter <= 0;
                    result_valid <= 0;
                end
            end

            STAGE_GROW: begin //2
                global_stage <= STAGE_MERGE;
                delay_counter <= 0;
                measurement_rounds <= 0;
            end

            STAGE_MERGE: begin //3
                if (delay_counter >= MAXIMUM_DELAY) begin
                    if(!busy) begin
                        if(!odd_clusters) begin
                            global_stage <= STAGE_PEELING;
                            delay_counter <= 0;
                        end else begin
                            global_stage <= STAGE_GROW;
                            delay_counter <= 0;
                        end
                    end
                end else begin
                    delay_counter <= delay_counter + 1;
                end
            end           

            STAGE_PEELING: begin //4
                if (delay_counter >= MAXIMUM_DELAY) begin
                    if(!busy) begin
                        global_stage <= STAGE_RESULT_VALID;
                        delay_counter <= 0;
                    end
                end else begin
                    delay_counter <= delay_counter + 1;
                end
            end

            STAGE_RESULT_VALID: begin //5
                measurement_rounds <= measurement_rounds + 1;
                if(measurement_rounds >= GRID_WIDTH_U - 1) begin
                    global_stage <= STAGE_IDLE;
                end
                delay_counter <= 0;
                result_valid <= 1;
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
        if(global_stage == STAGE_IDLE || global_stage == STAGE_MEASUREMENT_PREPARING) begin
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
        if(global_stage == STAGE_RESULT_VALID) begin
            output_fifo_valid = 1;
        end else begin
            output_fifo_valid = 0;
        end
    end
end

assign output_fifo_data = correction;

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
            if(output_message_counter >= ((CORRECTION_COUNT_PER_ROUND + 7)>>3)*GRID_WIDTH_U + 2) begin
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