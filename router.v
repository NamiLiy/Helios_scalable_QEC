module router
(
    clk,
    reset, 
    mailbox_north_value_in,
    mailbox_north_valid_in,
    mailbox_north_ready_out,
    mailbox_east_value_in,
    mailbox_east_valid_in,
    mailbox_east_ready_out,
    mailbox_west_value_in,
    mailbox_west_valid_in,
    mailbox_west_ready_out,
    mailbox_south_value_in,
    mailbox_south_valid_in,
    mailbox_south_ready_out,
    mailbox_self_value_in,
    mailbox_self_valid_in,
    mailbox_self_ready_out,
    outqueue_north_value_out,
    outqueue_north_valid_out,
    outqueue_north_ready_in,
    outqueue_east_value_out,
    outqueue_east_valid_out,
    outqueue_east_ready_in,
    outqueue_west_value_out,
    outqueue_west_valid_out,
    outqueue_west_ready_in,
    outqueue_south_value_out,
    outqueue_south_valid_out,
    outqueue_south_ready_in,
    outqueue_self_value_out,
    outqueue_self_valid_out,
    outqueue_self_ready_in,
    ROW_ID,
    COL_ID
    
);

`include "parameters.v"

input [CORDINATE_WIDTH - 1:0] ROW_ID;
input [CORDINATE_WIDTH - 1:0] COL_ID;

input clk;
input reset; 
input [MSG_WIDTH -1 : 0] mailbox_north_value_in;
input mailbox_north_valid_in;
output mailbox_north_ready_out;
input [MSG_WIDTH -1 : 0] mailbox_east_value_in;
input mailbox_east_valid_in;
output mailbox_east_ready_out;
input [MSG_WIDTH -1 : 0] mailbox_west_value_in;
input mailbox_west_valid_in;
output mailbox_west_ready_out;
input [MSG_WIDTH -1 : 0] mailbox_south_value_in;
input mailbox_south_valid_in;
output mailbox_south_ready_out;
input [MSG_WIDTH -1 : 0] mailbox_self_value_in;
input mailbox_self_valid_in;
output mailbox_self_ready_out;
output reg [MSG_WIDTH -1 : 0] outqueue_north_value_out;
output reg outqueue_north_valid_out;
input outqueue_north_ready_in;
output reg [MSG_WIDTH -1 : 0] outqueue_east_value_out;
output reg outqueue_east_valid_out;
input outqueue_east_ready_in;
output reg [MSG_WIDTH -1 : 0] outqueue_west_value_out;
output reg outqueue_west_valid_out;
input outqueue_west_ready_in;
output reg [MSG_WIDTH -1 : 0] outqueue_south_value_out;
output reg outqueue_south_valid_out;
input outqueue_south_ready_in;
output reg [MSG_WIDTH -1 : 0] outqueue_self_value_out;
output reg outqueue_self_valid_out;
input outqueue_self_ready_in;

wire north_full;
wire south_full;
wire east_full;
wire west_full;
wire self_full;

wire north_empty;
wire south_empty;
wire east_empty;
wire west_empty;
wire self_empty;

reg north_read_en;
reg south_read_en;
reg east_read_en;
reg west_read_en;
reg self_read_en;

wire [MSG_WIDTH -1 : 0] mailbox_north_value;
wire [MSG_WIDTH -1 : 0] mailbox_south_value;
wire [MSG_WIDTH -1 : 0] mailbox_east_value;
wire [MSG_WIDTH -1 : 0] mailbox_west_value;
wire [MSG_WIDTH -1 : 0] mailbox_self_value;

reg [MSG_WIDTH - 1 : 0] next_msg_to_process;
reg next_msg_valid;

assign mailbox_north_ready_out = ~north_full;
assign mailbox_south_ready_out = ~south_full;
assign mailbox_east_ready_out = ~east_full;
assign mailbox_west_ready_out = ~west_full;
assign mailbox_self_ready_out = ~self_full;

fifo_fwft #(.DEPTH(FIFO_DEPTH), .WIDTH(MSG_WIDTH)) north_fifo(
  .clk(clk),
  .srst(reset),
  .din(mailbox_north_value_in),
  .wr_en(mailbox_north_valid_in),
  .rd_en(north_read_en),
  .dout(mailbox_north_value),
  .full(north_full),
  .empty(north_empty)
);

fifo_fwft #(.DEPTH(FIFO_DEPTH), .WIDTH(MSG_WIDTH))  south_fifo(
  .clk(clk),
  .srst(reset),
  .din(mailbox_south_value_in),
  .wr_en(mailbox_south_valid_in),
  .rd_en(south_read_en),
  .dout(mailbox_south_value),
  .full(south_full),
  .empty(south_empty)
);

fifo_fwft #(.DEPTH(FIFO_DEPTH), .WIDTH(MSG_WIDTH)) east_fifo(
  .clk(clk),
  .srst(reset),
  .din(mailbox_east_value_in),
  .wr_en(mailbox_east_valid_in),
  .rd_en(east_read_en),
  .dout(mailbox_east_value),
  .full(east_full),
  .empty(east_empty)
);

fifo_fwft #(.DEPTH(FIFO_DEPTH), .WIDTH(MSG_WIDTH)) west_fifo(
  .clk(clk),
  .srst(reset),
  .din(mailbox_west_value_in),
  .wr_en(mailbox_west_valid_in),
  .rd_en(west_read_en),
  .dout(mailbox_west_value),
  .full(west_full),
  .empty(west_empty)
);

fifo_fwft #(.DEPTH(FIFO_DEPTH), .WIDTH(MSG_WIDTH)) self_fifo(
  .clk(clk),
  .srst(reset),
  .din(mailbox_self_value_in),
  .wr_en(mailbox_self_valid_in),
  .rd_en(self_read_en),
  .dout(mailbox_self_value),
  .full(self_full),
  .empty(self_empty)
);

// This logic is not optimized.
// TODO : Optimize this logic
always@(*) begin
    if (~self_empty) begin
        next_msg_valid = 1'b1;
        next_msg_to_process = mailbox_self_value;
    end else if (~north_empty) begin
        next_msg_valid = 1'b1;
        next_msg_to_process = mailbox_north_value;
    end else if (~south_empty) begin
        next_msg_valid = 1'b1;
        next_msg_to_process = mailbox_south_value;
    end else if (~east_empty) begin
        next_msg_valid = 1'b1;
        next_msg_to_process = mailbox_east_value;
    end else if (~west_empty) begin
        next_msg_valid= 1'b1;
        next_msg_to_process = mailbox_west_value;
    end else begin
        next_msg_valid= 1'b0;
        next_msg_to_process = mailbox_self_value;
    end
end

wire [CORDINATE_WIDTH-1:0] msg_row;
wire [CORDINATE_WIDTH-1:0] msg_col;

reg message_can_be_pushed;

assign {msg_row,msg_col} = {get_receiver_row(next_msg_to_process), get_receiver_col(next_msg_to_process)};

always@(*) begin
    outqueue_north_valid_out = 0;
    outqueue_south_valid_out = 0;
    outqueue_east_valid_out = 0;
    outqueue_west_valid_out = 0;
    outqueue_self_valid_out = 0;
    message_can_be_pushed = 0;
    if (next_msg_valid) begin
        if (msg_row == {(CORDINATE_WIDTH){1'b1}} && msg_col == {(CORDINATE_WIDTH){1'b1}} &&
        outqueue_north_ready_in == 1'b1 && outqueue_south_ready_in == 1'b1 && outqueue_west_ready_in == 1'b1 && outqueue_east_ready_in == 1'b1) begin
            outqueue_north_valid_out = 1;
            outqueue_south_valid_out = 1;
            outqueue_east_valid_out = 1;
            outqueue_west_valid_out = 1;
            message_can_be_pushed = 1;
        end else if(msg_row == ROW_ID && msg_col == COL_ID && outqueue_self_ready_in == 1'b1) begin
            outqueue_self_valid_out = 1;
            message_can_be_pushed = 1;
        end else if(msg_row < ROW_ID && outqueue_north_ready_in == 1'b1) begin
            outqueue_north_valid_out = 1;
            message_can_be_pushed = 1;
        end else if (msg_row > ROW_ID && outqueue_south_ready_in == 1'b1) begin
            outqueue_south_valid_out = 1;
            message_can_be_pushed = 1;
        end else if (msg_row == ROW_ID && msg_col > COL_ID && outqueue_east_ready_in == 1'b1) begin
            outqueue_east_valid_out = 1;
            message_can_be_pushed = 1;
        end else if (msg_row == ROW_ID && msg_col < COL_ID && outqueue_west_ready_in == 1'b1) begin
            outqueue_west_valid_out = 1;
            message_can_be_pushed = 1;
        end
    end
end


always@(*) begin
    if (msg_row == {(CORDINATE_WIDTH){1'b1}} && msg_col == {(CORDINATE_WIDTH){1'b1}}) begin
        outqueue_north_value_out = {cordinate_add(ROW_ID, -1), COL_ID, message_except_dest(next_msg_to_process)};
        outqueue_south_value_out = {cordinate_add(ROW_ID, 1), COL_ID, message_except_dest(next_msg_to_process)};
        outqueue_west_value_out = {ROW_ID, cordinate_add(COL_ID, -1),  message_except_dest(next_msg_to_process)};
        outqueue_east_value_out = {ROW_ID, cordinate_add(COL_ID, 1),  message_except_dest(next_msg_to_process)};
        outqueue_self_value_out = {(MSG_WIDTH){1'bx}};
    end else begin
        outqueue_north_value_out = next_msg_to_process;
        outqueue_south_value_out = next_msg_to_process;
        outqueue_west_value_out = next_msg_to_process;
        outqueue_east_value_out = next_msg_to_process;
        outqueue_self_value_out = next_msg_to_process;
    end
end

always@(*) begin
    north_read_en = 1'b0;
    south_read_en = 1'b0;
    east_read_en = 1'b0;
    west_read_en = 1'b0;
    self_read_en = 1'b0;
    if (message_can_be_pushed == 1'b1) begin
        if (~self_empty) begin
            self_read_en = 1'b1;
        end else if (~north_empty) begin
            north_read_en = 1'b1;
        end else if (~south_empty) begin
            south_read_en = 1'b1;
        end else if (~east_empty) begin
            east_read_en = 1'b1;
        end else if (~west_empty) begin
            west_read_en = 1'b1;
        end 
    end
    
end



function [CORDINATE_WIDTH-1:0] get_receiver_row;
    input [MSG_WIDTH-1 : 0] msg;
    begin
        get_receiver_row = msg [MSG_WIDTH -1 : CORDINATE_WIDTH*5 + COST_WIDTH + MAX_HOP_WIDTH + TIMESTAMP_WIDTH + MSG_TYPE_WIDTH];
    end
endfunction

function [CORDINATE_WIDTH-1:0] get_receiver_col;
    input [MSG_WIDTH-1 : 0] msg;
    begin
        get_receiver_col = msg [MSG_WIDTH -1 - CORDINATE_WIDTH : CORDINATE_WIDTH*4 + COST_WIDTH + MAX_HOP_WIDTH + TIMESTAMP_WIDTH + MSG_TYPE_WIDTH];
    end
endfunction

function [CORDINATE_WIDTH - 1:0] cordinate_add;
    input [CORDINATE_WIDTH-1 : 0] a, b;
    reg[31:0] y;
    begin
        y = a + b;
        cordinate_add = y [CORDINATE_WIDTH - 1:0];
    end
endfunction

function [MSG_WIDTH - CORDINATE_WIDTH - CORDINATE_WIDTH - 1:0] message_except_dest;
    input [MSG_WIDTH-1 : 0] msg;
    begin
        message_except_dest = msg [MSG_WIDTH - CORDINATE_WIDTH*2 -1 :0];
    end
endfunction

endmodule