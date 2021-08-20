module pe
(
    clk,
    reset, 
    measurement_value_in,
    measurement_valid_in,
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
    match_value_out,
    start_offer,
    stop_offer,
    measurement,
    ROW_ID,
    COL_ID,
    BOUNDARY_COST
    
);

`include "parameters.v"

input [CORDINATE_WIDTH - 1:0] ROW_ID;
input [CORDINATE_WIDTH - 1:0] COL_ID;
input [COST_WIDTH - 1:0] BOUNDARY_COST;

input clk;
input reset; 
input measurement_value_in;
input measurement_valid_in;
input start_offer;
input stop_offer;
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
output [MSG_WIDTH -1 : 0] outqueue_north_value_out;
output outqueue_north_valid_out;
input outqueue_north_ready_in;
output [MSG_WIDTH -1 : 0] outqueue_east_value_out;
output outqueue_east_valid_out;
input outqueue_east_ready_in;
output [MSG_WIDTH -1 : 0] outqueue_west_value_out;
output outqueue_west_valid_out;
input outqueue_west_ready_in;
output [MSG_WIDTH -1 : 0] outqueue_south_value_out;
output outqueue_south_valid_out;
input outqueue_south_ready_in;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out;

output reg measurement;
reg [PROCESSING_STATE_WIDTH - 1:0] processing_state;
reg [PROCESSING_STATE_WIDTH - 1:0] processing_next_state;
reg [COST_WIDTH - 1:0] qubit_cost;
reg [QUBIT_STATE_WIDTH - 1 : 0] qubit_state;
reg [CORDINATE_WIDTH - 1:0] broker_next_hop_row;
reg [CORDINATE_WIDTH - 1:0] broker_next_hop_col;
reg broker_next_hop_valid;
reg [CORDINATE_WIDTH - 1:0] match_col;
reg [CORDINATE_WIDTH - 1:0] match_row;
reg [ACCEPT_PROB_WIDTH - 1:0] accept_probability;
reg [TIMESTAMP_WIDTH - 1 : 0] timestamp;

reg [MSG_WIDTH - 1 : 0] next_msg_to_process;
reg next_msg_valid;
reg read_next_msg;

wire [COST_WIDTH-1 : 0] msg_cost, cache_cost, loop_cache_cost;
reg [COST_WIDTH-1 : 0] cost_saved;
wire [TIMESTAMP_WIDTH - 1 : 0] msg_timestamp, cache_timestamp, loop_cache_timestamp;
wire cache_valid, loop_cache_valid;
wire [CORDINATE_WIDTH - 1:0] cache_row,cache_col, cache_broker_row, cache_broker_col, loop_cache_broker_row, loop_cache_broker_col;
reg [TIMESTAMP_WIDTH - 1 : 0] timestamp_saved;
reg [MSG_WIDTH - 1 : 0] msg_saved;
reg cache_write, loop_cache_write;

wire [MSG_WIDTH -1 : 0] msg_from_router;
wire valid_from_router;
reg ready_to_router;

reg [MSG_WIDTH -1 : 0] msg_to_router;
reg valid_to_router;
wire ready_from_router;

reg stage_1_valid;
reg [MSG_WIDTH -1 : 0] stage_1_msg, stage_2_msg;
reg stage_1_ready;
reg cache_valid_delayed;

reg [MSG_WIDTH -1 : 0] msg_to_cache;
reg [2*CORDINATE_WIDTH - 1 : 0] address_for_cache_write;
reg [CACHED_OFFER_WIDTH - 1 : 0] value_to_cache_write;
reg cache_writing_mode;
reg [2*CORDINATE_WIDTH : 0] cache_reset_acc;

router main_router
(
    .clk(clk),
    .reset(reset), 
    .mailbox_north_value_in(mailbox_north_value_in),
    .mailbox_north_valid_in(mailbox_north_valid_in),
    .mailbox_north_ready_out(mailbox_north_ready_out),
    .mailbox_east_value_in(mailbox_east_value_in),
    .mailbox_east_valid_in(mailbox_east_valid_in),
    .mailbox_east_ready_out(mailbox_east_ready_out),
    .mailbox_west_value_in(mailbox_west_value_in),
    .mailbox_west_valid_in(mailbox_west_valid_in),
    .mailbox_west_ready_out(mailbox_west_ready_out),
    .mailbox_south_value_in(mailbox_south_value_in),
    .mailbox_south_valid_in(mailbox_south_valid_in),
    .mailbox_south_ready_out(mailbox_south_ready_out),
    .mailbox_self_value_in(msg_to_router),
    .mailbox_self_valid_in(valid_to_router),
    .mailbox_self_ready_out(ready_from_router),
    .outqueue_north_value_out(outqueue_north_value_out),
    .outqueue_north_valid_out(outqueue_north_valid_out),
    .outqueue_north_ready_in(outqueue_north_ready_in),
    .outqueue_east_value_out(outqueue_east_value_out),
    .outqueue_east_valid_out(outqueue_east_valid_out),
    .outqueue_east_ready_in(outqueue_east_ready_in),
    .outqueue_west_value_out(outqueue_west_value_out),
    .outqueue_west_valid_out(outqueue_west_valid_out),
    .outqueue_west_ready_in(outqueue_west_ready_in),
    .outqueue_south_value_out(outqueue_south_value_out),
    .outqueue_south_valid_out(outqueue_south_valid_out),
    .outqueue_south_ready_in(outqueue_south_ready_in),
    .outqueue_self_value_out(msg_from_router),
    .outqueue_self_valid_out(valid_from_router),
    .outqueue_self_ready_in(ready_to_router),
    .ROW_ID(ROW_ID),
    .COL_ID(COL_ID)
    
);

///////////////////////////////////////////////////
// Output readout circuit
assign match_value_out =  (measurement == 1'b1) ? {match_row, match_col} : {(MATCH_VALUE_WIDTH){1'b1}};

// node_measurement
always @(posedge clk, posedge reset) begin
    if(reset) begin
        measurement <= 0;
    end
    else begin
        if (processing_state == State_waiting_from_readout) begin
            if (measurement_valid_in == 1'b1) begin
                measurement <= measurement_value_in;
            end
        end
    end
end

/////////////////////////////////////////////////////

// Address going to cache read
always@(*) begin
    if (stage_1_ready) begin
        msg_to_cache = msg_from_router;
    end else begin
        msg_to_cache = stage_1_msg;
    end
end

// Data going to cache write
always@(*) begin
    if (cache_writing_mode) begin
        address_for_cache_write = cache_reset_acc;
        value_to_cache_write = {{(CACHED_OFFER_WIDTH-1){1'bx}},1'b0};
    end else begin
        address_for_cache_write = {get_source_row(stage_1_msg), get_source_col(stage_1_msg)};
        value_to_cache_write = {msg_cost, msg_timestamp, get_broker_row(stage_1_msg), get_broker_col(stage_1_msg),1'b1};
    end
end

always @(posedge clk, posedge reset) begin
    if(reset) begin
        cache_reset_acc <= 0;
    end
    else begin
        if (stop_offer) begin
            cache_reset_acc <= 0;
        end else if (cache_writing_mode) begin
            cache_reset_acc <= cache_reset_acc + 1;
        end
    end
end

always@(*) begin
    if(cache_reset_acc[2*CORDINATE_WIDTH] == 1'b1) begin
        cache_writing_mode = 0;
    end else begin
        cache_writing_mode = 1;
    end
end

// Writing to the cache
always@(*) begin
    cache_write = 1'b0;
    if (cache_writing_mode) begin
        cache_write = 1'b1;
    end
    else begin
        if(processing_state == State_msg_processing && stage_1_valid && get_msg_type(stage_1_msg) == MSG_MatchOffer) begin
            if(cache_valid == 1'b1) begin
                if(cost_is_less_than(msg_cost, cache_cost)  || cache_timestamp < msg_timestamp) begin
                    cache_write = 1'b1;
                end else begin
                    cache_write = 1'b0;
                end
            end else begin
                cache_write = 1'b1;
            end
        end else if (processing_state == State_msg_processing && stage_1_valid && get_msg_type(stage_1_msg) == MSG_BreakOffer) begin
            if(cache_valid == 1'b1) begin
                if(cost_is_less_than(msg_cost, cache_cost) || cache_timestamp < msg_timestamp) begin
                    cache_write = 1'b1;
                end else begin
                    cache_write = 1'b0;
                end
            end else begin
                cache_write = 1'b1;
            end
        end
    end
end

// Writing to the loop cache
always@(*) begin
    loop_cache_write = 1'b0;
    if (cache_writing_mode) begin
        loop_cache_write = 1'b1;
    end
    else begin
        if(processing_state == State_msg_processing && stage_1_valid && get_msg_type(stage_1_msg) == MSG_LoopOffer) begin
            if(loop_cache_valid == 1'b1) begin
                if(cost_is_less_than(msg_cost, loop_cache_cost) || loop_cache_timestamp < msg_timestamp) begin
                    loop_cache_write = 1'b1;
                end else begin
                    loop_cache_write = 1'b0;
                end
            end else begin
                loop_cache_write = 1'b1;
            end
        end
    end
end

// TODO : optimize the cache
blk_mem_gen_0 offer_cache
(
	.addra(address_for_cache_write),
    .clka(clk),
    .dina(value_to_cache_write),
    .wea(cache_write),
	.addrb({get_source_row(msg_to_cache), get_source_col(msg_to_cache)}),
	.enb(1'b1),
	.doutb({cache_cost, cache_timestamp,cache_broker_row,cache_broker_col,cache_valid}),
	.clkb(clk)
);

// TODO : optimize the cache
blk_mem_gen_0 loop_cache
(
	.addra(address_for_cache_write),
    .clka(clk),
    .dina(value_to_cache_write),
    .wea(loop_cache_write),
	.addrb({get_source_row(msg_to_cache), get_source_col(msg_to_cache)}),
	.enb(1'b1),
	.doutb({loop_cache_cost, loop_cache_timestamp,loop_cache_broker_row,loop_cache_broker_col,loop_cache_valid}),
	.clkb(clk)
);

always @(posedge clk, posedge reset) begin
    if(reset) begin
        stage_1_valid <= 0;
    end
    else begin
        if (stage_1_ready) begin
            stage_1_valid <= valid_from_router;
            stage_1_msg <= msg_from_router;
        end
    end
end

assign msg_cost = get_cost(stage_1_msg) ;
assign msg_timestamp = get_timestamp(stage_1_msg);
/////////////////////////////////////////////////////////////////////////////////

//Main section of the code

// next state
always @(posedge clk, posedge reset) begin
    if(reset) begin
        processing_state <= State_waiting_from_readout;
    end
    else begin
        processing_state <= processing_next_state;
    end
end

// next state logic
always @(*) begin
    processing_next_state = processing_state; 
    if(stop_offer == 1'b1) begin
        processing_next_state = State_waiting_from_readout; 
    end else begin
        case(processing_state)
            State_waiting_from_readout: begin
                if(start_offer == 1'b1) begin
                    if (cache_writing_mode == 1'b1) begin
                        processing_next_state = State_wait_cache_reset;
                    end else begin
                        processing_next_state = State_initial_resend;
                    end
                end
            end
            State_wait_cache_reset : begin
                if(cache_writing_mode == 1'b0) begin
                    processing_next_state = State_initial_resend;
                end
            end
            State_initial_resend : begin
                if(ready_from_router == 1'b1) begin
                    processing_next_state = State_brokered_break_offer_send;
                end
            end
            State_brokered_break_offer_send : begin
                if(ready_from_router == 1'b1) begin
                    processing_next_state = State_loop_offer_send; 
                end
            end
            State_loop_offer_send,
            State_break_offer_send,
            State_waiting_for_contract_send,
            State_break_offer_response_extra,
            State_loop_offer_response_extra : begin
                if(ready_from_router == 1'b1) begin
                    processing_next_state = State_msg_processing; 
                end
            end
            State_msg_processing : begin
                if(ready_from_router == 1'b1 && stage_1_valid) begin
                    if(get_msg_type(stage_1_msg) == MSG_MatchOffer) begin
                        if(measurement == 1'b1 && cache_write == 1'b1 && qubit_state == State_matched) begin
                            processing_next_state = State_break_offer_send;
                        end else if(measurement == 1'b1 && qubit_state == State_send_offer) begin
                            processing_next_state = State_waiting_for_contract_send;
                        end
                    end else if (get_msg_type(stage_1_msg) == MSG_RefuseAcceptance) begin
                        if(get_broker_row(stage_1_msg) == ROW_ID && get_broker_col(stage_1_msg) == COL_ID && qubit_state != State_matched) begin
                            processing_next_state = State_initial_resend;
                        end
                    end else if (get_msg_type(stage_1_msg) == MSG_BrokeredContract) begin
                        if(broker_next_hop_valid == 1'b0) begin
                            processing_next_state = State_initial_resend;
                        end
                    end else if (get_msg_type(stage_1_msg) == MSG_BreakOffer) begin
                        if(cache_write == 1'b1 && qubit_state == State_matched) begin
                            processing_next_state = State_break_offer_response_extra;
                        end
                    end else if (get_msg_type(stage_1_msg) == MSG_LoopOffer) begin
                        if(loop_cache_write == 1'b1 && qubit_state == State_matched) begin
                            processing_next_state = State_loop_offer_response_extra;
                        end
                    end
                end
            end
        endcase
    end
end

// Ready signal to router and cache
always@(*) begin
    stage_1_ready = 1'b0;
    ready_to_router = 1'b0;
    if (reset) begin
        stage_1_ready = 1'b0;
        ready_to_router = 1'b0;
    end else begin
        if(processing_state == State_msg_processing && ready_from_router == 1'b1) begin
            stage_1_ready = 1'b1;
            ready_to_router = 1'b1;
        end
    end
end

// output msg content
always @(*) begin
    msg_to_router = {(MSG_WIDTH){1'b0}};
    case(processing_state)
        State_initial_resend: begin
            if(measurement == 1'b1) begin
                msg_to_router = {{(CORDINATE_WIDTH){1'b1}}, {(CORDINATE_WIDTH){1'b1}}, ROW_ID, COL_ID, ROW_ID, COL_ID, timestamp,  cost_add(NEIGHBOUR_COST, (-1*BOUNDARY_COST)), MAX_HOP, MSG_MatchOffer};
            end
        end
        State_brokered_break_offer_send: begin
            if(measurement == 1'b1) begin
                msg_to_router = {match_row, match_col, ROW_ID, COL_ID, ROW_ID, COL_ID, timestamp, cost_add(qubit_cost, (-1*BOUNDARY_COST)), MAX_HOP, MSG_BrokeredBreakOffer};
            end
        end
        State_loop_offer_send: begin
            if(measurement == 1'b1) begin
                msg_to_router = {{(CORDINATE_WIDTH){1'b1}}, {(CORDINATE_WIDTH){1'b1}}, ROW_ID, COL_ID, ROW_ID, COL_ID, timestamp, cost_add(NEIGHBOUR_COST, -1*qubit_cost), {(MAX_HOP_WIDTH){1'b0}}, MSG_LoopOffer};
            end
        end
        State_msg_processing: begin
            if(get_msg_type(stage_1_msg) == MSG_MatchOffer) begin
                if(cache_write == 1'b1) begin
                    msg_to_router = {{(CORDINATE_WIDTH){1'b1}}, get_destination(get_broker_row(stage_1_msg), get_broker_col(stage_1_msg),ROW_ID, COL_ID), get_source_row(stage_1_msg), get_source_col(stage_1_msg), get_broker_row(stage_1_msg), get_broker_col(stage_1_msg), get_timestamp(stage_1_msg), cost_add(get_cost(stage_1_msg), NEIGHBOUR_COST), get_max_hops(stage_1_msg), MSG_MatchOffer};
                end
            end else if(get_msg_type(stage_1_msg) == MSG_AcceptOffer) begin
                if( get_source_row(stage_1_msg) == ROW_ID && get_source_col(stage_1_msg) == COL_ID ) begin
                    if(qubit_state == State_send_offer) begin
                        msg_to_router = {get_broker_row(stage_1_msg), get_broker_col(stage_1_msg),ROW_ID, COL_ID, ROW_ID, COL_ID,get_target_row(stage_1_msg), get_target_col(stage_1_msg),{(CORDINATE_WIDTH*2){1'b0}}, MSG_Contract};
                    end else begin
                        msg_to_router = {get_broker_row(stage_1_msg), get_broker_col(stage_1_msg),ROW_ID, COL_ID, ROW_ID, COL_ID,get_target_row(stage_1_msg), get_target_col(stage_1_msg),{(CORDINATE_WIDTH*2){1'b0}}, MSG_RefuseAcceptance};
                    end                            
                end else begin
                    if(qubit_state == State_matched) begin
                        msg_to_router = {match_row, match_col,get_source_row(stage_1_msg), get_source_col(stage_1_msg), ROW_ID, COL_ID,get_target_row(stage_1_msg), get_target_col(stage_1_msg),3'b0, get_is_loop(stage_1_msg),{(MAX_HOP_WIDTH){1'bx}}, MSG_AcceptBrokeredOffer};
                    end else begin
                        msg_to_router = {match_row, match_col,get_source_row(stage_1_msg), get_source_col(stage_1_msg), ROW_ID, COL_ID, get_target_row(stage_1_msg), get_target_col(stage_1_msg),{(CORDINATE_WIDTH*2){1'b0}}, MSG_BrokeredContract};
                    end         
                end
            end else if (get_msg_type(stage_1_msg) == MSG_Contract) begin
                msg_to_router = {get_broker_row(stage_1_msg), get_broker_col(stage_1_msg),ROW_ID, COL_ID, ROW_ID, COL_ID,get_target_row(stage_1_msg), get_target_col(stage_1_msg),{(CORDINATE_WIDTH*2){1'b0}}, MSG_Contract};
            end else if (get_msg_type(stage_1_msg) == MSG_RefuseAcceptance) begin
                if (broker_next_hop_valid == 1'b0) begin
                    msg_to_router = {match_row, match_col, get_source_row(stage_1_msg), get_source_col(stage_1_msg), ROW_ID, COL_ID, get_target_row(stage_1_msg), get_target_col(stage_1_msg), 4'bx, {(MAX_HOP_WIDTH){1'bx}}, MSG_RefuseAcceptance};
                end else begin
                    msg_to_router = {broker_next_hop_row, broker_next_hop_col, get_source_row(stage_1_msg), get_source_col(stage_1_msg), ROW_ID, COL_ID, get_target_row(stage_1_msg), get_target_col(stage_1_msg), 4'bx, {(MAX_HOP_WIDTH){1'bx}}, MSG_RefuseAcceptance};
                end
                
            end else if(get_msg_type(stage_1_msg) == MSG_BrokeredOffer) begin
                if( cost_is_negative (cost_add(get_cost(stage_1_msg), BOUNDARY_COST)) ) begin
                    msg_to_router = {match_row, match_col, get_source_row(stage_1_msg), get_source_col(stage_1_msg),  ROW_ID, COL_ID, ROW_ID, COL_ID, 4'b0, {(MAX_HOP_WIDTH){1'bx}}, MSG_AcceptBrokeredOffer};
                end else begin
                    msg_to_router = {{(CORDINATE_WIDTH){1'b1}}, {(CORDINATE_WIDTH){1'b1}}, get_source_row(stage_1_msg), get_source_col(stage_1_msg), ROW_ID, COL_ID, timestamp,  cost_add(NEIGHBOUR_COST, get_cost(stage_1_msg)), MAX_HOP, MSG_MatchOffer};
                end
            end else if(get_msg_type(stage_1_msg) == MSG_AcceptBrokeredOffer) begin
                if(qubit_state == State_matched && match_row == get_broker_row(stage_1_msg) && match_col == get_broker_col(stage_1_msg)) begin
                    if (get_source_row(stage_1_msg) == ROW_ID && get_source_col(stage_1_msg) == COL_ID) begin
                        msg_to_router = {match_row, match_col,ROW_ID, COL_ID, ROW_ID, COL_ID, get_target_row(stage_1_msg), get_target_col(stage_1_msg),{(CORDINATE_WIDTH*2){1'b0}}, MSG_BrokeredContract};
                    end else begin
                        if (get_is_loop(stage_1_msg) == 1'b1 && loop_cache_valid) begin
                            msg_to_router = {loop_cache_broker_row,loop_cache_broker_col, get_source_row(stage_1_msg), get_source_col(stage_1_msg),  ROW_ID, COL_ID, get_target_row(stage_1_msg), get_target_col(stage_1_msg), 3'b0, get_is_loop(stage_1_msg), {(MAX_HOP_WIDTH){1'bx}}, MSG_AcceptOffer};
                        end else if (get_is_loop(stage_1_msg) == 1'b0 && cache_valid) begin
                            msg_to_router = {cache_broker_row,cache_broker_col, get_source_row(stage_1_msg), get_source_col(stage_1_msg),  ROW_ID, COL_ID, get_target_row(stage_1_msg), get_target_col(stage_1_msg), 3'b0, get_is_loop(stage_1_msg), {(MAX_HOP_WIDTH){1'bx}}, MSG_AcceptOffer};
                        end else begin
                            msg_to_router = {match_row, match_col, get_source_row(stage_1_msg), get_source_col(stage_1_msg), ROW_ID, COL_ID, get_target_row(stage_1_msg), get_target_col(stage_1_msg), 4'bx, {(MAX_HOP_WIDTH){1'bx}}, MSG_RefuseAcceptance};
                        end
                    end
                end else begin
                    msg_to_router = {match_row, match_col, get_source_row(stage_1_msg), get_source_col(stage_1_msg), ROW_ID, COL_ID, get_target_row(stage_1_msg), get_target_col(stage_1_msg), 4'bx, {(MAX_HOP_WIDTH){1'bx}}, MSG_RefuseAcceptance};
                end
            end else if(get_msg_type(stage_1_msg) == MSG_BrokeredContract) begin
                if(broker_next_hop_valid == 1'b1 ) begin
                    msg_to_router = {broker_next_hop_row, broker_next_hop_col, get_source_row(stage_1_msg), get_source_col(stage_1_msg), ROW_ID, COL_ID, get_target_row(stage_1_msg), get_target_col(stage_1_msg),{(CORDINATE_WIDTH*2){1'b0}}, MSG_Contract};
                end
            end else if(get_msg_type(stage_1_msg) == MSG_BrokeredBreakOffer) begin
                if(qubit_state == State_matched && match_row == get_broker_row(stage_1_msg) && match_col == get_broker_col(stage_1_msg)) begin
                    if(compare_i_j(ROW_ID,COL_ID,get_source_row(stage_1_msg), get_source_col(stage_1_msg)) == 2'b11 &&  cost_is_negative (cost_add(get_cost(stage_1_msg), BOUNDARY_COST))) begin
                        msg_to_router = {get_broker_row(stage_1_msg), get_broker_col(stage_1_msg), get_source_row(stage_1_msg), get_source_col(stage_1_msg),  ROW_ID, COL_ID, ROW_ID, COL_ID, 4'b0, {(MAX_HOP_WIDTH){1'bx}}, MSG_AcceptBrokeredOffer};
                    end else begin
                        msg_to_router = {{(CORDINATE_WIDTH){1'b1}}, {(CORDINATE_WIDTH){1'b1}}, get_source_row(stage_1_msg), get_source_col(stage_1_msg), ROW_ID, COL_ID, get_timestamp(stage_1_msg), cost_add(NEIGHBOUR_COST, get_cost(stage_1_msg)), MAX_HOP, MSG_BreakOffer};
                    end
                end
            end else if(get_msg_type(stage_1_msg) == MSG_BreakOffer) begin
                msg_to_router = {{(CORDINATE_WIDTH){1'b1}}, get_destination(get_broker_row(stage_1_msg), get_broker_col(stage_1_msg),ROW_ID, COL_ID), get_source_row(stage_1_msg), get_source_col(stage_1_msg), get_broker_row(stage_1_msg), get_broker_col(stage_1_msg), get_timestamp(stage_1_msg), cost_add(NEIGHBOUR_COST, get_cost(stage_1_msg)), MAX_HOP, MSG_BreakOffer};
            end else if(get_msg_type(stage_1_msg) == MSG_LoopOffer) begin
                msg_to_router = {{(CORDINATE_WIDTH){1'b1}},get_destination(get_broker_row(stage_1_msg), get_broker_col(stage_1_msg),ROW_ID, COL_ID), get_source_row(stage_1_msg), get_source_col(stage_1_msg), get_broker_row(stage_1_msg), get_broker_col(stage_1_msg), get_timestamp(stage_1_msg), cost_add(NEIGHBOUR_COST, get_cost(stage_1_msg)), MAX_HOP, MSG_LoopOffer};
            end else if(get_msg_type(stage_1_msg) == MSG_BrokeredLoopOffer) begin
                msg_to_router = {{(CORDINATE_WIDTH){1'b1}}, {(CORDINATE_WIDTH){1'b1}}, get_source_row(stage_1_msg), get_source_col(stage_1_msg), ROW_ID, COL_ID, get_timestamp(stage_1_msg), cost_add(NEIGHBOUR_COST, get_cost(stage_1_msg)), MAX_HOP, MSG_LoopOffer};
            end
        end
        State_break_offer_send: begin
            if(cache_valid_delayed == 1'b1) begin
               msg_to_router = {match_row, match_col, get_source_row(stage_2_msg), get_source_col(stage_2_msg), ROW_ID, COL_ID, get_timestamp(stage_2_msg), cost_add(get_cost(stage_2_msg), -1*qubit_cost), hop_reduce(get_timestamp(stage_2_msg)), MSG_BrokeredOffer};
            end
        end
        State_waiting_for_contract_send: begin
            msg_to_router = {get_broker_row(stage_2_msg), get_broker_col(stage_2_msg), get_source_row(stage_2_msg), get_source_col(stage_2_msg), ROW_ID, COL_ID,  ROW_ID, COL_ID, 4'b0, {(MAX_HOP_WIDTH){1'bx}}, MSG_AcceptOffer};
        end
        State_break_offer_response_extra: begin
            msg_to_router = {match_row, match_col, get_source_row(stage_2_msg), get_source_col(stage_2_msg), ROW_ID, COL_ID, get_timestamp(stage_2_msg), cost_add(get_cost(stage_2_msg), (-1*qubit_cost)), hop_reduce(get_max_hops(stage_2_msg)), MSG_BrokeredBreakOffer};
        end
        State_loop_offer_response_extra: begin
            if (get_source_row(stage_2_msg) == match_row && get_source_col(stage_2_msg) == match_col) begin
                msg_to_router = {get_broker_row(stage_2_msg), get_broker_col(stage_2_msg), get_source_row(stage_2_msg), get_source_col(stage_2_msg), ROW_ID, COL_ID,  ROW_ID, COL_ID, 4'b1, {(MAX_HOP_WIDTH){1'bx}}, MSG_AcceptOffer};
            end else begin
                msg_to_router = {match_row, match_col, get_source_row(stage_2_msg), get_source_col(stage_2_msg), ROW_ID, COL_ID, get_timestamp(stage_2_msg), cost_add(get_cost(stage_2_msg), (-1*qubit_cost)), {(MAX_HOP_WIDTH){1'bx}}, MSG_BrokeredLoopOffer};
            end
        end
    endcase
end

// output msg valid
always @(*) begin
    valid_to_router = 1'b0;
    case(processing_state)
        State_initial_resend: begin
            if(measurement == 1'b1 && (qubit_state == State_initial || qubit_state == State_send_offer)) begin
                valid_to_router = 1'b1;
            end
        end
        State_brokered_break_offer_send: begin
            if(measurement == 1'b1 && qubit_state == State_matched) begin
                valid_to_router = 1'b1;
            end
        end
        State_loop_offer_send: begin
            if(measurement == 1'b1 && qubit_state == State_matched && compare_i_j(ROW_ID,COL_ID, match_row, match_col) == 2'b11) begin
                valid_to_router = 1'b1;
            end
        end
        State_msg_processing : begin
            if (stage_1_valid) begin
                if(get_msg_type(stage_1_msg) == MSG_MatchOffer) begin
                    if(cache_write == 1'b1) begin
                        valid_to_router = 1'b1;
                    end
                end else if(get_msg_type(stage_1_msg) == MSG_AcceptOffer) begin
                    valid_to_router = 1'b1;
                end else if (get_msg_type(stage_1_msg) == MSG_Contract) begin
                    if(qubit_state == State_waiting_contract && (get_target_row(stage_1_msg) != ROW_ID || get_target_col(stage_1_msg) != COL_ID)) begin
                        valid_to_router = 1'b1;
                    end
                end else if(get_msg_type(stage_1_msg) == MSG_RefuseAcceptance) begin
                    if (get_target_row(stage_1_msg) != ROW_ID || get_target_col(stage_1_msg) != COL_ID) begin
                    valid_to_router = 1'b1; 
                    end
                end else if (get_msg_type(stage_1_msg) == MSG_BrokeredOffer) begin
                    if(qubit_state == State_matched) begin
                        valid_to_router = 1'b1; 
                    end
                end else if(get_msg_type(stage_1_msg) == MSG_AcceptBrokeredOffer) begin
                    valid_to_router = 1'b1;
                end else if(get_msg_type(stage_1_msg) == MSG_BrokeredContract) begin
                    if(broker_next_hop_valid == 1'b1 ) begin
                        valid_to_router = 1'b1;
                    end
                end else if(get_msg_type(stage_1_msg) == MSG_BrokeredBreakOffer) begin
                    if(qubit_state == State_matched && match_row == get_broker_row(stage_1_msg) && match_col == get_broker_col(stage_1_msg)) begin
                        valid_to_router = 1'b1;
                    end
                end else if(get_msg_type(stage_1_msg) == MSG_BreakOffer) begin
                    if(cache_write == 1'b1) begin
                        valid_to_router = 1'b1;
                    end
                end else if(get_msg_type(stage_1_msg) == MSG_LoopOffer) begin
                    if (loop_cache_write == 1'b1 && (get_source_row(stage_1_msg) != ROW_ID || get_source_col(stage_1_msg) != COL_ID)) begin
                        valid_to_router = 1'b1;
                    end
                end else if(get_msg_type(stage_1_msg) == MSG_BrokeredLoopOffer) begin
                    if (qubit_state == State_matched && match_row == get_broker_row(stage_1_msg) && match_col == get_broker_col(stage_1_msg)) begin
                        valid_to_router = 1'b1;
                    end
                end
            end
        end
        State_break_offer_send : begin
            if(cache_valid_delayed == 1'b1) begin
                valid_to_router = 1'b1;
            end
        end
        State_waiting_for_contract_send : begin
            if (compare_i_j(ROW_ID, COL_ID, get_source_row(stage_2_msg), get_source_col(stage_2_msg)) == 2'b11 && cost_is_less_than(get_cost(stage_2_msg) , qubit_cost)) begin
                valid_to_router = 1'b1;
            end
        end
        State_break_offer_response_extra: begin
            if(!(get_source_row(stage_2_msg) == match_row && get_source_col(stage_2_msg) == match_col) && !(get_source_row(stage_2_msg) == ROW_ID && get_source_col(stage_2_msg) == COL_ID) && qubit_state == State_matched) begin
                valid_to_router = 1'b1;
            end
        end
        State_loop_offer_response_extra: begin
            if (get_source_row(stage_2_msg) == match_row && get_source_col(stage_2_msg) == match_col) begin
                if(cost_is_negative(get_cost(stage_2_msg))) begin
                    valid_to_router = 1'b1;
                end
            end else if (compare_i_j(get_source_row(stage_2_msg), get_source_col(stage_2_msg), ROW_ID, COL_ID)  == 2'b11 && compare_i_j(get_source_row(stage_2_msg), get_source_col(stage_2_msg), match_row, match_col) == 2'b11 ) begin
                valid_to_router = 1'b1;
            end
        end
    endcase
end

// qubit state
always @(posedge clk, posedge reset) begin
    if(reset) begin
        qubit_state <= State_initial;
    end
    else begin
        if(processing_state == State_waiting_from_readout) begin
            qubit_state <= State_initial;
            broker_next_hop_valid <= 1'b0;
        end else if(processing_state == State_initial_resend) begin
            if(qubit_state == State_initial) begin
                qubit_state <= State_send_offer;
            end 
            qubit_cost <= BOUNDARY_COST;
        end else if(processing_state == State_waiting_for_contract_send && compare_i_j(ROW_ID, COL_ID, get_source_row(stage_2_msg), get_source_col(stage_2_msg))  == 2'b11 && cost_is_less_than(get_cost(stage_2_msg) , qubit_cost)) begin
            qubit_state <= State_waiting_contract;
        end else if (processing_state == State_msg_processing && stage_1_valid && ready_from_router == 1'b1) begin
            if(get_msg_type(stage_1_msg) == MSG_AcceptOffer) begin
                if( get_source_row(stage_1_msg) == ROW_ID && get_source_col(stage_1_msg) == COL_ID ) begin
                    if(qubit_state == State_send_offer) begin
                        qubit_state <= State_matched;
                        match_row <= get_broker_row(stage_1_msg);
                        match_col <= get_broker_col(stage_1_msg);
                        qubit_cost <= cost_of_matching(ROW_ID, COL_ID,get_broker_row(stage_1_msg),get_broker_col(stage_1_msg));
                    end                            
                end else begin
                    if(qubit_state == State_matched) begin
                        qubit_state <= State_waiting_contract;
                        broker_next_hop_row <= get_broker_row(stage_1_msg);
                        broker_next_hop_col <= get_broker_col(stage_1_msg);
                        broker_next_hop_valid <= 1'b1;
                    end       
                end
            end else if (get_msg_type(stage_1_msg) == MSG_Contract) begin
                if (qubit_state == State_waiting_contract ) begin
                    qubit_state <= State_matched;
                    match_row <= get_broker_row(stage_1_msg);
                    match_col <= get_broker_col(stage_1_msg);
                    qubit_cost <= cost_of_matching(ROW_ID, COL_ID,get_broker_row(stage_1_msg),get_broker_col(stage_1_msg));
                end
            end else if  (get_msg_type(stage_1_msg) == MSG_RefuseAcceptance) begin
                if (get_target_row(stage_1_msg) == ROW_ID && get_target_col(stage_1_msg) == COL_ID) begin
                    if(qubit_state != State_matched) begin
                        qubit_state <= State_send_offer;
                    end
                end else begin
                    broker_next_hop_valid <= 1'b0;
                    qubit_state <= State_matched;
                end
            end else if  (get_msg_type(stage_1_msg) == MSG_AcceptBrokeredOffer) begin
                if(qubit_state == State_matched && match_row == get_broker_row(stage_1_msg) && match_col == get_broker_col(stage_1_msg)) begin
                    if (get_source_row(stage_1_msg) == ROW_ID && get_source_col(stage_1_msg) == COL_ID) begin
                        qubit_state <= State_send_offer;
                        match_row <= {(CORDINATE_WIDTH){1'b0}};
                        match_col <= {(CORDINATE_WIDTH){1'b0}};
                        qubit_cost <= BOUNDARY_COST;
                    end else begin
                        if (get_is_loop(stage_1_msg) == 1'b1 && loop_cache_valid) begin
                            qubit_state <= State_waiting_contract;
                        end else if (get_is_loop(stage_1_msg) == 1'b0 && cache_valid) begin
                            qubit_state <= State_waiting_contract;
                        end
                    end
                end
            end else if(get_msg_type(stage_1_msg) == MSG_BrokeredContract) begin
                if(broker_next_hop_valid == 1'b1 ) begin
                    qubit_state <= State_matched;
                    match_row <= broker_next_hop_row;
                    match_col <= broker_next_hop_col;
                    qubit_cost <= cost_of_matching(ROW_ID, COL_ID,broker_next_hop_row,broker_next_hop_col);
                    broker_next_hop_valid <= 1'b0;
                end else begin
                    qubit_state <= State_send_offer;
                    match_row <= {(CORDINATE_WIDTH){1'b0}};
                    match_col <= {(CORDINATE_WIDTH){1'b0}};
                    qubit_cost <= BOUNDARY_COST;
                end
            end else if(get_msg_type(stage_1_msg) == MSG_BrokeredBreakOffer) begin
                if(qubit_state == State_matched && match_row == get_broker_row(stage_1_msg) && match_col == get_broker_col(stage_1_msg)) begin
                    if(compare_i_j(ROW_ID,COL_ID,get_source_row(stage_1_msg), get_source_col(stage_1_msg))  == 2'b11 &&  cost_is_less_than(get_cost(stage_1_msg), BOUNDARY_COST)) begin
                        qubit_state <= State_waiting_contract;
                    end
                end
            end
        end else if (processing_state == State_loop_offer_response_extra) begin
            if (get_source_row(stage_2_msg) == match_row && get_source_col(stage_2_msg) == match_col && cost_is_negative(get_cost(stage_2_msg))) begin
                qubit_state <= State_waiting_contract;
            end
        end
    end
end

////////////////////////

// Timestamp
always @(posedge clk, posedge reset) begin
    if(reset) begin
        timestamp <= 0;
    end
    else begin
        if (processing_state == State_waiting_from_readout) begin
            timestamp <= 0;
        end else begin
            timestamp <= timestamp_add(timestamp, 1);
        end
    end
end

// stage 2 message for more than 1 output message generated for input message
always @(posedge clk) begin
    if(processing_state == State_msg_processing) begin
        stage_2_msg <= stage_1_msg;
        cache_valid_delayed <= cache_valid;
    end
end





// Helper functions


function [MSG_TYPE_WIDTH-1:0] get_msg_type;
    input [MSG_WIDTH-1 : 0] msg;
    begin
        get_msg_type = msg[MSG_TYPE_WIDTH-1:0];
    end
endfunction

function [CORDINATE_WIDTH-1:0] get_source_row;
    input [MSG_WIDTH-1 : 0] msg;
    begin
        get_source_row = msg[MSG_WIDTH -1 - CORDINATE_WIDTH*2 : CORDINATE_WIDTH*3 + COST_WIDTH + MAX_HOP_WIDTH + TIMESTAMP_WIDTH + MSG_TYPE_WIDTH];
    end
endfunction

function [CORDINATE_WIDTH-1:0] get_source_col;
    input [MSG_WIDTH-1 : 0] msg;
    begin
        get_source_col = msg[MSG_WIDTH -1 - CORDINATE_WIDTH*3 : CORDINATE_WIDTH*2 + COST_WIDTH + MAX_HOP_WIDTH + TIMESTAMP_WIDTH + MSG_TYPE_WIDTH];
    end
endfunction

function [CORDINATE_WIDTH-1:0] get_broker_row;
    input [MSG_WIDTH-1 : 0] msg;
    begin
        get_broker_row = msg[MSG_WIDTH -1 - CORDINATE_WIDTH*4 : CORDINATE_WIDTH + COST_WIDTH + MAX_HOP_WIDTH + TIMESTAMP_WIDTH + MSG_TYPE_WIDTH];
    end
endfunction

function [CORDINATE_WIDTH-1:0] get_broker_col;
    input [MSG_WIDTH-1 : 0] msg;
    begin
        get_broker_col =  msg[MSG_WIDTH -1 - CORDINATE_WIDTH*5 :  COST_WIDTH + MAX_HOP_WIDTH + TIMESTAMP_WIDTH + MSG_TYPE_WIDTH];
    end
endfunction

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

function [COST_WIDTH-1:0] get_cost;
    input [MSG_WIDTH-1 : 0] msg;
    begin
        get_cost = msg [MSG_WIDTH -1 - CORDINATE_WIDTH*6 - TIMESTAMP_WIDTH : MAX_HOP_WIDTH + MSG_TYPE_WIDTH];
    end
endfunction

function [TIMESTAMP_WIDTH-1:0] get_timestamp;
    input [MSG_WIDTH-1 : 0] msg;
    begin
        get_timestamp = msg [MSG_WIDTH -1 - CORDINATE_WIDTH*6  : COST_WIDTH + MAX_HOP_WIDTH + MSG_TYPE_WIDTH];
    end
endfunction

function [MAX_HOP_WIDTH-1:0] get_max_hops;
    input [MSG_WIDTH-1 : 0] msg;
    begin
        get_max_hops = msg [MSG_WIDTH -1 - CORDINATE_WIDTH*6 - TIMESTAMP_WIDTH - COST_WIDTH : MSG_TYPE_WIDTH];
    end
endfunction

function [CORDINATE_WIDTH-1:0] get_target_row;
    input [MSG_WIDTH-1 : 0] msg;
    begin
        get_target_row = msg [MSG_WIDTH -1 - CORDINATE_WIDTH*6  : MSG_WIDTH - CORDINATE_WIDTH*7];
    end
endfunction

function [CORDINATE_WIDTH-1:0] get_target_col;
    input [MSG_WIDTH-1 : 0] msg;
    begin
        get_target_col = msg [MSG_WIDTH -1 - CORDINATE_WIDTH*7  : MSG_WIDTH - CORDINATE_WIDTH*8];
    end
endfunction

function  get_is_loop;
    input [MSG_WIDTH-1 : 0] msg;
    begin
        get_is_loop = msg [MAX_HOP_WIDTH + MSG_TYPE_WIDTH + 1  : MAX_HOP_WIDTH + MSG_TYPE_WIDTH];
    end
endfunction

function [TIMESTAMP_WIDTH - 1:0] timestamp_add;
    input [TIMESTAMP_WIDTH-1 : 0] a, b;
    reg[31:0] y;
    begin
        y = a + b;
        timestamp_add = y [TIMESTAMP_WIDTH - 1:0];
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

function [COST_WIDTH - 1:0] cost_add;
    input [COST_WIDTH-1 : 0] a, b;
    reg[31:0] y;
    begin
        y = a + b;
        cost_add = y [COST_WIDTH - 1:0];
    end
endfunction

function [TIMESTAMP_WIDTH - 1:0] hop_reduce;
    input [TIMESTAMP_WIDTH-1 : 0] a;
    reg[31:0] y;
    begin
        y = a - 31'b1;
        hop_reduce = y [TIMESTAMP_WIDTH - 1:0];
    end
endfunction

function  cost_is_negative;
    input [COST_WIDTH-1 : 0] cost;
    begin
        cost_is_negative = cost[COST_WIDTH-1];
    end
endfunction

function  cost_is_less_than;
    input [COST_WIDTH-1 : 0] costa, costb;
    begin
        if (costa[COST_WIDTH-1] == 0 && costb[COST_WIDTH-1] == 0) begin
            if(costa < costb) begin
                cost_is_less_than = 1'b1;
            end else begin
                cost_is_less_than = 1'b0;
            end
        end else if (costa[COST_WIDTH-1] == 1 && costb[COST_WIDTH-1] == 1) begin
            if(costa > costb) begin
                cost_is_less_than = 1'b1;
            end else begin
                cost_is_less_than = 1'b0;
            end
        end else if (costa[COST_WIDTH-1] == 1 && costb[COST_WIDTH-1] == 0) begin
            cost_is_less_than = 1'b1;
        end else begin
            cost_is_less_than = 1'b0;
        end
    end
endfunction

//helper function to compare i,j
function  [1:0] compare_i_j;
    input [CORDINATE_WIDTH-1 : 0] i1, j1, i2, j2;
    begin
        if(i1 == i2) begin
            if (j1 == j2) begin
                compare_i_j = 2'b0;
            end else if ( j1 < j2 ) begin
                compare_i_j = 2'b11; // negative
            end else begin
                compare_i_j = 2'b1; // positive
            end
        end else if (i1 < i2) begin
            compare_i_j = 2'b11; // negative
        end else begin
            compare_i_j = 2'b1; // positive
        end
    end
endfunction

function [COST_WIDTH - 1:0] cost_of_matching;
    input [CORDINATE_WIDTH-1 : 0] i1, j1, i2, j2;
    reg[31:0] di, dj, d_sum;
    begin
        di = (i1 > i2) ? (i1 - i2) : i2 - i1;
        dj = (j1 > j2) ? (j1 - j2) : j2 - j1;
        d_sum = di + dj;
        cost_of_matching = d_sum[COST_WIDTH :1]; //divide by 2
    end
endfunction

function [CORDINATE_WIDTH-1 : 0] get_destination;
    input [CORDINATE_WIDTH-1 : 0] origin_row, origin_col, my_row, my_col;
    begin
        if (origin_row == my_row && origin_col == my_col) begin
            get_destination = 4'b1111; //send through news
        end else if (origin_row < my_row && origin_col == my_col) begin
            get_destination = 4'b0111; //send through ews
        end else if (origin_row > my_row && origin_col == my_col) begin
            get_destination = 4'b1110;
        end else if (origin_col < my_col) begin
            get_destination = 4'b0100;
        end else begin
            get_destination = 4'b0010;
        end
    end
endfunction

endmodule