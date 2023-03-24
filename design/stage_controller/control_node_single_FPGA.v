module unified_controller #(
    parameter GRID_WIDTH_X = 3,
    parameter GRID_WIDTH_Z = 2,
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
    global_stage
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

localparam X_BIT_WIDTH = $clog2(GRID_WIDTH_X);
localparam Z_BIT_WIDTH = $clog2(GRID_WIDTH_Z);
localparam U_BIT_WIDTH = $clog2(GRID_WIDTH_U);
localparam ADDRESS_WIDTH = X_BIT_WIDTH + Z_BIT_WIDTH + U_BIT_WIDTH;

localparam PU_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam PU_COUNT = PU_COUNT_PER_ROUND * GRID_WIDTH_U;


input clk;
input reset;
output reg [STAGE_WIDTH-1:0] global_stage;
reg [STAGE_WIDTH-1:0] global_stage_previous;

input [PU_COUNT - 1 : 0]  odd_clusters_PE;
input [PU_COUNT - 1 : 0]  busy_PE;
output reg [PU_COUNT_PER_ROUND-1:0] measurements;

input [7 : 0] input_data;
input input_valid;
output reg input_ready;

output [7 : 0] output_data;
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
        end else if (!result_valid && global_stage != STAGE_IDLE) begin
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
                    for (idx = 0; idx < (N - 8); idx = idx + 8) begin
                        measurements[N-1-idx-7:N-1-idx-14] <= data_array[N-1-idx-15:N-1-idx-22];
                    end
                    measurements[7:0] <= data_in;
                    messages_per_round_of_measurement <= messages_per_round_of_measurement + 8;
                    if(messages_per_round_of_measurement + 8 >= PU_COUNT_PER_ROUND) begin
                        global_stage <= STAGE_MEASUREMENT_LOADING;
                        delay_counter <= 0;
                        messages_per_round_of_measurement <= 0;
                        measurement_rounds <= measurement_rounds + 1;
                    end else begin
                        messages_per_round_of_measurement <= messages_per_round_of_measurement + 8;
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
                global_stage <= STAGE_IDLE;
                result_valid <= 1;
                measurement_rounds <= 0;
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
        if(global_stage == STAGE_IDLE || STAGE_MEASUREMENT_PREPARING) begin
            input_ready = 1;
        end else begin
            input_ready = 0;
        end
    end
end

always@(*) begin
    if (reset) begin
        output_valid = 0;
    end else begin 
        if(result_valid) begin
            output_valid = 1;
        end else begin
            output_valid = 0;
        end
    end
end

endmodule