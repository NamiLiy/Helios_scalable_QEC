`timescale 1ns / 10ps

module test_tree_compare_solver;

`define assert(condition, reason) if(!condition) begin $display(reason); $finish(1); end

localparam DATA_WIDTH = 8;
localparam CHANNEL_COUNT = 5;
reg [DATA_WIDTH-1:0] default_value;
reg [DATA_WIDTH-1:0] value_1;
reg [DATA_WIDTH-1:0] value_2;
reg [DATA_WIDTH-1:0] value_3;
reg [DATA_WIDTH-1:0] value_4;
reg [DATA_WIDTH-1:0] value_5;
reg valid_1;
reg valid_2;
reg valid_3;
reg valid_4;
reg valid_5;
wire [DATA_WIDTH-1:0] result;

// instantiate
tree_compare_solver #(.DATA_WIDTH(DATA_WIDTH), .CHANNEL_COUNT(CHANNEL_COUNT)) u_tree_compare_solver(
    .default_value(default_value),
    .values({value_5, value_4, value_3, value_2, value_1}),
    .valids({valid_5, valid_4, valid_3, valid_2, valid_1}),
    .result(result)
);

initial begin
    default_value = 'h33;
    valid_1 = 0;
    valid_2 = 0;
    valid_3 = 0;
    valid_4 = 0;
    valid_5 = 0;
    #20;
    
    // start test
    `assert(result == 'h33, "default value");
    
    valid_1 = 1;
    value_1 = 'h22;
    #20;
    `assert(result == 'h22, "smallest among all");
    
    value_1 = 'h44;
    #20;
    `assert(result == 'h33, "smallest among all");
    
    valid_1 = 1;
    valid_3 = 1;
    valid_5 = 1;
    value_1 = 'h44;
    value_3 = 'h11;
    value_5 = 'h88;
    #20;
    `assert(result == 'h11, "smallest among all");
    
    valid_1 = 0;
    valid_3 = 0;
    valid_5 = 1;
    value_1 = 'h44;
    value_3 = 'h11;
    value_5 = 'h88;
    default_value = 'hAA;
    #20;
    `assert(result == 'h88, "smallest among all");
    
    valid_1 = 1;
    valid_2 = 1;
    valid_3 = 1;
    valid_4 = 1;
    valid_5 = 1;
    value_1 = 'hFF;
    value_2 = 'hFE;
    value_3 = 'hFD;
    value_4 = 'hFC;
    value_5 = 'hFB;
    default_value = 'hFF;
    #20;
    `assert(result == 'hFB, "smallest among all");
    
    valid_1 = 0;
    valid_2 = 0;
    valid_3 = 0;
    valid_4 = 0;
    valid_5 = 0;
    #20;
    `assert(result == 'hFF, "smallest among all");

end

endmodule
