`timescale 1ns / 10ps

// Output file format
// Each line is 32 bit. Cordinates are entered as two 16 bit entries in a single line
// Test ID
// root_of_0,0
// root_of_0,1
// .....
// Test ID
// root_of_0,0
// root_of_0,1
// .......

module verification_bench_leaf#(
    parameter CODE_DISTANCE = 5,
    parameter NUM_FPGAS = 2,
    parameter ROUTER_DELAY = 18,
    parameter FPGA_ID = 1,
    parameter NUM_CONTEXTS = 1,
    parameter LOGICAL_QUBITS_PER_DIM = 2
)(
    input clk,
    input reset,

    input [63:0] parent_rx_data,
    input parent_rx_valid,
    output parent_rx_ready,

    output [63:0] parent_tx_data,
    output parent_tx_valid,
    input parent_tx_ready
 );

`include "../../parameters/parameters.sv"
`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end
               
localparam CODE_DISTANCE_X = (CODE_DISTANCE + 1)*LOGICAL_QUBITS_PER_DIM;
localparam CODE_DISTANCE_Z = (CODE_DISTANCE - 1)/2;

parameter GRID_WIDTH_X = (CODE_DISTANCE + 1)*LOGICAL_QUBITS_PER_DIM;
parameter GRID_WIDTH_Z = (CODE_DISTANCE - 1)/2;
parameter GRID_WIDTH_U = CODE_DISTANCE; // Laksheen
localparam PHYSICAL_GRID_WIDTH_U = (GRID_WIDTH_U % NUM_CONTEXTS == 0) ? 
                                   (GRID_WIDTH_U / NUM_CONTEXTS) : 
                                   (GRID_WIDTH_U / NUM_CONTEXTS + 1);
parameter MAX_WEIGHT = 2;


`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = PHYSICAL_GRID_WIDTH_U * NUM_CONTEXTS;


localparam PU_COUNT_ACROSS_CONTEXT = CODE_DISTANCE_X * CODE_DISTANCE_Z * PHYSICAL_GRID_WIDTH_U * NUM_CONTEXTS;

localparam X_BIT_WIDTH = $clog2(GRID_WIDTH_X);
localparam Z_BIT_WIDTH = $clog2(GRID_WIDTH_Z);
localparam U_BIT_WIDTH = $clog2(GRID_WIDTH_U);
localparam FPGA_BIT_WIDTH = $clog2(NUM_FPGAS);
localparam ADDRESS_WIDTH = X_BIT_WIDTH + Z_BIT_WIDTH + U_BIT_WIDTH + FPGA_BIT_WIDTH;

localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

localparam NS_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z;
localparam EW_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z + 1;
localparam UD_ERROR_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam CORRECTION_COUNT_PER_ROUND = NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND + UD_ERROR_COUNT_PER_ROUND;
localparam CORRECTION_BYTES_PER_ROUND = ((CORRECTION_COUNT_PER_ROUND  + 7) >> 3);


wire [(ADDRESS_WIDTH * PU_COUNT_ACROSS_CONTEXT)-1:0] roots;

`define BYTES_PER_ROUND ((CODE_DISTANCE_X * CODE_DISTANCE_Z  + 7) >> 3)
`define ALIGNED_PU_PER_ROUND (`BYTES_PER_ROUND << 3)

reg [`ALIGNED_PU_PER_ROUND*PHYSICAL_GRID_WIDTH_U * NUM_CONTEXTS-1:0] measurements;

