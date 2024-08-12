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
    do_not_store // Mem store wont happen when this flag is raised
);

`include "parameters.sv"

localparam EXPOSED_DATA_SIZE = ADDRESS_WIDTH + 1 + 1 + 1;

input clk;
input reset;

input [STAGE_WIDTH-1:0] global_stage;

input [EXPOSED_DATA_SIZE-1:0] input_data;
output reg [EXPOSED_DATA_SIZE-1:0] output_data;

input do_not_store;


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
reg [RAM_LOG_DEPTH-1:0] mem_read_address;
reg [RAM_LOG_DEPTH-1:0] mem_write_address;
wire [RAM_LOG_DEPTH-1:0] mem_rw_address;
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
        mem_write_address <= 0;
    end else begin
        if (stage == STAGE_WRITE_TO_MEM) begin
            if(do_not_store == 1'b0) begin
                if(mem_write_address < NUM_CONTEXTS -1) begin
                    mem_write_address <= mem_write_address + 1;
                end else begin
                    mem_write_address <= 0;
                end
            end
        end
    end
end

always@(posedge clk) begin
    if(reset) begin
        mem_read_address <= 1;
    end else begin
        if (stage == STAGE_WRITE_TO_MEM) begin
            if(do_not_store == 1'b0) begin
                if(mem_read_address < NUM_CONTEXTS -1) begin
                    mem_read_address <= mem_read_address + 1;
                end else begin
                    mem_read_address <= 0;
                end
            end
        end
    end
end

assign mem_rw_address = (stage == STAGE_WRITE_TO_MEM) ? mem_write_address : mem_read_address;

always@(*) begin
    if(reset) begin
        write_to_mem = 0;
    end else begin
        if (stage == STAGE_WRITE_TO_MEM && do_not_store == 1'b0) begin
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
        if(stage == STAGE_WRITE_TO_MEM && do_not_store) begin
            output_data <= input_data;
        end else if(stage == STAGE_WRITE_TO_MEM) begin
            output_data <= data_from_memory;
        end
    end
end
            

endmodule