module rand_gen_top #(
    parameter CODE_DISTANCE_X = 5,
    parameter CODE_DISTANCE_Z = 4
) (
    clk,
    reset,
    next,
    measurement_values
);

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;

input clk;
input reset;
input next;
output [PU_COUNT - 1 : 0] measurement_values;

genvar i;
genvar j;
genvar k;

`define HOR_INDEX(i, j) i*(CODE_DISTANCE_Z + 1) + j
`define VER_INDEX(i, j) i*(CODE_DISTANCE_X + 1) + j + CODE_DISTANCE_X*(CODE_DISTANCE_Z + 1)
`define MEASURE_INDEX(i,j) i*CODE_DISTANCE_Z + j + CODE_DISTANCE_X*(CODE_DISTANCE_Z + 1) + (CODE_DISTANCE_X-1)*CODE_DISTANCE_Z
`define INDEX(i, j, k) (i * CODE_DISTANCE_Z + j + k * CODE_DISTANCE_Z*CODE_DISTANCE_X)

localparam logic [63:0] s0[CODE_DISTANCE_X*(CODE_DISTANCE_Z + 1) + (CODE_DISTANCE_X-1)*CODE_DISTANCE_Z + CODE_DISTANCE_X*CODE_DISTANCE_Z + 1] = {/*$$S0_ARRAY*/};
localparam logic [63:0] s1[CODE_DISTANCE_X*(CODE_DISTANCE_Z + 1) + (CODE_DISTANCE_X-1)*CODE_DISTANCE_Z + CODE_DISTANCE_X*CODE_DISTANCE_Z + 1] = {/*$$S1_ARRAY*/};


generate
    for (i=0; i < CODE_DISTANCE_X; i=i+1) begin: m_i_horizontal_lines
        for (j=0; j <= CODE_DISTANCE_Z; j=j+1) begin: m_j
            wire [MEASUREMENT_ROUNDS - 1 : 0] measurement_values;
            error_stream #(.MEASUREMENT_ROUNDS(MEASUREMENT_ROUNDS)) es(
                .s0_initial(s0[`HOR_INDEX(i,j)]),
                .s1_initial(s1[`HOR_INDEX(i,j)]),
                .update_errors(next),
                .update_valid(),
                .error_stream(measurement_values),
                .clk(clk),
                .reset(reset)
            );
        end
    end

    for (i=0; i < CODE_DISTANCE_Z; i=i+1) begin: m_i_vertical_lines
        for (j=0; j <= CODE_DISTANCE_X; j=j+1) begin: m_j
            wire [MEASUREMENT_ROUNDS - 1 : 0] measurement_values;
            if(j > 0 && j < CODE_DISTANCE_X) begin
                error_stream #(.MEASUREMENT_ROUNDS(MEASUREMENT_ROUNDS)) es(
                    .s0_initial(s0[`VER_INDEX(i,j)]),
                    .s1_initial(s1[`VER_INDEX(i,j)]),
                    .update_errors(next),
                    .update_valid(),
                    .error_stream(measurement_values),
                    .clk(clk),
                    .reset(reset)
                );
            end else begin
                assign measurement_values = {MEASUREMENT_ROUNDS{1'b0}};
            end
        end
    end

    for (i=0; i < CODE_DISTANCE_X; i=i+1) begin: m_i_measurement_lines
        for (j=0; j < CODE_DISTANCE_Z; j=j+1) begin: m_j
            wire [MEASUREMENT_ROUNDS  : 0] measurement_values;
            error_stream #(.MEASUREMENT_ROUNDS(MEASUREMENT_ROUNDS)) es(
                .s0_initial(s0[`MEASURE_INDEX(i,j)]),
                .s1_initial(s1[`MEASURE_INDEX(i,j)]),
                .update_errors(next),
                .update_valid(),
                .error_stream(measurement_values[MEASUREMENT_ROUNDS - 1 : 1]),
                .clk(clk),
                .reset(reset)
            );
            assign measurement_values[0] = 1'b0;
            assign measurement_values[MEASUREMENT_ROUNDS] = 1'b0;
        end
    end

endgenerate

generate
    for (k=0; k < MEASUREMENT_ROUNDS; k=k+1) begin: pu_k
        for (i=0; i < CODE_DISTANCE_X; i=i+1) begin: pu_i
            for (j=0; j < CODE_DISTANCE_Z; j=j+1) begin: pu_j
                assign measurement_values[`INDEX(i, j, k)] = 
                    m_i_horizontal_lines[i].m_j[j].measurement_values[k]^
                    m_i_horizontal_lines[i].m_j[j+1].measurement_values[k]^
                    m_i_vertical_lines[j].m_j[i].measurement_values[k]^
                    m_i_vertical_lines[j].m_j[i+1].measurement_values[k]^
                    m_i_measurement_lines[i].m_j[j].measurement_values[k]^
                    m_i_measurement_lines[i].m_j[j].measurement_values[k+1];
            end
        end
    end
endgenerate

endmodule
    
