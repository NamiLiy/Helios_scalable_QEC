module root_controller #(
    parameter ITERATION_COUNTER_WIDTH = 8,  // counts to 255 iterations
    parameter MAXIMUM_DELAY = 2, // This has use only in multi-fpga mode
    parameter CTRL_FIFO_WIDTH = 64,
    parameter NUM_CHILDREN = 4
) (
    clk,
    reset,

    data_from_cpu,
    valid_from_cpu,
    ready_from_cpu,

    data_to_cpu,
    valid_to_cpu,
    ready_to_cpu,

    data_to_fpgas,
    valid_to_fpgas,
    ready_to_fpgas,

    data_from_fpgas,
    valid_from_fpgas,
    ready_from_fpgas,

    router_busy
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

localparam CTRL_MSG_MSB = 47;


input clk;
input reset;

input [CTRL_FIFO_WIDTH-1:0] data_from_cpu;
input valid_from_cpu;
output reg ready_from_cpu;

output reg [CTRL_FIFO_WIDTH-1:0] data_to_cpu;
output reg valid_to_cpu;
input ready_to_cpu;

output reg [CTRL_FIFO_WIDTH-1:0] data_to_fpgas;
output reg valid_to_fpgas;
input ready_to_fpgas;

input [CTRL_FIFO_WIDTH-1:0] data_from_fpgas;
input valid_from_fpgas;
output reg ready_from_fpgas;

input router_busy;

reg [STAGE_WIDTH-1:0] global_stage;

reg result_valid;
reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
reg [31:0] cycle_counter;

reg busy;
reg odd_clusters;

reg multi_fpga_mode;
reg measurement_fusion_on;

reg cycle_counter_on;
reg cycle_counter_reset;
reg [$clog2(NUM_CHILDREN + 1)-1:0] return_msg_count;

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

localparam DELAY_COUNTER_WIDTH = 8;
reg [DELAY_COUNTER_WIDTH-1:0] delay_counter;
reg merge_incomplete;
reg prelim_busy;

always@(posedge clk) begin
    if (reset) begin
        prelim_busy <= 0;
    end else begin
        prelim_busy <= router_busy;
    end
end

always @(posedge clk) begin
    if (reset) begin
        global_stage <= STAGE_IDLE;
        delay_counter <= 0;
        cycle_counter_on <= 0;
        cycle_counter_reset <= 0;
        multi_fpga_mode <= 0;
        measurement_fusion_on <= 0;
    end else begin
        case (global_stage)
            STAGE_IDLE: begin // 0
                if (valid_from_cpu && ready_to_fpgas) begin
                    if(data_from_cpu [CTRL_MSG_MSB : CTRL_MSG_MSB - 7] == START_DECODING_MSG) begin
                        multi_fpga_mode <= data_from_cpu [0];
                        measurement_fusion_on <= data_from_cpu [1];
                    end else if(data_from_cpu [CTRL_MSG_MSB : CTRL_MSG_MSB - 7] == MEASUREMENT_DATA_HEADER) begin
                        if(multi_fpga_mode) begin
                            global_stage <= STAGE_MEASUREMENT_LOADING; // This is to wait reasonable time to load the data
                        end else if(measurement_fusion_on) begin
                            if(data_from_cpu[1:0] == 2'b01) begin
                                global_stage <= STAGE_RESULT_VALID; // The root controller does nothing in single FPGA mode
                            end
                        end else begin
                            global_stage <= STAGE_RESULT_VALID; // The root controller does nothing in single FPGA mode
                        end
                        result_valid <= 0;
                    end
                end
                iteration_counter <= 0;
                cycle_counter_on <= 0;
                cycle_counter_reset <= 1;
                delay_counter <= 0;
                return_msg_count <= 0;
                merge_incomplete <= 0;
                odd_clusters <= 0;
            end

            STAGE_MEASUREMENT_LOADING: begin
                // We come to this state only in multi-FPGA mode
                if(delay_counter < 200) begin
                    delay_counter <= delay_counter + 1;
                end else begin
                    delay_counter <= 0;
                    global_stage <= STAGE_GROW;
                end
            end

            STAGE_GROW: begin //2
                // We come to this state only in multi-FPGA mode
                global_stage <= STAGE_MERGE;
                cycle_counter_reset <= 0;
                cycle_counter_on <= 1;
                iteration_counter <= iteration_counter + 1;
            end

            STAGE_MERGE: begin //3
                // We come to this state only in multi-FPGA mode
                if (delay_counter >= MAXIMUM_DELAY) begin
                    if(!prelim_busy) begin // Ask nodes for busy states
                        global_stage <= STAGE_WAIT_TILL_NODE_RESULTS; 
                    end
                    delay_counter <= 0;
                end else begin
                    delay_counter <= delay_counter + 1;
                end
            end

            STAGE_WAIT_TILL_NODE_RESULTS: begin //4
                // We come to this state only in multi-FPGA mode
                if (valid_from_fpgas && ready_from_fpgas) begin
                    if(data_from_fpgas [CTRL_MSG_MSB : CTRL_MSG_MSB - 7] == NODE_RESULT_MSG) begin
                        return_msg_count <= return_msg_count + 1;
                        if(data_from_fpgas [0] == 1'b1) begin
                            merge_incomplete <= 1'b1;
                        end else begin
                            if(data_from_fpgas [1] == 1'b1) begin
                                odd_clusters <= 1'b1;
                            end
                        end
                    end
                end
                if(return_msg_count == NUM_CHILDREN) begin
                    if(merge_incomplete) begin
                        global_stage <= STAGE_MERGE;
                    end else begin
                        if (odd_clusters) begin
                            global_stage <= STAGE_GROW;
                        end else begin
                            global_stage <= STAGE_PEELING;
                        end
                    end
                    return_msg_count <= 0;
                    merge_incomplete <= 0;
                    odd_clusters <= 0;
                end
                
            end           

            STAGE_PEELING: begin //4
                // We come to this state only in multi-FPGA mode
                global_stage <= STAGE_RESULT_VALID;
                cycle_counter_on <= 0;
            end

            STAGE_RESULT_VALID: begin //5
                if(multi_fpga_mode == 1'b0) begin
                    if(valid_from_fpgas) begin
                        return_msg_count <= return_msg_count + 1;
                    end
                    if(return_msg_count == NUM_CHILDREN) begin
                        global_stage <= STAGE_IDLE;
                        return_msg_count <= 0;
                    end
                end else begin
                    if(delay_counter >= MAXIMUM_DELAY) begin
                        global_stage <= STAGE_IDLE;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end
            end
            
            default: begin
                global_stage <= STAGE_IDLE;
            end
        endcase
    end
end

always@(*) begin
    ready_from_cpu = 1'b0;
    data_to_cpu = 64'b0;
    valid_to_cpu = 1'b0;

    ready_from_fpgas = 1'b0;
    data_to_fpgas = 64'b0;
    valid_to_fpgas = 1'b0;

    case(global_stage)
        STAGE_IDLE: begin
            ready_from_cpu = ready_to_fpgas;
            data_to_fpgas = data_from_cpu;
            valid_to_fpgas = valid_from_cpu;
        end

        STAGE_GROW: begin
            data_to_fpgas = {8'hff, 8'hff, MOVE_TO_STAGE, 8'b0, 8'b0, 8'b0, 8'b0, 8'b1};
            valid_to_fpgas = 1'b1;
        end

        STAGE_MERGE: begin
            if (delay_counter >= MAXIMUM_DELAY) begin
                if(!prelim_busy) begin // Ask nodes for busy states
                    data_to_fpgas = {8'hff, 8'hff, SEND_ODD_AND_BUSY, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0};
                    valid_to_fpgas = 1'b1;
                end
            end
        end

        STAGE_WAIT_TILL_NODE_RESULTS: begin
            ready_from_fpgas = 1'b1;
        end

        STAGE_PEELING: begin
            data_to_fpgas = {8'hff, 8'hff, MOVE_TO_STAGE, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0};
            valid_to_fpgas = 1'b1;
        end

        STAGE_RESULT_VALID: begin
            if(multi_fpga_mode == 1'b0) begin
                valid_to_cpu = valid_from_fpgas;
                data_to_cpu = data_from_fpgas;
                ready_from_fpgas = ready_to_cpu;
            end else begin
                if(delay_counter >= MAXIMUM_DELAY) begin
                    valid_to_cpu = 1'b1;
                    data_to_cpu [39:24] = cycle_counter;
                    data_to_cpu [47:40] = iteration_counter;
                end 
            end
        end
    endcase
end

endmodule