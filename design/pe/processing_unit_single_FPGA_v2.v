`timescale 1ns / 1ps

// This PEs are written for Z type ancillas
// Todo : Local context switch can be potentially removed.
module processing_unit #(
    parameter ADDRESS_WIDTH = 6,
    parameter NEIGHBOR_COUNT = 6,
    parameter NUM_CONTEXTS = 2
) (
    clk,
    reset,
    measurement,
    measurement_out,
    global_stage,

    neighbor_fully_grown,
    neighbor_increase,
    neighbor_is_boundary, //This indicates the PE is connected by a fully grown link to a boundary
    neighbor_is_error,

    input_address, // M,X,Z, address

    input_data,
    output_data,

    odd,
    root,
    busy
);

`include "../../parameters/parameters.sv"

localparam EXPOSED_DATA_SIZE = ADDRESS_WIDTH + 1 + 1 + 1;

input clk;
input reset;
input measurement;
output measurement_out;
input [STAGE_WIDTH-1:0] global_stage;

input [NEIGHBOR_COUNT-1:0] neighbor_fully_grown;
output reg neighbor_increase;
input [NEIGHBOR_COUNT-1:0] neighbor_is_boundary;
output [NEIGHBOR_COUNT-1:0] neighbor_is_error;

input [NEIGHBOR_COUNT*EXPOSED_DATA_SIZE-1:0] input_data;
output [NEIGHBOR_COUNT*EXPOSED_DATA_SIZE-1:0] output_data;

input [ADDRESS_WIDTH-1:0] input_address;

output reg [ADDRESS_WIDTH-1:0] root;
output reg odd;
output reg busy;

wire [NEIGHBOR_COUNT*ADDRESS_WIDTH-1:0] neighbor_root;
wire [NEIGHBOR_COUNT-1:0] neighbor_parent_vector;
wire [NEIGHBOR_COUNT-1:0] parent_odd;
wire [NEIGHBOR_COUNT - 1:0] child_cluster_parity;

wire cluster_parity_mem;
wire [NEIGHBOR_COUNT - 1:0] parent_vector_mem;
wire [ADDRESS_WIDTH-1:0] root_mem;
wire odd_mem;
wire m_mem;

genvar i;
generate
for (i = 0; i < NEIGHBOR_COUNT; i=i+1) begin: input_2d
    assign neighbor_root[(i+1)*ADDRESS_WIDTH-1 : i*ADDRESS_WIDTH] = input_data[i*EXPOSED_DATA_SIZE + ADDRESS_WIDTH-1 : i*EXPOSED_DATA_SIZE];
    assign neighbor_parent_vector[i] = input_data[i*EXPOSED_DATA_SIZE + ADDRESS_WIDTH + 1 -1];
    assign parent_odd[i] = input_data[i*EXPOSED_DATA_SIZE + ADDRESS_WIDTH + 2 -1];
    assign child_cluster_parity[i] = input_data[i*EXPOSED_DATA_SIZE + ADDRESS_WIDTH + 3 -1];
end
endgenerate

reg [NEIGHBOR_COUNT-1:0] parent_vector;
reg cluster_parity;

generate
for (i = 0; i < NEIGHBOR_COUNT; i=i+1) begin: output_2d
    assign output_data[i*EXPOSED_DATA_SIZE + ADDRESS_WIDTH-1 : i*EXPOSED_DATA_SIZE] = root ;
    assign output_data[i*EXPOSED_DATA_SIZE + ADDRESS_WIDTH + 1 -1]  = parent_vector[i];
    assign output_data[i*EXPOSED_DATA_SIZE + ADDRESS_WIDTH + 2 -1]  = odd;
    assign output_data[i*EXPOSED_DATA_SIZE + ADDRESS_WIDTH + 3 -1]  = cluster_parity;
end
endgenerate

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

// Load the measurement
reg m;
always@(posedge clk) begin
    if(reset) begin
        m <= 0;
    end else if(stage == STAGE_MEASUREMENT_LOADING) begin
        m <= measurement;
    end else if(stage == STAGE_WRITE_TO_MEM) begin
        m <= m_mem;
    end
