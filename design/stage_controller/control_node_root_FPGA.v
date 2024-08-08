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

reg measurement_fusion_on;

reg cycle_counter_on;
reg cycle_counter_reset;
reg [$clog2(NUM_CHILDREN + 1)-1:0] return_msg_count;

wire [7:0] message_header;
assign message_header = data_from_cpu [MSG_HEADER_MSB : MSG_HEADER_LSB];

wire [7:0] dest;
assign message_dest = data_from_cpu [MSG_DEST_MSB : MSG_DEST_LSB];

// always @(posedge clk) begin
//     if (reset) begin
//         cycle_counter <= 0;
//     end else begin
//         if(cycle_counter_reset) begin
//             cycle_counter <= 2; // to account for propagation time from controller to PEs 
//         end else if(cycle_counter_on) begin
//             cycle_counter <= cycle_counter + 1;
//         end
//     end
// end

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


reg report_all_latencies;

always @(posedge clk) begin
    if (reset) begin
        global_stage <= STAGE_IDLE;
        delay_counter <= 0;
        cycle_counter_on <= 0;
        cycle_counter_reset <= 0;
        measurement_fusion_on <= 0;
    end else begin
        case (global_stage)
            STAGE_IDLE: begin // 0
                if (valid_from_cpu && ready_to_fpgas) begin
                    if(message_dest == 8'h0) begin
                        case(message_header)
                            HEADER_INITIALIZE_DECODING: begin
                                global_stage <= STAGE_MEASUREMENT_LOADING;
                            end

                            HEADER_SET_BOUNDARIES: begin
                                global_stage <= STAGE_SET_BOUNDARIES;
                            end

                            HEADER_DECODE_BLOCK: begin
                                if(data_from_cpu[2] == 1'b1) begin//wait for result
                                    global_stage <= STAGE_WAIT_TILL_NODE_RESULTS;
                                end
                                report_all_latencies <= data_from_cpu[3];
                            end
                        endcase
                    end
                end
                iteration_counter <= 0;
                cycle_counter_on <= 0;
                cycle_counter_reset <= 1;
                delay_counter <= 0;
                return_msg_count <= 0;
            end

            STAGE_SET_BOUNDARIES: begin
                global_stage <= STAGE_IDLE;
            end

            STAGE_WAIT_TILL_NODE_RESULTS: begin //4  
                if (valid_from_fpgas && ready_from_fpgas && return_msg_count < NUM_CHILDREN) begin
                    if(data_from_fpgas [MSG_HEADER_MSB : MSG_HEADER_LSB] == HEADER_RESULT) begin
                        return_msg_count <= return_msg_count + 1;
                        cycle_counter <= data_from_fpgas[15:0];
                    end
                end else if(return_msg_count == NUM_CHILDREN && ready_to_cpu) begin
                    return_msg_count <= 0;
                    global_stage <= STAGE_IDLE;
                end
                
            end           
            
            default: begin
                global_stage <= STAGE_IDLE;
            end
        endcase
    end
end

// From CPU to FPGA path
always@(*) begin
    ready_from_cpu = 1'b0;
    data_to_fpgas = 64'b0;
    valid_to_fpgas = 1'b0;

    case(global_stage)
        STAGE_IDLE: begin
            ready_from_cpu = ready_to_fpgas;
            if (valid_from_cpu && ready_to_fpgas) begin
                if(message_dest == 8'h0) begin
                    case(message_header)
                        //Note that messages indicated to root are converted to broadcast (ff) messages
                        HEADER_INITIALIZE_DECODING: begin
                            data_to_fpgas = {8'hff, data_from_cpu [MSG_HEADER_MSB : 0]};
                            valid_to_fpgas = 1'b1;
                        end
                        HEADER_DECODE_BLOCK: begin
                            data_to_fpgas = {8'hff, data_from_cpu [MSG_HEADER_MSB : 0]};
                            valid_to_fpgas = 1'b1;
                        end

                        default: begin
                            data_to_fpgas = data_from_cpu;
                            valid_to_fpgas = 1'b0;
                        end
                    endcase
                end else begin
                    data_to_fpgas = data_from_cpu;
                    valid_to_fpgas = 1'b0;
                end
            end
        end

        default: begin
            data_to_fpgas = data_from_cpu;
            valid_to_fpgas = 1'b0;
            ready_from_cpu = 1'b0;
        end
    endcase
end

// From FPGA to CPU path
always@(*) begin
    ready_from_fpgas = 1'b0;
    data_to_cpu = 64'b0;
    valid_to_cpu = 1'b0;

    if(report_all_latencies) begin
        data_to_cpu = data_from_fpgas;
        valid_to_cpu = valid_from_fpgas;
        ready_from_fpgas = ready_to_cpu;
    end else begin
        case(global_stage)
            STAGE_WAIT_TILL_NODE_RESULTS: begin
                if(return_msg_count == NUM_CHILDREN) begin
                    data_to_cpu = {8'h0,8'h6,16'h0,16'b0,cycle_counter};
                    valid_to_cpu = 1'b1;
                    ready_from_fpgas = 1'b0;
                end else begin
                    data_to_cpu = data_from_fpgas;
                    valid_to_cpu = 1'b0;
                    ready_from_fpgas = 1'b1;
                end
            end
            default: begin
                data_to_cpu = data_from_fpgas;
                valid_to_cpu = 1'b0;
                ready_from_fpgas = 1'b0;
            end
        endcase
    end
end

endmodule