// output msg content
always @(*) begin
    outqueue_north_value_out = {(MSG_WIDTH){1'b0}};
    outqueue_south_value_out = {(MSG_WIDTH){1'b0}};
    outqueue_east_value_out = {(MSG_WIDTH){1'b0}};
    outqueue_west_value_out = {(MSG_WIDTH){1'b0}};
    case(node_state)
        State_initial: begin
            if(start_offer == 1'b1 && measurement == 1'b1) begin
                outqueue_north_value_out = {cordinate_add(ROW_ID, -1), COL_ID, MSG_MatchOffer, timestamp_add(timestamp, 1), ROW_ID, COL_ID, ROW_ID, COL_ID, cost_add(1, (-1*BOUNDARY_COST)), MAX_HOP};
                outqueue_south_value_out = {cordinate_add(ROW_ID, 1), COL_ID, MSG_MatchOffer, timestamp_add(timestamp, 1), ROW_ID, COL_ID, ROW_ID, COL_ID, cost_add(1, (-1*BOUNDARY_COST)), MAX_HOP};
                outqueue_east_value_out = {ROW_ID, cordinate_add(COL_ID, 1), MSG_MatchOffer, timestamp_add(timestamp, 1), ROW_ID, COL_ID, ROW_ID, COL_ID, cost_add(1, (-1*BOUNDARY_COST)), MAX_HOP};
                outqueue_west_value_out = {ROW_ID, cordinate_add(COL_ID, -1), MSG_MatchOffer, timestamp_add(timestamp, 1), ROW_ID, COL_ID, ROW_ID, COL_ID, cost_add(1, (-1*BOUNDARY_COST)), MAX_HOP};
            end
        end
        State_send_offer_2: begin
            outqueue_north_value_out = {get_source_row(msg_saved), get_source_col(msg_saved), MSG_AcceptOffer, timestamp_saved, ROW_ID, COL_ID,  get_broker_row(msg_saved), get_broker_col(msg_saved), cost_add(cost_saved, 1), MAX_HOP};
            outqueue_south_value_out = {get_source_row(msg_saved), get_source_col(msg_saved), MSG_AcceptOffer, timestamp_saved, ROW_ID, COL_ID,  get_broker_row(msg_saved), get_broker_col(msg_saved), cost_add(cost_saved, 1), MAX_HOP};
            outqueue_east_value_out = {get_source_row(msg_saved), get_source_col(msg_saved), MSG_AcceptOffer, timestamp_saved, ROW_ID, COL_ID,  get_broker_row(msg_saved), get_broker_col(msg_saved), cost_add(cost_saved, 1), MAX_HOP};
            outqueue_west_value_out = {get_source_row(msg_saved), get_source_col(msg_saved), MSG_AcceptOffer, timestamp_saved, ROW_ID, COL_ID,  get_broker_row(msg_saved), get_broker_col(msg_saved), cost_add(cost_saved, 1), MAX_HOP};
        end
        State_matched_1: begin
            outqueue_north_value_out = {match_row, match_col, MSG_BrokeredOffer, timestamp_add(timestamp, 1), ROW_ID, COL_ID, ROW_ID, COL_ID, cost_add(BOUNDARY_COST, -1*cost), MAX_HOP};
            outqueue_south_value_out = {match_row, match_col, MSG_BrokeredOffer, timestamp_add(timestamp, 1), ROW_ID, COL_ID, ROW_ID, COL_ID, cost_add(BOUNDARY_COST, -1*cost), MAX_HOP};
            outqueue_east_value_out = {match_row, match_col, MSG_BrokeredOffer, timestamp_add(timestamp, 1), ROW_ID, COL_ID, ROW_ID, COL_ID, cost_add(BOUNDARY_COST, -1*cost), MAX_HOP};
            outqueue_west_value_out = {match_row, match_col, MSG_BrokeredOffer, timestamp_add(timestamp, 1), ROW_ID, COL_ID, ROW_ID, COL_ID, cost_add(BOUNDARY_COST, -1*cost), MAX_HOP};
        end
        State_matched_2: begin
            outqueue_north_value_out = {cordinate_add(ROW_ID, -1), COL_ID, MSG_LoopOffer, timestamp_add(timestamp, 1), ROW_ID, COL_ID, ROW_ID, COL_ID, cost_add(1, -1*cost), {(MAX_HOP_WIDTH){1'b0}}};
            outqueue_south_value_out = {cordinate_add(ROW_ID, 1), COL_ID, MSG_LoopOffer, timestamp_add(timestamp, 1), ROW_ID, COL_ID, ROW_ID, COL_ID, cost_add(1, -1*cost), {(MAX_HOP_WIDTH){1'b0}}};
            outqueue_east_value_out = {ROW_ID, cordinate_add(COL_ID, 1), MSG_LoopOffer, timestamp_add(timestamp, 1), ROW_ID, COL_ID, ROW_ID, COL_ID, cost_add(1, -1*cost), {(MAX_HOP_WIDTH){1'b0}}};
            outqueue_west_value_out = {ROW_ID, cordinate_add(COL_ID, -1), MSG_LoopOffer, timestamp_add(timestamp, 1), ROW_ID, COL_ID, ROW_ID, COL_ID, cost_add(1, -1*cost), {(MAX_HOP_WIDTH){1'b0}}};
        end
        State_matched_5: begin
            outqueue_north_value_out = {match_row, match_col, MSG_BrokeredOffer, timestamp_saved, get_source_row(msg_saved), get_source_col(msg_saved), ROW_ID, COL_ID, cost_add(cost_saved, -1*cost), MAX_HOP - 1};
            outqueue_south_value_out = {match_row, match_col, MSG_BrokeredOffer, timestamp_saved, get_source_row(msg_saved), get_source_col(msg_saved), ROW_ID, COL_ID, cost_add(cost_saved, -1*cost), MAX_HOP - 1};
            outqueue_east_value_out = {match_row, match_col, MSG_BrokeredOffer, timestamp_saved, get_source_row(msg_saved), get_source_col(msg_saved), ROW_ID, COL_ID, cost_add(cost_saved, -1*cost), MAX_HOP - 1};
            outqueue_west_value_out = {match_row, match_col, MSG_BrokeredOffer, timestamp_saved, get_source_row(msg_saved), get_source_col(msg_saved), ROW_ID, COL_ID, cost_add(cost_saved, -1*cost), MAX_HOP - 1};
        end
        State_matched_6: begin
            outqueue_north_value_out = {cordinate_add(ROW_ID, -1), COL_ID, MSG_MatchOffer, timestamp_saved, get_source_row(msg_saved), get_source_col(msg_saved),  get_broker_row(msg_saved), get_broker_col(msg_saved), cost_add(cost_saved, 1), MAX_HOP};
            outqueue_south_value_out = {cordinate_add(ROW_ID, 1), COL_ID, MSG_MatchOffer, timestamp_saved, get_source_row(msg_saved), get_source_col(msg_saved),  get_broker_row(msg_saved), get_broker_col(msg_saved), cost_add(cost_saved, 1), MAX_HOP};
            outqueue_east_value_out = {ROW_ID, cordinate_add(COL_ID, 1), MSG_MatchOffer, timestamp_saved, get_source_row(msg_saved), get_source_col(msg_saved),  get_broker_row(msg_saved), get_broker_col(msg_saved), cost_add(cost_saved, 1), MAX_HOP};
            outqueue_west_value_out = {ROW_ID, cordinate_add(COL_ID, -1), MSG_MatchOffer, timestamp_saved, get_source_row(msg_saved), get_source_col(msg_saved),  get_broker_row(msg_saved), get_broker_col(msg_saved), cost_add(cost_saved, 1), MAX_HOP};
        end
        default begin
            outqueue_north_value_out = {(MSG_WIDTH){1'b0}};
            outqueue_south_value_out = {(MSG_WIDTH){1'b0}};
            outqueue_east_value_out = {(MSG_WIDTH){1'b0}};
            outqueue_west_value_out = {(MSG_WIDTH){1'b0}};
        end
    endcase
end

// next state logic
always @(*) begin
    node_next_state = node_state; 
    case(node_state)
        State_initial: begin
            if(start_offer == 1'b1) begin
                node_next_state = State_send_offer;
            end
        end
        State_send_offer: begin
            if(next_msg_valid == 1'b1 && cost >  get_cost(next_msg_to_process) && is_less_than(get_source_row(next_msg_to_process), get_source_col(next_msg_to_process), ROW_ID, COL_ID)) begin
                node_next_state = State_send_offer_2;
            end
        end
        State_send_offer_2: begin
            if(outqueue_north_ready_in == 1'b1 && outqueue_south_ready_in == 1'b1 && outqueue_west_ready_in == 1'b1 && outqueue_east_ready_in == 1'b1) begin
                node_next_state = State_matched_1;
            end
        end
        State_matched_1: begin
            if(outqueue_north_ready_in == 1'b1 && outqueue_south_ready_in == 1'b1 && outqueue_west_ready_in == 1'b1 && outqueue_east_ready_in == 1'b1) begin
                node_next_state = State_matched_2;
            end
        end
        State_matched_2: begin
            if(outqueue_north_ready_in == 1'b1 && outqueue_south_ready_in == 1'b1 && outqueue_west_ready_in == 1'b1 && outqueue_east_ready_in == 1'b1) begin
                node_next_state = State_matched_3;
            end
        end
        State_matched_3: begin
            if (stop_offer) begin
                node_next_state = State_initial;
            end else if(next_msg_valid == 1'b1 && get_msg_type(next_msg_to_process) == MSG_MatchOffer) begin
                node_next_state = State_matched_4;
            end
        end
        State_matched_4: begin
            if(cache_cost > msg_cost && cache_timestamp < msg_timestamp) begin
                node_next_state = State_matched_5;
            end else begin
                node_next_state = State_matched_3;
            end
        end
        State_matched_5: begin
            if(outqueue_north_ready_in == 1'b1 && outqueue_south_ready_in == 1'b1 && outqueue_west_ready_in == 1'b1 && outqueue_east_ready_in == 1'b1) begin
                node_next_state = State_matched_6;
            end
        end
        State_matched_6: begin
            if(outqueue_north_ready_in == 1'b1 && outqueue_south_ready_in == 1'b1 && outqueue_west_ready_in == 1'b1 && outqueue_east_ready_in == 1'b1) begin
                node_next_state = State_matched_3;
            end
        end
    endcase
end

// next state
always @(posedge clk, posedge reset) begin
    if(reset) begin
        node_state <= State_initial;
    end
    else begin
        node_state <= node_next_state;
    end
end

// output msg valid
always @(*) begin
    outqueue_north_valid_out = 0;
    outqueue_south_valid_out = 0;
    outqueue_east_valid_out = 0;
    outqueue_west_valid_out = 0;
    case(node_state)
        State_initial: begin
            if(start_offer == 1'b1 && measurement == 1'b1) begin
                outqueue_north_valid_out = 1;
                outqueue_south_valid_out = 1;
                outqueue_east_valid_out = 1;
                outqueue_west_valid_out = 1;
            end
        end
        State_send_offer_2: begin
            {outqueue_north_valid_out,
            outqueue_south_valid_out,
            outqueue_east_valid_out,
            outqueue_west_valid_out} = select_output_port(get_receiver_row(msg_saved), get_receiver_col(msg_saved), ROW_ID, COL_ID);
        end
        State_matched_1,
        State_matched_5: begin
            {outqueue_north_valid_out,
            outqueue_south_valid_out,
            outqueue_east_valid_out,
            outqueue_west_valid_out} = select_output_port(match_row, match_col, ROW_ID, COL_ID);
        end
        State_matched_2: begin
            if(is_less_than(match_row, match_col, ROW_ID, COL_ID) == 1'b1) begin
                outqueue_north_valid_out = 1;
                outqueue_south_valid_out = 1;
                outqueue_east_valid_out = 1;
                outqueue_west_valid_out = 1;
            end
        end
        State_matched_6: begin
            outqueue_north_valid_out = 1;
            outqueue_south_valid_out = 1;
            outqueue_east_valid_out = 1;
            outqueue_west_valid_out = 1;
        end
    endcase
end

//helper function to compare i,j
function  is_less_than;
    input [CORDINATE_WIDTH-1 : 0] dest_row, dest_col, my_row, my_col;
    begin
        if(dest_row < my_row) begin
            is_less_than = 1'b1;
        end else if (dest_row == my_row && dest_col < my_col) begin
            is_less_than = 1'b1;
        end else begin
           is_less_than = 1'b0;
        end
    end
endfunction

function [3:0] select_output_port;
    input [CORDINATE_WIDTH-1 : 0] dest_row, dest_col, my_row, my_col;
    begin
        if(dest_row < my_row) begin
            select_output_port = 4'b1000;
        end else if (dest_row > my_row) begin
            select_output_port = 4'b0100;
        end else if (dest_row == my_row && dest_col > my_col) begin
            select_output_port = 4'b0010;
        end else if (dest_row == my_row && dest_col < my_col) begin
            select_output_port = 4'b0001;
        end else begin
            select_output_port = 4'b0000;
        end
    end
endfunction