end

assign measurement_out = m;

// Increase growth during the growth stage
reg already_grown;
always@(posedge clk) begin
    if(reset) begin
        already_grown <= 0;
    end else begin
        if((stage == STAGE_GROW) && (last_stage != STAGE_GROW)) begin
            already_grown <= ~already_grown;
        end
    end
end

always@(*) begin
    neighbor_increase = 1'b0;
    if( (stage == STAGE_GROW) && (last_stage != STAGE_GROW)) begin
        if(odd) begin
            neighbor_increase = 1'b1;
        end else begin
            neighbor_increase = 1'b0;
        end
    end
end

// root is the minimum of valid roots
// when root changes : change parent vector
wire [NEIGHBOR_COUNT-1 : 0] valid_from_root_comparator;
wire [ADDRESS_WIDTH - 1 : 0] result_from_root_comparator;

min_val_less_8x_with_index #(
    .DATA_WIDTH(ADDRESS_WIDTH),
    .CHANNEL_COUNT(NEIGHBOR_COUNT)
) u_tree_compare_solver (
    .values(neighbor_root),
    .valids(neighbor_fully_grown & ~neighbor_is_boundary),
    .result(result_from_root_comparator),
    .output_valids(valid_from_root_comparator)
);

// Calculate the next root and parent vector
reg [ADDRESS_WIDTH - 1 : 0] root_modified;
always@(*) begin
    root_modified = root;
    if(|(neighbor_is_boundary)) begin
        root_modified[ADDRESS_WIDTH-2 : 0] = input_address[ADDRESS_WIDTH-2 : 0];
        root_modified[ADDRESS_WIDTH-1] = 0;
    end
end

always@(posedge clk) begin
    if(stage == STAGE_MEASUREMENT_LOADING) begin
        root <= input_address;
        parent_vector <= 0;
    end else begin
        if (stage == STAGE_MERGE) begin
            if( (|valid_from_root_comparator) && result_from_root_comparator < root_modified && result_from_root_comparator < root) begin
                root <= result_from_root_comparator;
                parent_vector <= valid_from_root_comparator;
            end else if (root_modified < root) begin
                root <= root_modified;
                parent_vector <= 0;
            end
        end else if(stage == STAGE_WRITE_TO_MEM) begin
            root <= root_mem;
            parent_vector <= parent_vector_mem;
        end
    end
end

// Calculate the sub-tree parity and sub_tree touching boundary

wire next_cluster_parity = (^(neighbor_parent_vector & child_cluster_parity)) ^ m;
wire next_cluster_touching_boundary = (|neighbor_is_boundary);

always@(posedge clk) begin
    if(stage == STAGE_MEASUREMENT_LOADING) begin
        cluster_parity <= measurement;
    end else begin
        if (stage == STAGE_MERGE) begin
            cluster_parity <= next_cluster_parity;
        end else if(stage == STAGE_WRITE_TO_MEM) begin
            cluster_parity <= cluster_parity_mem;
        end
    end
end

// Calculate cluster odd if you are the root.
// If not pass parents odd data
always@(posedge clk) begin
    if(stage == STAGE_MEASUREMENT_LOADING) begin
        odd <= measurement;
    end else begin
        if (stage == STAGE_MERGE) begin
            if(|parent_vector) begin
                odd <= |(parent_vector & parent_odd);
            end else begin
                odd <= next_cluster_parity & !next_cluster_touching_boundary;
            end
        end else if(stage == STAGE_WRITE_TO_MEM) begin
            odd <= odd_mem;
        end
    end
end

// Peeling logic.

