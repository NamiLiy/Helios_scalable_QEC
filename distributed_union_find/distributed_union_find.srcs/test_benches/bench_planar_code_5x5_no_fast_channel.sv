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

module bench_planar_code_5x5_no_fast_channel;

`include "../sources_1/new/parameters.sv"
`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

localparam CODE_DISTANCE = 5;
localparam PU_COUNT = CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 2;
localparam DISTANCE_WIDTH = 1 + PER_DIMENSION_WIDTH;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

reg clk;
reg reset;
reg new_round_start = 0;

reg [PU_COUNT-1:0] is_error_syndromes;
wire [PU_COUNT-1:0] is_odd_cardinalities;
wire [31:0] cycle_counter;
wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
`define INDEX(i, j) (i * (CODE_DISTANCE-1) + j)
`define is_error_syndrome(i, j) is_error_syndromes[`INDEX(i, j)]
`define is_odd_cluster(i, j) decoder.is_odd_clusters[`INDEX(i, j)]
`define root(i, j) roots[ADDRESS_WIDTH*`INDEX(i, j) +: ADDRESS_WIDTH]
`define root_x(i, j) roots[ADDRESS_WIDTH*`INDEX(i, j)+PER_DIMENSION_WIDTH +: PER_DIMENSION_WIDTH]
`define root_y(i, j) roots[ADDRESS_WIDTH*`INDEX(i, j) +: PER_DIMENSION_WIDTH]
`define PU(i, j) decoder.decoder.pu_i[i].pu_j[j].u_processing_unit

wire result_valid;
wire [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;

// instantiate
standard_planar_code_2d_no_fast_channel_with_stage_controller #(.CODE_DISTANCE(CODE_DISTANCE)) decoder (
    .clk(clk),
    .reset(reset),
    .new_round_start(new_round_start),
    .is_error_syndromes(is_error_syndromes),
    .is_odd_cardinalities(is_odd_cardinalities),
    .roots(roots),
    .result_valid(result_valid),
    .iteration_counter(iteration_counter),
    .cycle_counter(cycle_counter)
);

function [ADDRESS_WIDTH-1:0] make_address;
input [PER_DIMENSION_WIDTH-1:0] i;
input [PER_DIMENSION_WIDTH-1:0] j;
begin
    make_address = { i, j };
end
endfunction

always #5 clk = ~clk;  // flip every 5ns, that is 100MHz clock

reg valid_delayed = 0;
integer i;
integer j;
integer file, input_file;
reg open = 1;
reg input_open = 1;
reg eof = 0;
reg input_eof = 0;
reg [31:0] read_value, test_case, input_read_value;
reg [PER_DIMENSION_WIDTH-1 : 0] expected_x, expected_y;
reg test_fail;
reg processing = 0;



// Input loading logic
always @(negedge clk) begin
    if (!processing && !reset) begin
        is_error_syndromes = 0;
        if(input_open == 1) begin
            input_file = $fopen ("/home/heterofpga/Desktop/qec_hardware/distributed_union_find/simulation_data/input_data.txt", "r");
            input_open = 0;
        end
        if (input_eof == 0)begin 
            $fscanf (input_file, "%h\n", input_read_value);
            input_eof = $feof(input_file);
            if (input_eof == 0)begin 
                new_round_start = 1;
                processing = 1;
            end
        end
        for (i=0 ;i <CODE_DISTANCE; i++) begin
            for (j=0 ;j <CODE_DISTANCE - 1; j++) begin
                if (input_eof == 0)begin 
                    $fscanf (input_file, "%h\n", input_read_value);
                    `is_error_syndrome(i, j) = input_read_value;
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
            file = $fopen ("/home/heterofpga/Desktop/qec_hardware/distributed_union_find/simulation_data/output_data.txt", "r");
            open = 0;
        end
        if (eof == 0)begin 
            $fscanf (file, "%h\n", test_case);
            test_fail = 0;
            eof = $feof(file);
        end
        for (i=0 ;i <CODE_DISTANCE; i++) begin
            for (j=0 ;j <CODE_DISTANCE - 1; j++) begin
                if (eof == 0)begin 
                    $fscanf (file, "%h\n", read_value);
                    expected_y = read_value[PER_DIMENSION_WIDTH - 1:0];
                    expected_x = read_value[PER_DIMENSION_WIDTH - 1 + 16 :16];
                    eof = $feof(file);
                    if (expected_x != `root_x(i, j) || expected_y != `root_y(i, j)) begin
                        $display("%t\t Root(%0d,%0d) = (%0d,%0d) : Expected (%0d,%0d)" , $time, i ,j, `root_x(i, j), `root_y(i, j), expected_x, expected_y);
                        test_fail = 1;
                    end
                end
            end
        end
        if (!test_fail) begin
            $display("%t\tTest case %d pass %d cycles", $time, test_case, cycle_counter);
        end else begin
            $display("%t\tTest case %d fail %d cycles ", $time, test_case, cycle_counter);
        end
    end
end

always@(posedge clk) begin
    valid_delayed <= result_valid;
end

initial begin
    clk = 1'b1;
    reset = 1'b1;
    // is_error_syndromes = 0;
    // Rust distributed_uf_decoder.rs: distributed_union_find_decoder_test_case_2()
    // `is_error_syndrome(1, 0) = 1;
    // `is_error_syndrome(1, 1) = 1;
    // `is_error_syndrome(1, 2) = 1;
    // `is_error_syndrome(1, 3) = 1;
    #107;
    reset = 1'b0;
    #100;
    // new_round_start = 1;
    // #10;
    // new_round_start = 0;
    // #500;
    // `assert(`root(0, 0) == make_address(0, 0), "root should be itself");
    // `assert(`root(1, 0) == make_address(1, 0), "root should be (1, 0)");
    // `assert(`root(1, 1) == make_address(1, 0), "root should be (1, 0)");
    // `assert(`root(1, 2) == make_address(1, 0), "root should be (1, 0)");
    // `assert(`root(1, 3) == make_address(1, 0), "root should be (1, 0)");
    // `assert(`root(2, 0) == make_address(2, 0), "root should be itself");
    // `assert(`is_odd_cluster(1, 0) == 0, "it's a even cluster");
    // `assert(result_valid, "decoder should terminate after 1us");
    // `assert(iteration_counter == 2, "this simple case should terminate after 2 iterations");
    
    
    // Rust distributed_uf_decoder.rs: distributed_union_find_decoder_test_case_3()
    // #10;
    // is_error_syndromes = 0;
    // `is_error_syndrome(0, 0) = 1;
    // `is_error_syndrome(0, 1) = 1;
    // `is_error_syndrome(0, 2) = 1;
    // `is_error_syndrome(1, 1) = 1;
    // `is_error_syndrome(1, 2) = 1;
    // #20;
    // new_round_start = 1;
    // #10;
    // new_round_start = 0;
    // #500;
    // `assert(`root(0, 0) == make_address(0, 0), "root should be (0, 0)");
    // `assert(`root(0, 1) == make_address(0, 0), "root should be (0, 0)");
    // `assert(`root(0, 2) == make_address(0, 0), "root should be (0, 0)");
    // `assert(`root(0, 3) == make_address(0, 0), "root should be (0, 0)");
    // `assert(`root(1, 0) == make_address(0, 0), "root should be (0, 0)");
    // `assert(`root(1, 1) == make_address(0, 0), "root should be (0, 0)");
    // `assert(`root(1, 2) == make_address(0, 0), "root should be (0, 0)");
    // `assert(`root(1, 3) == make_address(0, 0), "root should be (0, 0)");
    // `assert(`root(2, 0) == make_address(2, 0), "root should be itself");
    // `assert(`root(2, 1) == make_address(0, 0), "root should be (0, 0)");
    // `assert(`root(2, 2) == make_address(0, 0), "root should be (0, 0)");
    // `assert(`root(2, 3) == make_address(2, 3), "root should be itself");
    // `assert(`root(3, 0) == make_address(3, 0), "root should be itself");
    // `assert(`root(3, 1) == make_address(3, 1), "root should be itself");
    // `assert(`root(3, 2) == make_address(3, 2), "root should be itself");
    // `assert(`root(3, 3) == make_address(3, 3), "root should be itself");
    // `assert(`is_odd_cluster(0, 0) == 0, "it's a even cluster");
    // `assert(`PU(0, 0).is_touching_boundary == 1, "it's the root of a set that touching boundary");
    // `assert(result_valid, "decoder should terminate after 1000ns");
    // `assert(iteration_counter == 3, "this simple case should terminate after 3 iterations");

end


endmodule
