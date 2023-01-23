// This module is tricky leave it to later

module get_boundry_cardinality #(
    parameter CODE_DISTANCE_X = 4,
    parameter CODE_DISTANCE_Z = 12,
    parameter BOUNDARY_TYPE = 0 // 0 for x boundary and 1 for z boundary
) (
    clk,
    reset,
    is_touching_boundaries,
    is_odd_cardinalities,
    roots,
    final_cardinality,
    go,
    done
);


`define MAX(a, b) (((a) > (b)) ? (a) : (b))

localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PER_DIMENSION_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
    

localparam BOUNDRY_PU_COUNT = CODE_DISTANCE_X * MEASUREMENT_ROUNDS;

`define INDEX(i, j, k) (i * (CODE_DISTANCE_Z) + j + k * (CODE_DISTANCE_Z)*CODE_DISTANCE_X)
`define CONVERT_TO_INDEX(root) `INDEX(root[PER_DIMENSION_WIDTH*2-1:PER_DIMENSION_WIDTH], root[PER_DIMENSION_WIDTH-1:0], root[PER_DIMENSION_WIDTH*3-1:PER_DIMENSION_WIDTH*2])
// `define roots(i, j, k) roots[ADDRESS_WIDTH*(`INDEX(i, j, k)+1)-1:ADDRESS_WIDTH*`INDEX(i, j, k)]
// `define k_index(value) (value / ((CODE_DISTANCE-1)*CODE_DISTANCE))
// `define i_index(value) ((value % ((CODE_DISTANCE-1)*CODE_DISTANCE)) / (CODE_DISTANCE-1))
// `define j_index(value) (value % (CODE_DISTANCE-1))

input clk;
input reset;
input [PU_COUNT-1:0] is_odd_cardinalities;
input [PU_COUNT-1:0] is_touching_boundaries;
input [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
output final_cardinality;
input go;
output reg done;


always@(posedge clk) begin
    if(reset) begin
        done <= 0;
    end else begin
        done <= go;
    end
end
assign final_cardinality = 1'b0;
// Temporarly disabling this for convenience
/*

reg [PU_COUNT-1:0] root_array; //indicating used PUs
reg [ADDRESS_WIDTH-1 :0] selected_PU;
reg [ADDRESS_WIDTH-1 :0] selected_root;
reg selected_root_valid;
reg [PER_DIMENSION_WIDTH-1:0] i_index;
reg [PER_DIMENSION_WIDTH-1:0] j_index;
reg [PER_DIMENSION_WIDTH-1:0] k_index;
reg [PER_DIMENSION_WIDTH-1:0] i_index_next;
reg [PER_DIMENSION_WIDTH-1:0] j_index_next;
reg [PER_DIMENSION_WIDTH-1:0] k_index_next;

reg [1:0] state;
reg [ADDRESS_WIDTH-1:0] count;
reg [1:0] process_delay;

always@(posedge clk) begin
    if(reset) begin
        state <= 0;
    end else begin
        if (state == 2'b0) begin
            if (go) begin
                state <= 2'b1;
            end
        end else if (state == 2'b1) begin
            if (i_index == CODE_DISTANCE_X - 2 && k_index == MEASUREMENT_ROUNDS - 1) begin
                state <= 2'b11;
            end
            process_delay <= 2'b11;
        end else if(state ==2'b11) begin
            process_delay <= process_delay - 1;
            if (process_delay == 0) begin
                state <= 2'b10;
            end
        end else if (state == 2'b10) begin
            state <= 2'b0;
        end
    end    
end

always@(*) begin
    if(i_index == CODE_DISTANCE_X - 1) begin
        i_index_next = 0;
    end else begin
        i_index_next = i_index + 1;
    end

    if(i_index == CODE_DISTANCE_X - 1) begin
        k_index_next = k_index + 1;
    end else begin
        k_index_next = k_index;
    end

    j_index_next = j_index;

end

always@(posedge clk) begin
    if(reset) begin
        i_index <= 0;
        j_index <= 0;
        k_index <= 0;
        selected_PU <= 0;
    end else begin
        if (state == 2'b0) begin
            i_index <= 0;
            j_index <= 0;
            k_index <= 0;
            selected_PU <= 0;
        end else if (state == 2'b1) begin
            i_index <= i_index_next;
            j_index <= j_index_next;
            k_index <= k_index_next;
            selected_PU <= `INDEX(i_index, j_index, k_index);
        end
    end    
end



// If a PU is touching the boundary you consider whether it's root is an odd cardinality
always@(posedge clk) begin
    if(reset) begin
        root_array <= 0;
        selected_root <= 0;
        selected_root_valid <= 0;
    end else begin
        if (go) begin
            root_array <= 0;
            selected_root <= 0;
            selected_root_valid <= 0;
        end else begin
            if(is_touching_boundaries[selected_PU]) begin
                selected_root <= roots[ADDRESS_WIDTH*selected_PU +: ADDRESS_WIDTH];
                selected_root_valid <= 1;
            end else begin
                selected_root_valid <= 0;
            end
            if(selected_root_valid) begin
                root_array[`CONVERT_TO_INDEX(selected_root)] <= is_odd_cardinalities[`CONVERT_TO_INDEX(selected_root)];
            end
        end
    end    
end

assign final_cardinality = ^root_array;
assign done = state==2'b10 ? 1 : 0;

//*/

endmodule


