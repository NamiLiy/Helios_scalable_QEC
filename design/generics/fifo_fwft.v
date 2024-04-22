module fifo_fwft #(
    parameter DEPTH     = 16,       // FIFO depth, must be power of 2
    parameter WIDTH     = 4         // FIFO width in bits
    ) (
    input  wire             clk,
    input wire srst,
    // FIFO inputs interface
    input  wire             wr_en,
    input  wire [WIDTH-1:0] din,
    output wire             full,
    // FIFO output interface
    output wire             empty,
    output wire [WIDTH-1:0] dout,
    input  wire             rd_en
    );
    
    /* A very temporary fix to test size 1 FIFO //*/
    
    /*
    reg  [WIDTH-1:0] fifo;
    wire in_ready;
    wire out_valid;
    reg count;
    
    always @(posedge clk) begin
        if (srst) begin
            count <= 0;
        end else begin
            if (wr_en & in_ready & out_valid & rd_en) begin
                count <= count;
            end else if (wr_en & in_ready) begin
                count <= 1;
            end else if (out_valid & rd_en) begin
                count <= 0;
            end
        end
    end
    
    always @(posedge clk) begin
        if (srst) begin
            ;
        end else begin
            if (wr_en & in_ready) begin
                fifo <= din;
            end
        end
    end
    
    assign out_valid = count == 1;
    assign in_ready = count == 0;

    assign dout = fifo;
    assign full = !in_ready;
    assign empty = !out_valid;
    
    
    //*/
    
    
    // Instantiate FIFO indexes
    localparam PW = $clog2(DEPTH);
    reg  [PW-1:0]   head;   // Data is dequeued from the head
    reg  [PW-1:0]   tail;   // Data is enqueued at the tail
    wire  [PW-1:0]   tail_plus_one;   // Data is enqueued at the tail

    wire in_ready;
    wire out_valid;
    
    // Define the FIFO buffer
    reg  [WIDTH-1:0] fifo [0:DEPTH-1];
    reg [PW:0] count = 0;

    always @(posedge clk) begin
        if (srst) begin
            count <= 0;
        end else begin
            if (wr_en & in_ready & out_valid & rd_en) begin
                count <= count;
            end else if (wr_en & in_ready) begin
                count <= count + 1;
            end else if (out_valid & rd_en) begin
                count <= count - 1;
            end
        end
    end

    // Control data input to the FIFO

    always @(posedge clk) begin
        if (srst) begin
            tail <= 0;
        end else begin
            if (wr_en & in_ready) begin
                tail <= tail + 1;
                fifo[tail] <= din;
            end
        end
    end

    always @(posedge clk) begin
        if (srst) begin
            head <= 0;
        end else begin
            if (rd_en & out_valid) begin
                head <= head + 1;
            end
        end
    end
    
    // Control data output from the FIFO
    assign out_valid = head != tail;
    assign tail_plus_one = tail + 1;
    assign in_ready = tail_plus_one != head;

    assign dout = fifo[head];
    assign full = !in_ready;
    assign empty = !out_valid;
    
    // */

endmodule

module fifo_wrapper #(
    parameter DEPTH     = 16,       // FIFO depth, must be power of 2
    parameter WIDTH     = 4         // FIFO width in bits
    ) (
    input  wire             clk,
    input wire reset,

    // Input interface
    input wire              input_valid,
    output wire             input_ready,
    input  wire [WIDTH-1:0] input_data,

    // Output interface
    output wire             output_valid,
    input  wire             output_ready,
    output wire [WIDTH-1:0] output_data
);

    wire wr_en;
    wire rd_en;
    wire [WIDTH-1:0] din;
    wire [WIDTH-1:0] dout;
    wire full;
    wire empty;

    fifo_fwft #(.DEPTH(DEPTH), .WIDTH(WIDTH)) fifo_inst (
        .clk(clk),
        .srst(reset),
        .wr_en(wr_en),
        .din(din),
        .full(full),
        .empty(empty),
        .dout(dout),
        .rd_en(rd_en)
    );

    assign input_ready = ~full;
    assign output_valid = ~empty;
    assign din = input_data;
    assign wr_en = input_valid;
    assign output_data = dout;
    assign rd_en = output_ready;

endmodule

module fifo_wrapper_with_delay #(
    parameter DEPTH     = 16,       // FIFO depth, must be power of 2
    parameter WIDTH     = 4,         // FIFO width in bits
    parameter DELAY     = 1
    ) (
    input  wire             clk,
    input wire reset,

    // Input interface
    input wire              input_valid,
    output wire             input_ready,
    input  wire [WIDTH-1:0] input_data,

    // Output interface
    output reg             output_valid,
    input  wire             output_ready,
    output wire [WIDTH-1:0] output_data
);

    localparam TIME_WIDTH = 32;
    reg [TIME_WIDTH-1:0] current_time;
    
    always @(posedge clk) begin
        if (reset) begin
            current_time <= 0;
        end else begin
            //if(~input_valid && ~output_valid_received) begin //we can reset the timer when fifos are empty
            //    current_time <= 0;
            // end else begin
                current_time <= current_time + 1;
            // end
        end
    end

    wire [TIME_WIDTH-1:0] received_time;
    wire output_valid_received;
    reg output_ready_received;

    fifo_wrapper #(.DEPTH(DEPTH), .WIDTH(WIDTH+TIME_WIDTH)) fifo_inst (
        .clk(clk),
        .reset(reset),
        .input_valid(input_valid),
        .input_ready(input_ready),
        .input_data({input_data, current_time}),
        .output_valid(output_valid_received),
        .output_ready(output_ready_received),
        .output_data({output_data, received_time})
    );

    always@(*) begin
        if(received_time + DELAY <= current_time) begin
            output_valid = output_valid_received;
            output_ready_received = output_ready;
        end else begin
            output_valid = 0;
            output_ready_received = 0;
        end
    end

endmodule
