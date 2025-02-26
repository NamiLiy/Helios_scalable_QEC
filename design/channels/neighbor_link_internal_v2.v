module neighbor_link_internal #(
    parameter ADDRESS_WIDTH = 6,
    parameter MAX_WEIGHT = 2,
    parameter NUM_CONTEXTS = 2,
    parameter STORE_EXTERNAL = 0, //1 means edges to lower SPEs, 2 means edges to upper PEs. Only needed for support PES when num_ctx > 2
    parameter DUMMY_EDGE = 0
    // parameter WEIGHT = 2,
    // parameter BOUNDARY_CONDITION = 0, //0 : No boundary 1: A boundary 2: Non existant edge 3: fusion edge (fusion edge is connected on both ends but acts like a boundary)
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
    do_not_store,

    reset_edge,
    context_input,
    context_output
);

`include "../../parameters/parameters.sv"

localparam LINK_BIT_WIDTH = $clog2(MAX_WEIGHT + 1);
localparam EXPOSED_DATA_SIZE = ADDRESS_WIDTH + 1 + 1 + 1;

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
input do_not_store;

input reset_edge;
input [2:0] context_input;
output [2:0] context_output;

output reg [LINK_BIT_WIDTH-1:0] weight_out;
output reg [1:0] boundary_condition_out;

reg [LINK_BIT_WIDTH-1 : 0] growth;
reg [STAGE_WIDTH-1:0] stage;
reg [STAGE_WIDTH-1:0] last_stage;

wire [1:0] growth_mem;
wire [1:0] boundary_condition_mem;
wire is_error_mem;



`define MIN(a, b) (((a) < (b)) ? (a) : (b))