reg [NEIGHBOR_COUNT-1:0] neighbor_is_error_internal;
reg [NEIGHBOR_COUNT-1:0] neighbor_is_error_border;
always@(*) begin
    if(stage == STAGE_PEELING && cluster_parity == 1'b1) begin
    // We only connect the root to the boundary. Odd clusters always have root at the boundary 
        neighbor_is_error_internal = parent_vector;
    end else begin
        neighbor_is_error_internal = 6'b0;
    end
end

always@(*) begin
    if(stage == STAGE_PEELING &&  !(|parent_vector) && next_cluster_parity) begin
        casex (neighbor_is_boundary)
            6'b1xxxxx: neighbor_is_error_border = 6'b100000;
            6'b01xxxx: neighbor_is_error_border = 6'b010000;
            6'b001xxx: neighbor_is_error_border = 6'b001000;
            6'b0001xx: neighbor_is_error_border = 6'b000100;
            6'b00001x: neighbor_is_error_border = 6'b000010;
            6'b000001: neighbor_is_error_border = 6'b000001;
            default: neighbor_is_error_border = 0;
        endcase
    end else begin
        neighbor_is_error_border = 6'b0;
    end
end

assign neighbor_is_error = neighbor_is_error_internal | neighbor_is_error_border;

// Calculate busy
// Todo: We need to simplify this to the multi-FPGA case
always@(posedge clk) begin
    if(reset) begin
        busy <= 0;
    end else begin
        if (stage == STAGE_MERGE) begin
            if( ((|valid_from_root_comparator) && result_from_root_comparator < root) ||
                    (root_modified < root) ||
                 next_cluster_parity != cluster_parity ||
                 (|(parent_vector) & (|(parent_vector & parent_odd) != odd)) ||
                 (~|(parent_vector) && ((next_cluster_parity & !next_cluster_touching_boundary) != odd))
            )begin
                busy <= 1;
            end else begin
                busy <= 0;
            end
        end
    end
end

reg write_to_mem;
localparam RAM_LOG_DEPTH = $clog2(NUM_CONTEXTS);
reg [RAM_LOG_DEPTH-1:0] mem_read_address;
reg [RAM_LOG_DEPTH-1:0] mem_write_address;
wire [RAM_LOG_DEPTH-1:0] mem_rw_address;
localparam RAM_WIDTH = ADDRESS_WIDTH + 6 + 3;
reg [RAM_WIDTH - 1 :0] data_from_memory;
wire [RAM_WIDTH - 1:0] data_to_memory;

//rams_sp_nc #(
//    .DEPTH(NUM_CONTEXTS),
//    .WIDTH(RAM_WIDTH)
//) PE_mem (
//    .clk(clk),            // Clock input
//    //.rsta(reset),            // Reset input (active high)
//    .en(1'b1),              // Enable input
//    .we(write_to_mem),            // Write Enable input (0 to 0)
//    .addr(mem_rw_address),     // Address input (3 downto 0)
//    .di(data_to_memory),      // Data input (35 downto 0)
//    .dout(data_from_memory)   // Data output (35 downto 0)
//);

always@(posedge clk) begin
    if(write_to_mem) begin
        data_from_memory <= data_to_memory;
    end
end

//logic to calulate the address to write to memory
always@(posedge clk) begin
    if(reset) begin
        mem_write_address <= 0;
    end else begin
        if (stage == STAGE_WRITE_TO_MEM) begin
            if(mem_write_address < NUM_CONTEXTS -1) begin
                mem_write_address <= mem_write_address + 1;
            end else begin
                mem_write_address <= 0;
            end
        end
    end
end

always@(posedge clk) begin
    if(reset) begin
        mem_read_address <= 1;
    end else begin
        if (stage == STAGE_WRITE_TO_MEM) begin
            if(mem_read_address < NUM_CONTEXTS -1) begin
                mem_read_address <= mem_read_address + 1;
            end else begin
                mem_read_address <= 0;
            end
        end
    end
end

assign mem_rw_address = (stage == STAGE_WRITE_TO_MEM) ? mem_write_address : mem_read_address;

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

//logic to data write to memory
assign data_to_memory = {cluster_parity, parent_vector[5:0], root, odd, m};

//logic to read data from memory
assign {cluster_parity_mem, parent_vector_mem, root_mem, odd_mem, m_mem} = data_from_memory;
            

endmodule