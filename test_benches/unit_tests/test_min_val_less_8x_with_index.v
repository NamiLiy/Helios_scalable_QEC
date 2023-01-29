module min_val_less_8x_with_index_tb;

    localparam DATA_WIDTH = 8;
    localparam CHANNEL_COUNT = 6;
    reg [(DATA_WIDTH*CHANNEL_COUNT)-1:0] values;
    reg [CHANNEL_COUNT-1:0] valids;
    wire [DATA_WIDTH-1:0] result;
    wire [CHANNEL_COUNT-1:0] output_valids;

    min_val_less_8x_with_index  #(
        .DATA_WIDTH(DATA_WIDTH),
        .CHANNEL_COUNT(CHANNEL_COUNT)
    ) uut (
        .values(values),
        .valids(valids),
        .result(result),
        .output_valids(output_valids)
    );
    
    `define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: Expected %d : Actual %d", value, signal); \
            $finish; \
        end

    initial begin
        // Test case 1: Check minimum value of all valid inputs
        values = {8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06};
        valids = {1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1};
        #1;
        `assert(result, 8'h01)
        `assert(output_valids , 6'b100000)
        
        // Test case 2: Check minimum value of valid inputs with invalid inputs
        values = {8'h05, 8'h00, 8'hFF, 8'h04, 8'h03, 8'h02};
        valids = {1, 0, 0, 1, 1, 1};
        #1;
        `assert(result , 8'h02)
        `assert(output_valids , 6'b000001)

        // Test case 3: Check minimum value of only invalid inputs
        values = {8'h05, 8'h06, 8'hFF, 8'h04, 8'h03, 8'h02};
        valids = {0, 0, 0, 0, 0, 0};
        #1;
        `assert(output_valids , 0)

        // Add more test cases as needed
        $finish;
    end
endmodule
