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

/* module fifo_fwft #(
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

    // Instantiate FIFO indexes
    localparam PW = $clog2(DEPTH);
    reg  [PW-1:0]   head;   // Data is dequeued from the head
    reg  [PW-1:0]   tail;   // Data is enqueued at the tail

    wire in_ready;
    wire out_valid;
    
    // Define the FIFO buffer
    reg  [WIDTH-1:0] fifo [0:DEPTH-1];

    reg [WIDTH-1:0] special_reg_output;
    reg [WIDTH-1:0] special_reg_input;
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
        if (count == 0) begin
            if (wr_en & in_ready) begin
                special_reg_output <= din;
            end
            tail <= 0;
            head <= 0;
        end else if (count == 1) begin
            if(wr_en & in_ready && out_valid & rd_en) begin
                special_reg_output <= din;
            end else if(wr_en & in_ready) begin
                special_reg_input <= din;
            end
        end else if (count == 2) begin
            if(wr_en & in_ready && out_valid & rd_en) begin
                special_reg_output <= special_reg_input;
                special_reg_input <= din;
            end else if(wr_en & in_ready) begin
                special_reg_input <= din;
                fifo[tail] <= special_reg_input;
                tail <= tail + 1;
            end else if (out_valid & rd_en) begin
                special_reg_output <= special_reg_input;
            end
        end else begin
            if(wr_en & in_ready && out_valid & rd_en) begin
                special_reg_output <= fifo[head];
                head <= head + 1;
                fifo[tail] <= special_reg_input;
                tail <= tail + 1;
                special_reg_input <= din;
            end else if(wr_en & in_ready) begin
                special_reg_input <= din;
                fifo[tail] <= special_reg_input;
                tail <= tail + 1;
            end else if (out_valid & rd_en) begin
                special_reg_output <= fifo[head];
                head <= head + 1;
            end
        end
    end

    // Control data output from the FIFO
    assign out_valid = count == 0 ? 0 : 1;
    assign in_ready = (tail + 1) != head;

    assign dout = special_reg_output;
    assign full = !in_ready;
    assign empty = !out_valid;

endmodule */