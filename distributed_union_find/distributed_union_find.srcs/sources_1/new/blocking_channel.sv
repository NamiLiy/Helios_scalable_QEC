`timescale 1ns / 1ps

module blocking_channel #(
    parameter WIDTH = 8  // width of data
) (
    input [WIDTH-1:0] in_data,
    input in_valid,
    output in_is_full,
    output [WIDTH-1:0] out_data,
    output out_valid,
    input out_is_taken,
    input clk,
    input reset,
    input initialize
);

// Temporary code to convert the blocking channel to fwft fifo

wire empty;
assign out_valid = !empty;

fifo_fwft #(.DEPTH(16), .WIDTH(WIDTH)) temp_fifo 
    (
    .clk(clk),
    .srst(initialize | reset),
    .wr_en(in_valid),
    .din(in_data),
    .full(in_is_full),
    .empty(empty),
    .dout(out_data),
    .rd_en(out_is_taken)
);

// old code

// // Nami : Improved this by converting to a ping-pong buffer.
// // Supports 1 message / clock without long combinational path
// // old comments : 
// // current implementation doesn't support 1 message / clock, it only supports 1 message / 2 clock cycles
// // improve this later but keep the same interface
// // the challenge here is that `in_is_full` should not be a combinational logic based on `out_is_taken`
// // otherwise multiple processing units could have a super long path of dependency, making the clock rate of the system scaling down with code distance



// reg [WIDTH-1:0] buffer_data_a;
// reg buffer_valid_a;
// reg [WIDTH-1:0] buffer_data_b;
// reg buffer_valid_b;
// reg selected_read_reg;
// reg selected_write_reg;

// assign out_data = selected_read_reg ? buffer_data_b : buffer_data_a;
// assign out_valid = selected_read_reg ? buffer_valid_b : buffer_valid_a;
// assign in_is_full = selected_write_reg ? buffer_valid_b : buffer_valid_a;

// always @(posedge clk) begin
//     if (reset) begin
//         buffer_valid_a <= 0;
//     end else begin
//         if (initialize) begin
//             buffer_valid_a <= 0;
//         end else if (buffer_valid_a) begin  // do not take input data
//             if (out_is_taken && !selected_read_reg) begin
//                 buffer_valid_a <= 0;
//             end
//         end else begin
//             if(!selected_write_reg) begin
//                 buffer_valid_a <= in_valid;
//                 buffer_data_a <= in_data;
//             end
//         end
//     end
// end

// always @(posedge clk) begin
//     if (reset) begin
//         buffer_valid_b <= 0;
//     end else begin
//         if (initialize) begin
//             buffer_valid_b <= 0;
//         end else if (buffer_valid_b) begin  // do not take input data
//             if (out_is_taken && selected_read_reg) begin
//                 buffer_valid_b <= 0;
//             end
//         end else begin
//             if(selected_write_reg) begin
//                 buffer_valid_b <= in_valid;
//                 buffer_data_b <= in_data;
//             end
//         end
//     end
// end

// always @(posedge clk) begin
//     if (reset) begin
//         selected_read_reg <= 0;
//     end else begin
//         if (initialize) begin
//             selected_read_reg <= 0;
//         end else if (selected_read_reg) begin
//             if (buffer_valid_b && out_is_taken) begin  // do not take input data
//                 selected_read_reg <= 0;
//             end
//         end else begin
//             if (buffer_valid_a && out_is_taken) begin  // do not take input data
//                 selected_read_reg <= 1;
//             end
//         end
//     end
// end

// always @(posedge clk) begin
//     if (reset) begin
//         selected_write_reg <= 0;
//     end else begin
//         if (initialize) begin
//             selected_write_reg <= 0;
//         end else if (selected_write_reg) begin
//             if (!buffer_valid_b && in_valid) begin  // do not take input data
//                 selected_write_reg <= 0;
//             end
//         end else begin
//             if (!buffer_valid_a && in_valid) begin  // do not take input data
//                 selected_write_reg <= 1;
//             end
//         end
//     end
// end

endmodule