if (DUMMY_EDGE == 0) begin

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
    if (boundary_condition_out == 0 || boundary_condition_out == 2'b11)  begin // No boundary default case 
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
        if(reset_edge == 1'b1) begin
            growth <= 0;
        end else if(stage == STAGE_WRITE_TO_MEM) begin
            growth <= growth_mem;
        end else begin
            growth <= growth_new;
        end 
    end
end

always@(posedge clk) begin
    if(reset) begin
        is_error <= 0;
    end else if(stage == STAGE_WRITE_TO_MEM) begin
        is_error <= is_error_mem;
    end else begin
        if (boundary_condition_out == 0 || boundary_condition_out == 2'b11)  begin // No boundary default case 
            if(stage == STAGE_RESULT_VALID) begin
                is_error <= is_error_systolic_in;
            end else begin
                is_error <= a_is_error_in | b_is_error_in;
            end
        end else if (boundary_condition_out == 1) begin // edge touching a boundary
            if(stage == STAGE_RESULT_VALID) begin
                is_error <= is_error_systolic_in;
            end else begin
                is_error <= a_is_error_in;
            end
        end else begin // Non existant edge
            is_error <= 0;
        end
    end
end

assign fully_grown = (growth >= weight_out) && (boundary_condition_out != 2'b10); // Non-existent edge can never be fully grown
assign is_boundary = (boundary_condition_out==2'b01 || boundary_condition_out == 2'b11) && fully_grown;

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
localparam RAM_LOG_DEPTH = $clog2(NUM_CONTEXTS + 1);
reg [RAM_LOG_DEPTH-1:0] mem_read_address;
reg [RAM_LOG_DEPTH-1:0] mem_write_address;
wire [RAM_LOG_DEPTH-1:0] mem_rw_address;
localparam RAM_WIDTH = 3;
wire [RAM_WIDTH - 1 :0] data_from_memory;
wire [RAM_WIDTH - 1:0] data_to_memory;

reg [RAM_LOG_DEPTH-1:0] context_min;
reg [RAM_LOG_DEPTH-1:0] context_max;
reg context_full_range;
reg not_first_block;


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

localparam HALF_CONTEXT = (NUM_CONTEXTS >> 1);

reg continutation_from_top;

always@(posedge clk) begin
    if(reset) begin
        context_min <= 0;
        context_max <= HALF_CONTEXT -1;
        context_full_range <= 0;
        not_first_block <= 0;
        continutation_from_top <= 1;
    end else begin
        if(mem_write_address == 0 || mem_write_address == HALF_CONTEXT) begin
            if(stage == STAGE_RESET_ROOTS)begin
                if(not_first_block) begin
                    if(context_full_range) begin
                        if(mem_write_address == 0) begin
                            context_min <= HALF_CONTEXT;
                            context_max <= NUM_CONTEXTS - 1;
                        end else begin
                            context_min <= 0;
                            context_max <= HALF_CONTEXT - 1;
                        end
                        continutation_from_top <= ~continutation_from_top;
                        context_full_range <= 0;
                    end else begin
                        if(NUM_CONTEXTS <=2) begin
                            context_min <= 0;
                            context_max <= NUM_CONTEXTS - 1;
                        end else begin
                            if(mem_write_address == 0) begin
                                context_min <= HALF_CONTEXT;
                                context_max <= HALF_CONTEXT - 1;
                            end else begin
                                context_min <= 0;
                                context_max <= NUM_CONTEXTS - 1;
                            end
                        end
                        context_full_range <= 1;
                    end
                end else begin
                    context_min <= HALF_CONTEXT;
                    context_max <= NUM_CONTEXTS - 1;
                    not_first_block <= 1;
                end
            end else if(stage == STAGE_PEELING) begin
                if(mem_write_address == 0) begin
                    context_min <= 0;
                    context_max <= HALF_CONTEXT - 1;
                end else begin
                    context_min <= HALF_CONTEXT;
                    context_max <= NUM_CONTEXTS - 1;
                end
            end else if(stage == STAGE_RESULT_VALID) begin
                if(NUM_CONTEXTS <=2) begin
                    context_min <= 0;
                    context_max <= NUM_CONTEXTS - 1;
                end else begin
                    if(mem_write_address == 0) begin
                        context_min <= HALF_CONTEXT;
                        context_max <= HALF_CONTEXT-1;
                    end else begin
                        context_min <= 0;
                        context_max <= NUM_CONTEXTS - 1;
                    end
                end
            end
        end
    end
end

if(STORE_EXTERNAL == 0) begin

    //logic to calulate the address to write to memory
    always@(posedge clk) begin
        if(reset) begin
            mem_write_address <= 0;
        end else begin
            if (stage == STAGE_WRITE_TO_MEM) begin
                if(do_not_store == 1'b0) begin
                    if(NUM_CONTEXTS > 2) begin
                        if(mem_write_address == context_max) begin
                            mem_write_address <= context_min;
                        end else if (mem_write_address == NUM_CONTEXTS - 1) begin
                            mem_write_address <= 0;
                        end else begin
                            mem_write_address <= mem_write_address + 1;
                        end
                    end else begin
                        mem_write_address <= ~mem_write_address;
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
                    if(NUM_CONTEXTS > 2) begin
                        if(mem_read_address == context_max) begin
                            mem_read_address <= context_min;
                        end else if (mem_read_address == NUM_CONTEXTS - 1) begin
                            mem_read_address <= 0;
                        end else begin
                            mem_read_address <= mem_read_address + 1;
                        end
                    end else begin
                        mem_read_address <= ~mem_read_address;
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

    //logic to data write to memory
    assign data_to_memory = {growth,is_error};
    assign {growth_mem,is_error_mem} = (do_not_store) ? {growth, 1'b0} : data_from_memory;

end else if(STORE_EXTERNAL == 1) begin

    
            
    assign growth_mem = context_input[2:1];
    assign is_error_mem = context_input[0];

    assign context_output[2:1] = growth;
    assign context_output[0] = is_error;

    always@(*) begin
        if(reset) begin
            write_to_mem = 0;
        end else begin
            write_to_mem = 0;
        end
    end

end else if(STORE_EXTERNAL == 2) begin

    reg [RAM_LOG_DEPTH-1:0] context_address;

    // always@(posedge clk) begin
    //     if(reset) begin
    //         stored_context <= 0;
    //     end else begin
    //         stored_context <= context_input;
    //     end
    // end

    // always@(posedge clk) begin
    //     if(reset) begin
    //         stored_context_valid <= 0;
    //         stored_context <= 0;
    //     end else begin
    //         if(stage == STAGE_WRITE_TO_MEM) begin
    //             if(mem_read_address == context_min) begin
    //                 stored_context_valid <= 1;
    //                 stored_context[2:1] <= growth;
    //                 stored_context[0] <= is_error;
    //             end else begin
    //                 stored_context_valid <= 0;
    //             end
    //         end
    //     end
    // end

    // always@(posedge clk) begin
    //     if(reset) begin
    //         mem_read_address <= 1;
    //         mem_read_address_d <= 0;
    //         mem_write_address <= HALF_CONTEXT - 1;
    //     end else begin
    //         if (stage == STAGE_WRITE_TO_MEM) begin
    //             if(do_not_store == 1'b0) begin
    //                 if(NUM_CONTEXTS > 2) begin
    //                     if(mem_read_address == context_max) begin
    //                         mem_read_address <= context_min;
    //                     end else if (mem_read_address == NUM_CONTEXTS - 1) begin
    //                         mem_read_address <= 0;
    //                     end else begin
    //                         mem_read_address <= mem_read_address + 1;
    //                     end
    //                 end else begin
    //                     mem_read_address <= ~mem_read_address;
    //                 end
    //                 mem_read_address_d <= mem_read_address;
    //                 mem_write_address <= mem_read_address_d;
    //             end
    //         end
    //     end
    // end

    //logic to calulate the address to write to memory
    always@(posedge clk) begin
        if(reset) begin
            context_address <= 0;
        end else begin
            if (stage == STAGE_WRITE_TO_MEM) begin
                if(do_not_store == 1'b0) begin
                    if(NUM_CONTEXTS > 2) begin
                        if(context_address == context_max) begin
                            context_address <= context_min;
                        end else if (context_address == NUM_CONTEXTS - 1) begin
                            context_address <= 0;
                        end else begin
                            context_address <= context_address + 1;
                        end
                    end else begin
                        context_address <= ~context_address;
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
                    if(NUM_CONTEXTS > 2) begin
                        if(mem_read_address == context_max) begin
                            mem_read_address <= context_min;
                        end else if (mem_read_address == NUM_CONTEXTS - 1) begin
                            mem_read_address <= 0;
                        end else begin
                            mem_read_address <= mem_read_address + 1;
                        end
                    end else begin
                        mem_read_address <= ~mem_read_address;
                    end
                end
            end
        end
    end

    always@(posedge clk) begin
        if(reset) begin
            mem_write_address <= HALF_CONTEXT - 1;
        end else begin
            if (stage == STAGE_WRITE_TO_MEM) begin
                if(do_not_store == 1'b0) begin
                    if(NUM_CONTEXTS > 2) begin
                        if(mem_write_address == context_max) begin
                            mem_write_address <= context_min;
                        end else if (mem_write_address == NUM_CONTEXTS - 1) begin
                            mem_write_address <= 0;
                        end else begin
                            mem_write_address <= mem_write_address + 1;
                        end
                    end else begin
                        mem_write_address <= ~mem_write_address;
                    end
                end
            end
        end
    end

    reg [1:0] grow_at_zero;
    reg [1:0] grow_at_2d;
    reg [1:0] grow_at_d_low;
    reg [1:0] grow_at_d_high;

    reg is_error_at_zero;
    reg is_error_at_2d;
    reg is_error_at_d_low;
    reg is_error_at_d_high;

    always@(posedge clk) begin
        if(reset) begin
            grow_at_zero <= 0;
            grow_at_2d <= 0;
            grow_at_d_low <= 0;
            grow_at_d_high <= 0;
            is_error_at_zero <= 0;
            is_error_at_2d <= 0;
            is_error_at_d_low <= 0;
            is_error_at_d_high <= 0;
        end else begin
            if(stage == STAGE_WRITE_TO_MEM) begin
                if(context_address == 0) begin
                    grow_at_zero <= context_input[2:1];
                    is_error_at_zero <= context_input[0];
                    if(~continutation_from_top) begin
                        grow_at_2d <= context_input[2:1];
                        is_error_at_2d <= context_input[0];
                    end
                end else if(context_address == HALF_CONTEXT-1) begin
                    grow_at_d_low <= growth;
                    is_error_at_d_low <= is_error;
                    if(continutation_from_top) begin
                        grow_at_d_high <= growth;
                        is_error_at_d_high <= is_error;
                    end
                end else if(context_address == HALF_CONTEXT) begin
                    grow_at_d_high <= context_input[2:1];
                    is_error_at_d_high <= context_input[0];
                    if(continutation_from_top) begin
                        grow_at_d_low <= context_input[2:1];
                        is_error_at_d_low <= context_input[0];
                    end
                end else if(context_address == NUM_CONTEXTS - 1) begin
                    grow_at_2d <= growth;
                    is_error_at_2d <= is_error;
                    if(~continutation_from_top) begin
                        grow_at_zero <= growth;
                        is_error_at_zero <= is_error;
                    end
                end
            end
        end
    end

    always@(*) begin
        if(reset) begin
            write_to_mem = 0;
        end else begin
            if (stage == STAGE_WRITE_TO_MEM && do_not_store == 1'b0) begin
                if(context_address == 0 || context_address == HALF_CONTEXT) begin
                    write_to_mem = 0;
                end else begin
                    write_to_mem = 1;
                end
            end else begin
                write_to_mem = 0;
            end
        end
    end

    assign data_to_memory = context_input;
    assign mem_rw_address = (stage == STAGE_WRITE_TO_MEM) ? mem_write_address : mem_read_address;
    assign {growth_mem,is_error_mem} = (mem_read_address == (HALF_CONTEXT -1) ? {grow_at_d_low,is_error_at_d_low} : 
                                        (mem_read_address == (NUM_CONTEXTS - 1) ? 
                                        {grow_at_2d,is_error_at_2d} : data_from_memory));

    reg [1:0] grow_for_low;
    reg is_error_for_low;

    always@(*) begin
        if(mem_read_address == 0) begin
            if(context_address == HALF_CONTEXT -1) begin
                grow_for_low = grow_at_zero;
                is_error_for_low = is_error_at_zero;
            end else if(context_address == NUM_CONTEXTS - 1 && ~continutation_from_top) begin
                grow_for_low = growth;
                is_error_for_low = is_error;
            end else begin
                grow_for_low = grow_at_zero;
                is_error_for_low = is_error_at_zero;
            end
        end else if(mem_read_address == HALF_CONTEXT) begin
            if(context_address == NUM_CONTEXTS -1) begin
                grow_for_low = grow_at_d_high;
                is_error_for_low = is_error_at_d_high;
            end else if(context_address == HALF_CONTEXT -1 && continutation_from_top) begin
                grow_for_low = growth;
                is_error_for_low = is_error;
            end else begin
                grow_for_low = grow_at_d_high;
                is_error_for_low = is_error_at_d_high;
            end
        end else begin
            grow_for_low = growth;
            is_error_for_low = is_error;
        end
    end

    assign context_output[2:1] = grow_for_low;
    assign context_output[0] = is_error_for_low;
end

end else begin
    assign fully_grown = 0;
    assign is_boundary = 0;
    assign a_output_data = 0;
    assign b_output_data = 0;
    assign context_output = 0;

    always@(posedge clk) begin
        is_error <= 0;
        weight_out <= 0;
        boundary_condition_out <= 0;
    end
end




endmodule


