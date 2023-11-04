`timescale 1ns / 1ps

// This PE stores the data of the missing vertex to help with the decoding process at the boundary vertex

module support_processing_unit #(
    parameter ADDRESS_WIDTH = 6,
    parameter NUM_CONTEXTS = 2
) (
    clk,
    reset,
    global_stage,

    output_data,
    input_data,
    local_context_switch
);

`include "../../parameters/parameters.sv"

localparam EXPOSED_DATA_SIZE = ADDRESS_WIDTH + 1 + 1 + 1;

input clk;
input reset;

input [STAGE_WIDTH-1:0] global_stage;

input [EXPOSED_DATA_SIZE-1:0] input_data;
output reg [EXPOSED_DATA_SIZE-1:0] output_data;

input local_context_switch;


reg [STAGE_WIDTH - 1 : 0] stage;
reg [STAGE_WIDTH - 1 : 0] last_stage;


// stage is always equal to global_stage
always@(posedge clk) begin
    if(reset) begin
        stage <= STAGE_IDLE;
        last_stage <= STAGE_IDLE;
    end else begin
        stage <= global_stage;
        last_stage <= stage;
    end
end

reg write_to_mem;
localparam RAM_LOG_DEPTH = $clog2(NUM_CONTEXTS);
reg [RAM_LOG_DEPTH-1:0] mem_rw_address;
localparam RAM_WIDTH = ADDRESS_WIDTH + 6 + 3;
wire [RAM_WIDTH - 1 :0] data_from_memory;
wire [RAM_WIDTH - 1:0] data_to_memory;

assign data_to_memory = input_data;

rams_sp_nc #(
    .DEPTH(NUM_CONTEXTS),
    .WIDTH(RAM_WIDTH)
) PE_mem (
    .clk(clk),            // Clock input
    //.rsta(reset),            // Reset input (active high)
    .en(1'b1),              // Enable input
    .we(write_to_mem),            // Write Enable input (0 to 0)
    .addr(mem_rw_address),     // Address input (3 downto 0)
    .di(data_to_memory),      // Data input (35 downto 0)
    .dout(data_from_memory)   // Data output (35 downto 0)
);

//logic to calulate the address to write to memory
always@(posedge clk) begin
    if(reset) begin
        mem_rw_address <= 0;
    end else begin
        if (stage == STAGE_WRITE_TO_MEM && local_context_switch == 1'b0) begin
            if(mem_rw_address < NUM_CONTEXTS -1) begin
                mem_rw_address <= mem_rw_address + 1;
            end else begin
                mem_rw_address <= 0;
            end
        end
    end
end

reg last_context_switch_is_local;
always@(posedge clk) begin
    if(reset) begin
        last_context_switch_is_local <= 0;
    end else begin
        if (stage == STAGE_WRITE_TO_MEM) begin
            last_context_switch_is_local <= local_context_switch;
        end
    end
end

always@(*) begin
    if(reset) begin
        write_to_mem = 0;
    end else begin
        if (stage == STAGE_WRITE_TO_MEM && local_context_switch == 1'b0) begin
            write_to_mem = 1;
        end else begin
            write_to_mem = 0;
        end
    end
end

// logic to check whether last context switch was a local context switch


always@(posedge clk) begin
    if(reset) begin
        output_data <= 0;
    end else begin
        if(stage == STAGE_WRITE_TO_MEM && local_context_switch) begin
            output_data <= input_data;
        end else if(stage == STAGE_READ_FROM_MEM && !last_context_switch_is_local) begin
            output_data <= data_from_memory;
        end
    end
end
            

endmodule