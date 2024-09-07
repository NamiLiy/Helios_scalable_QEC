module message_handler #(
    parameter GT_FIFO_SIZE = 64,
    parameter FPGA_ID = 1    
) (
    clk,
    reset,

    in_data,
    in_valid,
    in_ready,

    out_data,
    out_valid,
    out_ready,

    control_to_handler_data,
    control_to_handler_valid,
    control_to_handler_ready,

    handler_to_control_data,
    handler_to_control_valid,
    handler_to_control_ready,

    router_busy
);

`include "../../parameters/parameters.sv"

    input clk;
    input reset;

    input [GT_FIFO_SIZE-1 : 0] in_data;
    input in_valid;
    output reg in_ready;

    output reg [GT_FIFO_SIZE-1 : 0] out_data;
    output reg out_valid;
    input out_ready;

    input [GT_FIFO_SIZE-1:0] control_to_handler_data;
    input control_to_handler_valid;
    output reg control_to_handler_ready;

    output reg [GT_FIFO_SIZE-1:0] handler_to_control_data;
    output reg handler_to_control_valid;
    input handler_to_control_ready;
    
    output router_busy;

    assign router_busy = 1'b0;


    always@(*) begin
        out_data  = control_to_handler_data;
        out_valid = 1'b0;
        control_to_handler_ready = 1'b0;
        if (out_ready) begin
            out_valid = control_to_handler_valid;
            out_data  = control_to_handler_data;
            control_to_handler_ready = 1'b1;
        end 
    end

    always@(*) begin
        handler_to_control_data = in_data;
        handler_to_control_valid = 1'b0;
        in_ready = 1'b0;
        if(in_valid) begin
            if(in_data[MSG_DEST_MSB:MSG_DEST_LSB] == 8'hff || in_data[MSG_DEST_MSB:MSG_DEST_LSB] == FPGA_ID) begin
                handler_to_control_valid = 1'b1;
                in_ready = handler_to_control_ready;
            end
        end
    end

endmodule