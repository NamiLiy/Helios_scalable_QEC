localparam [1:0] 
    Data_Qubit = 2'b0,
    StabX_Qubit =  2'b1,
    StabY_Qubit =  2'b10;

localparam CACHED_OFFER_WIDTH = 24;
localparam TOTAL_QUBITS = 13*13;
localparam CORDINATE_WIDTH = 4; //how many bits needed to store an x or y cordinate
localparam MATCH_VALUE_WIDTH = CORDINATE_WIDTH*2; // output matched value sent back
localparam ACCEPT_PROB_WIDTH = 8;
localparam MAX_HOP_WIDTH = 4;
localparam [MAX_HOP_WIDTH - 1 : 0] MAX_HOP = 15;
localparam COST_WIDTH = 6;
localparam TIMESTAMP_WIDTH = 6;
localparam MSG_TYPE = 4;
localparam  MSG_TYPE_WIDTH = 4;
localparam MSG_WIDTH = MSG_TYPE_WIDTH + TIMESTAMP_WIDTH + CORDINATE_WIDTH*6 + COST_WIDTH + MAX_HOP_WIDTH;


localparam  NEIGHBOUR_COST = 1;

localparam PROCESSING_STATE_WIDTH = 4;

localparam [PROCESSING_STATE_WIDTH - 1:0] 
    State_waiting_from_readout = 4'b0, // qubits expect value to be send from readout
    State_initial_resend = 4'b1, // qubits expect value to be send from readout
    State_brokered_break_offer_send = 4'b10, // A message will be readout and processed
    State_loop_offer_send = 4'b11,
    State_msg_processing = 4'b100,
    State_break_offer_send = 4'b101,
    State_waiting_for_contract_send = 4'b110,
    State_break_offer_response_extra = 4'b111,
    State_loop_offer_response_extra = 4'b1000,
    State_wait_cache_reset = 4'b1001;


localparam QUBIT_STATE_WIDTH = 3;

localparam [QUBIT_STATE_WIDTH - 1:0] 
    State_initial = 3'b0, //qubits expect value to be send from readout
    State_send_offer =  3'b1, //offer is send
    State_waiting_contract = 3'b10, //waiting for contract
    State_matched =  3'b11; //matched with ...
    


localparam [MSG_TYPE_WIDTH - 1 :0] 
    MSG_MatchOffer = 4'b0,
    MSG_AcceptOffer =  4'b1,
    MSG_RefuseAcceptance =  4'b10,
    MSG_Contract = 4'b11,
    MSG_BrokeredOffer =  4'b100,
    MSG_AcceptBrokeredOffer =  4'b101,
    MSG_BrokeredContract = 4'b110,
    MSG_BrokeredBreakOffer =  4'b111,
    MSG_BreakOffer =  4'b1000,
    MSG_LoopOffer = 4'b1001,
    MSG_BrokeredLoopOffer =  4'b1010;