`define INDEX(i, j, k) (i * CODE_DISTANCE_Z + j + k * CODE_DISTANCE_Z*CODE_DISTANCE_X)
`define PADDED_INDEX(i, j, k) (i * CODE_DISTANCE_Z + j + k * `ALIGNED_PU_PER_ROUND)
`define measurements(i, j, k) measurements[`PADDED_INDEX(i, j, k)]
// `define is_odd_cluster(i, j, k) decoder.is_odd_clusters[`INDEX(i, j, k)]
`define root(i, j, k) decoder.roots[ADDRESS_WIDTH*`INDEX(i, j, k) +: ADDRESS_WIDTH]
`define root_x(i, j, k) decoder.roots[ADDRESS_WIDTH*`INDEX(i, j, k)+Z_BIT_WIDTH +: X_BIT_WIDTH]
`define root_z(i, j, k) decoder.roots[ADDRESS_WIDTH*`INDEX(i, j, k) +: Z_BIT_WIDTH]
`define root_u(i, j, k) decoder.roots[ADDRESS_WIDTH*`INDEX(i, j, k)+X_BIT_WIDTH+Z_BIT_WIDTH +: U_BIT_WIDTH]
`define root_fpga(i, j, k) decoder.roots[ADDRESS_WIDTH*`INDEX(i, j, k)+X_BIT_WIDTH+Z_BIT_WIDTH+U_BIT_WIDTH +: FPGA_BIT_WIDTH]



reg [7:0] input_data;
reg input_valid;
wire input_ready;
wire [7:0] output_data;
wire output_valid;
reg output_ready;

wire [7:0] input_data_fifo;
wire input_valid_fifo;
wire input_ready_fifo;
wire [7:0] output_data_fifo;
wire output_valid_fifo;
wire output_ready_fifo;


// instantiate
Helios_single_FPGA #(
    .GRID_WIDTH_X(GRID_WIDTH_X),
    .GRID_WIDTH_Z(GRID_WIDTH_Z),
    .GRID_WIDTH_U(GRID_WIDTH_U),
    .MAX_WEIGHT(MAX_WEIGHT),
    .NUM_CONTEXTS(NUM_CONTEXTS),
    .NUM_FPGAS(NUM_FPGAS),
    .ROUTER_DELAY_COUNTER(ROUTER_DELAY),
    .LOGICAL_QUBITS_PER_DIM(LOGICAL_QUBITS_PER_DIM)
 ) decoder (
    .clk(clk),
    .reset(reset),
    .input_data(input_data_fifo),
    .input_valid(input_valid_fifo),
    .input_ready(input_ready_fifo),
    .output_data(output_data_fifo),
    .output_valid(output_valid_fifo),
    .output_ready(output_ready_fifo),

    .parent_rx_data(parent_rx_data),
    .parent_rx_valid(parent_rx_valid),
    .parent_rx_ready(parent_rx_ready),
    .parent_tx_data(parent_tx_data),
    .parent_tx_valid(parent_tx_valid),
    .parent_tx_ready(parent_tx_ready),
    .FPGA_ID(FPGA_ID)
    
    //.roots(roots)
);

// FIFO
fifo_wrapper #(
    .WIDTH(8),
    .DEPTH(128)
) input_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(input_data),
    .input_valid(input_valid),
    .input_ready(input_ready),
    .output_data(input_data_fifo),
    .output_valid(input_valid_fifo),
    .output_ready(input_ready_fifo)
);

fifo_wrapper #(
    .WIDTH(8),
    .DEPTH(128)
) output_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(output_data_fifo),
    .input_valid(output_valid_fifo),
    .input_ready(output_ready_fifo),
    .output_data(output_data),
    .output_valid(output_valid),
    .output_ready(output_ready)
);

reg valid_delayed = 0;
integer i;
integer j;
integer k;
integer context_k;
integer file, input_file;
reg open = 1;
reg input_open = 1;
reg eof = 0;
reg input_eof = 0;
reg [31:0] read_value, test_case, input_read_value;
reg [X_BIT_WIDTH-1 : 0] expected_x;
reg [Z_BIT_WIDTH-1 : 0] expected_z;
reg [U_BIT_WIDTH-1 : 0] expected_u;
reg [FPGA_BIT_WIDTH-1 : 0] expected_fpga;
reg test_fail;
reg processing = 0;
reg [31:0] syndrome_count;
reg [31:0] pass_count = 0;
reg [31:0] fail_count = 0;
reg [31:0] total_count;

reg [2:0] loading_state;
reg [31:0] input_fifo_counter;

reg new_round_start;
reg [31:0] cycle_counter;
reg [31:0] iteration_counter;
reg [31:0] message_counter;

reg completed;

always @(posedge clk) begin
    if(reset) begin
        loading_state <= 3'b0;
        completed = 0;
    end else begin
        case(loading_state)
            3'b0: begin
                loading_state <= 3'b1;
                input_fifo_counter <= 0;
            end
            3'b1: begin // start decoding header
                loading_state <= 3'b10;
            end
            3'b10: begin // measurement data header
                loading_state <= 3'b11;
                input_fifo_counter <= 0;
            end
            3'b11: begin
                if (input_fifo_counter == (`BYTES_PER_ROUND*PHYSICAL_GRID_WIDTH_U*NUM_CONTEXTS-1)) begin
                    loading_state <= 3'b100;
                end
                input_fifo_counter <= input_fifo_counter + 1; 
            end
            3'b100: begin
                if(output_valid == 1) begin
                    loading_state <= 3'b101;
                    message_counter <= 0;
                end
            end
            3'b101: begin
                if(message_counter == (CORRECTION_BYTES_PER_ROUND*PHYSICAL_GRID_WIDTH_U*NUM_CONTEXTS-1) + 3) begin
                    loading_state <= 3'b10;
                end else begin
                    if(output_valid == 1) begin
                        message_counter <= message_counter + 1;
                        if (message_counter == 0) begin
                        iteration_counter <= {24'b0, output_data[7:0]};
                        end
                        if (message_counter == 1) begin
                            cycle_counter[15:8] <= {24'b0, output_data[7:0]};
                        end
                        if (message_counter == 2) begin
                            cycle_counter[7:0] <= {24'b0, output_data[7:0]};
                        end
                    end
                    cycle_counter[31:16] <= 16'b0;
                end
            end
        endcase
    end
end

always@(*) begin
    if(loading_state == 3'b1) begin
        input_valid = 0;
        input_data = START_DECODING_MSG;
    end else if (loading_state == 3'b10) begin
        input_valid = 0;
        input_data = MEASUREMENT_DATA_HEADER;
    end else if (loading_state == 3'b11) begin
        input_valid = 1;
        input_data = measurements[input_fifo_counter*8 +: 8];
    end else begin
        input_valid = 0;
    end
end

always @(*) begin
    if (loading_state == 3'b101) begin
        output_ready = 1;
    end else begin
        output_ready = 0;
    end
end

string input_filename, output_filename;

// Input loading logic
always @(negedge clk) begin
    if (loading_state == 3'b10 && completed == 0) begin
        measurements = 0;
        if(input_open == 1) begin
            input_filename = $sformatf("/home/heterofpga/Desktop/qec_hardware/test_benches/test_data/input_data_%0d_%0d.txt", CODE_DISTANCE, FPGA_ID);
            input_file = $fopen(input_filename, "r");
            input_open = 0;
        end
        if (input_eof == 0)begin 
            $fscanf (input_file, "%h\n", test_case);
            input_eof = $feof(input_file);
            if (input_eof == 0)begin 
                syndrome_count = 0;
            end
        end
        for (k=0 ;k <MEASUREMENT_ROUNDS; k++) begin
            for (i=0 ;i <CODE_DISTANCE_X; i++) begin
                for (j=0 ;j <CODE_DISTANCE_Z; j++) begin
                    if (input_eof == 0)begin 
                        $fscanf (input_file, "%h\n", input_read_value);
                        `measurements(i, j, k) = input_read_value;
                        if (input_read_value == 1) begin //This is to avoid duplication in the border PEs
                            syndrome_count = syndrome_count + 1;
                        end
                    end
                end
            end
        end
    end else begin
        new_round_start = 0;
    end
end


// Output verification logic
always @(posedge clk) begin
    if (decoder.controller.global_stage_d == STAGE_PEELING && completed == 0) begin // When we move to peeling we are doen with clustering
//       $display("%t\tTest case %d pass %d cycles %d iterations %d syndromes", $time, test_case, cycle_counter, iteration_counter, syndrome_count);
       if(open == 1) begin
            output_filename = $sformatf("/home/heterofpga/Desktop/qec_hardware/test_benches/test_data/output_data_%0d_%0d.txt", CODE_DISTANCE, FPGA_ID);
            file = $fopen(output_filename, "r");
            open = 0;
        end
        if (eof == 0)begin 
            if(decoder.controller.current_context == 0) begin
                $fscanf (file, "%h\n", test_case);
                test_fail = 0;
            end
            eof = $feof(file);
        end
        for (k=0 ;k <PHYSICAL_GRID_WIDTH_U; k++) begin
            for (i=0 ;i <CODE_DISTANCE_X; i++) begin
                for (j=0 ;j <CODE_DISTANCE_Z; j++) begin
                    if (eof == 0)begin 
                        $fscanf (file, "%h\n", read_value);
                        if(Z_BIT_WIDTH>0) begin
                            expected_z = read_value[Z_BIT_WIDTH - 1:0];
                        end else begin
                            expected_z = 0;
                        end
                        expected_x = read_value[X_BIT_WIDTH - 1 + 8 :8];
                        expected_u = read_value[U_BIT_WIDTH - 1 + 16 :16];
                        expected_fpga = read_value[FPGA_BIT_WIDTH - 1 + 24 :24];
                        eof = $feof(file);
                        
                        // context_k = k;
                        // These logic are for multi context verification
                        if(decoder.controller.current_context % 2 == 1) begin
                            context_k = decoder.controller.current_context*PHYSICAL_GRID_WIDTH_U + PHYSICAL_GRID_WIDTH_U - k - 1;
                        end else begin
                            context_k = decoder.controller.current_context*PHYSICAL_GRID_WIDTH_U  + k;
                        end
//                        if(decoder.controller.current_context == NUM_CONTEXTS - 1 && expected_u == 0 && expected_x==0 && expected_z==0) begin //hack for d=7,11
//                            continue;
                        //end else begin
                            if(Z_BIT_WIDTH>0) begin
                                if (expected_u != `root_u(i, j, k) || expected_x != `root_x(i, j, k) || expected_z != `root_z(i, j, k)) begin
                                    $display("%t\t Root(%0d,%0d,%0d) = (%0d,%0d,%0d,%0d) : Expected (%0d,%0d,%0d,%0d) : TC %d : ID %d" , $time, context_k, i ,j, `root_fpga(i,j,k), `root_u(i, j, k), `root_x(i, j, k), `root_z(i, j, k), expected_fpga, expected_u, expected_x, expected_z, test_case, FPGA_ID);
                                    test_fail = 1;
                                end
                            end else begin
                                // This logic has to be modified to multi FPGA
                                if (expected_u != `root_u(i, j, k) || expected_x != `root_x(i, j, k)) begin
                                    $display("%t\t Root(%0d,%0d,%0d) = (%0d,%0d,%0d) : Expected (%0d,%0d,%0d) : TC %d : ID %d" , $time, context_k, i ,j, `root_u(i, j, k), `root_x(i, j, k), 0, expected_u, expected_x, expected_z, test_case, FPGA_ID);
                                    test_fail = 1;
                                end
                            end
                        //end
                    end
                end
            end
        end
    end
    if (message_counter == 3 && output_valid == 1 && completed == 0) begin // Cycle counter and iteration counter is recevied
        if (!test_fail) begin
            $display("%t\tID  = %d Test case  = %d, %d pass %d cycles %d first round %d syndromes", $time, FPGA_ID, test_case, pass_count, cycle_counter, iteration_counter, syndrome_count);
            pass_count = pass_count + 1;
        end else begin
            $display("%t\tID  = %d Test case  = %d, %d fail %d cycles %d iterations %d syndromes", $time, FPGA_ID, test_case, fail_count, cycle_counter, iteration_counter, syndrome_count);
            fail_count = fail_count + 1;
            $finish;
        end
    end
    if (input_eof == 1 && completed == 0)begin
        total_count = pass_count + fail_count;
        $display("%t\t Done:", $time);
        $display("Total : %d",total_count);
        $display("Passed : %d",pass_count);
        $display("Failed : %d",fail_count);
        completed = 1;
        $finish;
    end
end




endmodule
