module parent_controller #(
    parameter CODE_DISTANCE_X = 3,
    parameter CODE_DISTANCE_Z = 2,
    parameter ITERATION_COUNTER_WIDTH = 8,  // counts to 255 iterations
    parameter MAXIMUM_INITIAL_DELAY = 10,
    parameter MAXIMUM_BUSY_DELAY = 7,
    parameter CHILD_COUNT = 2
) (
    clk,
    reset,
    new_round_start,

    busy_child, 
    odd_clusters_child,
    global_stage,

    result_valid,
    iteration_counter, 
    cycle_counter,

    decoding_start,
    next_iteration
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PER_DIM_BIT_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = PER_DIM_BIT_WIDTH * 3;

localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;

input clk;
input reset;
output reg [STAGE_WIDTH-1:0] global_stage;
reg [STAGE_WIDTH-1:0] global_stage_previous;

input [CHILD_COUNT - 1 : 0]  busy_child;
input [CHILD_COUNT - 1 : 0]  odd_clusters_child;
input new_round_start;

output reg result_valid;
output reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
output reg [31:0] cycle_counter;

output reg decoding_start;
output reg next_iteration;


reg [MAXIMUM_BUSY_DELAY-1:0] busy;
reg odd_clusters;

always@(posedge clk) begin
    busy[0] <= |busy_child;
    busy[MAXIMUM_BUSY_DELAY-1:1] <= busy[MAXIMUM_BUSY_DELAY-2:0];
    odd_clusters <= |odd_clusters_child;
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

always @(posedge clk) begin
    if (reset) begin
        global_stage <= STAGE_IDLE;
        delay_counter <= 0;
        result_valid <= 0;
        decoding_start <= 0;
        next_iteration <= 0;
    end else begin
        case (global_stage)
            STAGE_IDLE: begin // 0
                if (new_round_start) begin
                    global_stage <= STAGE_MEASUREMENT_LOADING;
                    delay_counter <= 0;
                    result_valid <= 0;
                    decoding_start <= 1;
                end
                next_iteration <= 0; 
                // else begin
                //     result_valid <= 1;
                // end
            end

            STAGE_MEASUREMENT_LOADING: begin
                // Currently this is single cycle as only from external buffer happens.
                // In future might need multiple
                global_stage <= STAGE_GROW;
                delay_counter <= 0;
                result_valid <= 0; // for safety
            end

            STAGE_GROW: begin //2
                global_stage <= STAGE_MERGE;
                delay_counter <= 0;
            end

            STAGE_MERGE: begin //3
                if (delay_counter >= MAXIMUM_INITIAL_DELAY) begin
                    if(!busy) begin
                        if(!odd_clusters) begin
                            global_stage <= STAGE_PEELING;
                            delay_counter <= 0;
                            decoding_start <= 0;
                        end else begin
                            global_stage <= STAGE_GROW;
                            delay_counter <= 0;
                            next_iteration <= !next_iteration;
                        end
                    end
                end else begin
                    delay_counter <= delay_counter + 1;
                end
            end           

            STAGE_PEELING: begin //4
                if (delay_counter >= MAXIMUM_INITIAL_DELAY) begin
                    if(!busy) begin
                        global_stage <= STAGE_RESULT_VALID;
                        delay_counter <= 0;
                        next_iteration <= 1;
                    end
                end else begin
                    delay_counter <= delay_counter + 1;
                    next_iteration <= 0;
                end
            end

            STAGE_RESULT_VALID: begin //5
                global_stage <= STAGE_IDLE;
                result_valid <= 1;
            end


            
            default: begin
                global_stage <= STAGE_IDLE;
            end
        endcase
    end
end

endmodule