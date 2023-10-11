module neighbor_link_internal #(
    parameter ADDRESS_WIDTH = 6,
    parameter MAX_WEIGHT = 2,
    parameter NUM_CONTEXTS = 2
    // parameter WEIGHT = 2,
    // parameter BOUNDARY_CONDITION = 0, //0 : No boundary 1: A boundary 2: Non existant edge 3: Connected to a FIFO
    // parameter ADDRESS_A = 0,
    // parameter ADDRESS_B = 0,
    // parameter HEADER_ID = 0,
    // parameter HEADER_WIDTH = 2
) (
    clk,
    reset,
    global_stage,

    fully_grown,

    a_increase,
    b_increase,
    is_boundary,

    a_input_data,
    b_input_data,
    a_output_data,
    b_output_data,

    a_is_error_in,
    b_is_error_in,
    is_error,

    weight_in,
    boundary_condition_in,
    is_error_systolic_in,

    weight_out,
    boundary_condition_out,
    local_context_switch
);

`include "../../parameters/parameters.sv"

localparam LINK_BIT_WIDTH = $clog2(MAX_WEIGHT + 1);
localparam EXPOSED_DATA_SIZE = ADDRESS_WIDTH + 1 + 1 + 1 + 1 + 3;

input clk;
input reset;
input [STAGE_WIDTH-1:0] global_stage;

output fully_grown;
input a_increase;
input b_increase;

output is_boundary;

input a_is_error_in;
input b_is_error_in;
output reg is_error;

input [EXPOSED_DATA_SIZE-1:0] a_input_data;
input [EXPOSED_DATA_SIZE-1:0] b_input_data;
output [EXPOSED_DATA_SIZE-1:0] a_output_data;
output [EXPOSED_DATA_SIZE-1:0] b_output_data;

input [LINK_BIT_WIDTH-1:0] weight_in;
input [1:0] boundary_condition_in;
input is_error_systolic_in;
input local_context_switch;

output reg [LINK_BIT_WIDTH-1:0] weight_out;
output reg [1:0] boundary_condition_out;

reg [LINK_BIT_WIDTH-1 : 0] growth;
reg [STAGE_WIDTH-1:0] stage;
reg [STAGE_WIDTH-1:0] last_stage;

wire [1:0] growth_mem;
wire [1:0] boundary_condition_mem;
wire is_error_mem;



`define MIN(a, b) (((a) < (b)) ? (a) : (b))

localparam GROWTH_CALC_WIDTH = $clog2(MAX_WEIGHT + 3);
reg [GROWTH_CALC_WIDTH-1:0] growth_new;

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

always@(*) begin
    if (boundary_condition_out == 0)  begin // No boundary default case 
        growth_new = growth + a_increase + b_increase;
    end else if (boundary_condition_out == 1) begin // edge touching a boundary
        growth_new = growth + a_increase;
    end else begin // Non existant edge
        growth_new = 0;
    end
    if (growth_new > weight_out) begin
        growth_new = weight_out;
    end
end


always@(posedge clk) begin
    if(reset) begin
        growth <= 0;
    end else begin
        if(stage == STAGE_MEASUREMENT_LOADING) begin
                growth <= 0;
        end else if(stage == STAGE_READ_FROM_MEM) begin
            growth <= growth_mem;
        end else begin
            growth <= growth_new;
        end 
    end
end

always@(posedge clk) begin
    if(reset) begin
        is_error <= 0;
    end else if(stage == STAGE_READ_FROM_MEM) begin
        is_error <= is_error_mem;
    end else begin
        if (boundary_condition_out == 0)  begin // No boundary default case 
            if(stage == STAGE_MEASUREMENT_LOADING) begin
                is_error <= 0;
            end else if(stage == STAGE_RESULT_VALID) begin
                is_error <= is_error_systolic_in;
            end else begin
                is_error <= a_is_error_in | b_is_error_in;
            end
        end else if (boundary_condition_out == 1) begin // edge touching a boundary
            if(stage == STAGE_MEASUREMENT_LOADING) begin
                is_error <= 0;
            end else if(stage == STAGE_RESULT_VALID) begin
                is_error <= is_error_systolic_in;
            end else begin
                is_error <= a_is_error_in;
            end
        end else begin // Non existant edge
            is_error <= 0;
        end
    end
end

assign fully_grown = growth >= weight_out;
assign is_boundary = (boundary_condition_out==1'b1) && fully_grown;

assign a_output_data = (boundary_condition_out ==0)? b_input_data : 0;
assign b_output_data = (boundary_condition_out ==0)? a_input_data : 0;

always@(posedge clk) begin
    if(reset) begin
        weight_out <= 0;
        boundary_condition_out <= 0;
    end else begin
        boundary_condition_out <= boundary_condition_in;
        weight_out <= weight_in;
        // if(stage == STAGE_PARAMETERS_LOADING) begin
        //     weight_out <= weight_in;
        //     boundary_condition_out <= boundary_condition_in;
        // end else if(stage == STAGE_READ_FROM_MEM) begin
        //     //boundary_condition_out <= boundary_condition_mem;
        //     //Todo : Temporary hack to debug
        //     if(mem_rw_address != 0) begin
        //         boundary_condition_out <= 2;
        //     end else begin
        //         boundary_condition_out <= boundary_condition_mem;
        //     end
        // end
    end
end

reg write_to_mem;
reg [3:0] mem_rw_address;
wire [4:0] data_from_memory;
wire [4:0] data_to_memory;

blk_mem_gen_1 edge_mem (
    .clka(clk),            // Clock input
    //.rsta(reset),            // Reset input (active high)
    .ena(1'b1),              // Enable input
    .wea(write_to_mem),            // Write Enable input (0 to 0)
    .addra(mem_rw_address),     // Address input (3 downto 0)
    .dina(data_to_memory),      // Data input (35 downto 0)
    .douta(data_from_memory)    // Data output (35 downto 0)
);



//logic to calulate the address to write to memory
always@(posedge clk) begin
    if(reset) begin
        mem_rw_address <= 0;
    end else begin
        if (stage == STAGE_WRITE_TO_MEM  && local_context_switch == 1'b0) begin
            if(mem_rw_address < NUM_CONTEXTS -1) begin
                mem_rw_address <= mem_rw_address + 1;
            end else begin
                mem_rw_address <= 0;
            end
        end
    end
end

always@(*) begin
    if(reset) begin
        write_to_mem = 0;
    end else begin
        if (stage == STAGE_WRITE_TO_MEM) begin
            write_to_mem = 1;
        end else begin
            write_to_mem = 0;
        end
    end
end

// reg last_context_switch_is_local;
// always@(posedge clk) begin
//     if(reset) begin
//         last_context_switch_is_local <= 0;
//     end else begin
//         if (stage == STAGE_WRITE_TO_MEM) begin
//             last_context_switch_is_local <= local_context_switch;
//         end
//     end
// end

//logic to data write to memory
assign data_to_memory = {growth,is_error};

assign {growth_mem,is_error_mem} = (local_context_switch) ? {growth, is_error} : data_from_memory;

endmodule


