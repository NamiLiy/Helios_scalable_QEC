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

module bench_single_FPGA;

`include "../../parameters/parameters.sv"
`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

localparam CODE_DISTANCE = 5;                ;
localparam CODE_DISTANCE_X = CODE_DISTANCE;
localparam CODE_DISTANCE_Z = CODE_DISTANCE_X - 1;
localparam WEIGHT_X = 2;
localparam WEIGHT_Z = 2;
localparam WEIGHT_M = 2; // Weight up down


`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam PER_DIM_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = PER_DIM_WIDTH * 3;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

reg clk;
reg reset;
reg new_round_start = 0;

reg [PU_COUNT-1:0] measurements;
wire [31:0] cycle_counter;
wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
wire result_valid;
wire [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;

`define INDEX(i, j, k) (i * CODE_DISTANCE_Z + j + k * CODE_DISTANCE_Z*CODE_DISTANCE_X)
`define measurements(i, j, k) measurements[`INDEX(i, j, k)]
// `define is_odd_cluster(i, j, k) decoder.is_odd_clusters[`INDEX(i, j, k)]
`define root(i, j, k) roots[ADDRESS_WIDTH*`INDEX(i, j, k) +: ADDRESS_WIDTH]
`define root_x(i, j, k) roots[ADDRESS_WIDTH*`INDEX(i, j, k)+PER_DIM_WIDTH +: PER_DIM_WIDTH]
`define root_y(i, j, k) roots[ADDRESS_WIDTH*`INDEX(i, j, k) +: PER_DIM_WIDTH]
`define root_z(i, j, k) roots[ADDRESS_WIDTH*`INDEX(i, j, k)+(2*PER_DIM_WIDTH) +: PER_DIM_WIDTH]
`define PU(i, j, k) decoder.decoder.pu_k[k].pu_i[i].pu_j[j].u_processing_unit

wire result_valid;
wire [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;

// instantiate
Helios_single_FPGA #(
    .CODE_DISTANCE_X(CODE_DISTANCE_X),
    .CODE_DISTANCE_Z(CODE_DISTANCE_Z),
    .WEIGHT_X(WEIGHT_X),
    .WEIGHT_Z(WEIGHT_Z),
    .WEIGHT_M(WEIGHT_M)
 ) decoder (
    .clk(clk),
    .reset(reset),
    .new_round_start(new_round_start),
    .measurements(measurements),
    .roots(roots),
    .result_valid(result_valid),
    .iteration_counter(iteration_counter),
    .cycle_counter(cycle_counter),
    .global_stage()
);

function [ADDRESS_WIDTH-1:0] make_address;
input [PER_DIM_WIDTH-1:0] i;
input [PER_DIM_WIDTH-1:0] j;
input [PER_DIM_WIDTH-1:0] k;
begin
    make_address = { k, i, j };
end
endfunction

always #5 clk = ~clk;  // flip every 5ns, that is 100MHz clock

reg valid_delayed = 0;
integer i;
integer j;
integer k;
integer file, input_file;
reg open = 1;
reg input_open = 1;
reg eof = 0;
reg input_eof = 0;
reg [31:0] read_value, test_case, input_read_value;
reg [PER_DIM_WIDTH-1 : 0] expected_x, expected_y, expected_z;
reg test_fail;
reg processing = 0;
reg [31:0] syndrome_count;
reg [31:0] pass_count = 0;
reg [31:0] fail_count = 0;
reg [31:0] total_count;

// Input loading logic
always @(negedge clk) begin
    if (!processing && !reset) begin
        measurements = 0;
        if(input_open == 1) begin
            if (CODE_DISTANCE == 3) begin
                input_file = $fopen ("/home/heterofpga/Desktop/qec_hardware/test_benches/test_data/input_data_3.txt", "r");
            end else if (CODE_DISTANCE == 5) begin
                input_file = $fopen ("/home/heterofpga/Desktop/qec_hardware/test_benches/test_data/input_data_5.txt", "r");
            end else if (CODE_DISTANCE == 7) begin
                input_file = $fopen ("/home/heterofpga/Desktop/qec_hardware/test_benches/test_data/input_data_7.txt", "r");
            end else if (CODE_DISTANCE == 9) begin
                input_file = $fopen ("/home/heterofpga/Desktop/qec_hardware/test_benches/test_data/input_data_9.txt", "r");
            end else if (CODE_DISTANCE == 11) begin
                input_file = $fopen ("/home/heterofpga/Desktop/qec_hardware/test_benches/test_data/input_data_11.txt", "r");
            end else if (CODE_DISTANCE == 13) begin
                input_file = $fopen ("/home/heterofpga/Desktop/qec_hardware/test_benches/test_data/input_data_13.txt", "r");
            end
            input_open = 0;
        end
        if (input_eof == 0)begin 
            $fscanf (input_file, "%h\n", input_read_value);
            input_eof = $feof(input_file);
            if (input_eof == 0)begin 
                new_round_start = 1;
                processing = 1;
                syndrome_count = 0;
            end
        end
        for (k=0 ;k <CODE_DISTANCE; k++) begin
            for (i=0 ;i <CODE_DISTANCE; i++) begin
                for (j=0 ;j <CODE_DISTANCE - 1; j++) begin
                    if (input_eof == 0)begin 
                        $fscanf (input_file, "%h\n", input_read_value);
                        `measurements(i, j, k) = input_read_value;
                        if (input_read_value == 1) begin
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
    if (!valid_delayed && result_valid) begin
        processing = 0;
        if(open == 1) begin
            if (CODE_DISTANCE == 3) begin
                file = $fopen ("/home/heterofpga/Desktop/qec_hardware/test_benches/test_data/output_data_3.txt", "r");
            end else if (CODE_DISTANCE == 5) begin
                file = $fopen ("/home/heterofpga/Desktop/qec_hardware/test_benches/test_data/output_data_5.txt", "r");
            end else if (CODE_DISTANCE == 7) begin
                file = $fopen ("/home/heterofpga/Desktop/qec_hardware/test_benches/test_data/output_data_7.txt", "r");
            end else if (CODE_DISTANCE == 9) begin
                file = $fopen ("/home/heterofpga/Desktop/qec_hardware/test_benches/test_data/output_data_9.txt", "r");
            end else if (CODE_DISTANCE == 11) begin
                file = $fopen ("/home/heterofpga/Desktop/qec_hardware/test_benches/test_data/output_data_11.txt", "r");
            end else if (CODE_DISTANCE == 13) begin
                file = $fopen ("/home/heterofpga/Desktop/qec_hardware/test_benches/test_data/output_data_13.txt", "r");
            end 
            open = 0;
        end
        if (eof == 0)begin 
            $fscanf (file, "%h\n", test_case);
            test_fail = 0;
            eof = $feof(file);
        end
        for (k=0 ;k <CODE_DISTANCE; k++) begin
            for (i=0 ;i <CODE_DISTANCE; i++) begin
                for (j=0 ;j <CODE_DISTANCE - 1; j++) begin
                    if (eof == 0)begin 
                        $fscanf (file, "%h\n", read_value);
                        expected_y = read_value[PER_DIM_WIDTH - 1:0];
                        expected_x = read_value[PER_DIM_WIDTH - 1 + 8 :8];
                        expected_z = read_value[PER_DIM_WIDTH - 1 + 16 :16];
                        eof = $feof(file);
                        if (result_valid) begin
                            if (expected_x != `root_x(i, j, k) || expected_y != `root_y(i, j, k) || expected_z != `root_z(i, j, k)) begin
                                $display("%t\t Root(%0d,%0d,%0d) = (%0d,%0d,%0d) : Expected (%0d,%0d,%0d)" , $time, k, i ,j, `root_z(i, j, k), `root_x(i, j, k), `root_y(i, j, k), expected_z, expected_x, expected_y);
                                test_fail = 1;
                            end
                        end
                    end
                end
            end
        end
        if (!test_fail) begin
            $display("%t\tTest case %d pass %d cycles %d iterations %d syndromes", $time, test_case, cycle_counter, iteration_counter, syndrome_count);
            pass_count = pass_count + 1;
        end else begin
            $display("%t\tTest case %d fail %d cycles %d iterations %d syndromes", $time, test_case, cycle_counter, iteration_counter, syndrome_count);
            fail_count = fail_count + 1;
            $finish;
        end
    end
    if (input_eof == 1)begin
        total_count = pass_count + fail_count;
        $display("%t\t Done:", $time);
        $display("Total : %d",total_count);
        $display("Passed : %d",pass_count);
        $display("Failed : %d",fail_count);
        $finish;
    end
end

always@(posedge clk) begin
    valid_delayed <= result_valid;
end

initial begin
    clk = 1'b1;
    reset = 1'b1;

    #107;
    reset = 1'b0;
    #100;


end


endmodule
