//`ifndef DEFINE_DUF_PARAMETERS

// global stage of the algorithm
localparam STAGE_WIDTH = 4;
localparam [STAGE_WIDTH-1:0]
    STAGE_IDLE = 0,
    STAGE_MEASUREMENT_LOADING = 1,
    STAGE_GROW = 2,
    STAGE_MERGE = 3,
    STAGE_PEELING = 4,
    STAGE_RESULT_VALID = 5,
    STAGE_PARAMETERS_LOADING = 6,
    STAGE_MEASUREMENT_PREPARING = 7,
    STAGE_WRITE_TO_MEM = 8,
    STAGE_WAIT_TILL_NODE_RESULTS = 9,
    STAGE_RESET_ROOTS = 10,
    STAGE_TEMPORARY = 11;

localparam [7:0]
    START_DECODING_MSG = 8'h01,
    MEASUREMENT_DATA_HEADER = 8'h02,
    SEND_ODD_AND_BUSY = 8'h03,
    NODE_RESULT_MSG = 8'h04,
    MOVE_TO_STAGE = 8'h05;

//`define DEFINE_DUF_PARAMETERS 1
//`endif

// START_DECODING_MSG -> 
// [0] = 0 => single fpga, 1 => multiple fpga

// NODE_RESULT_MSG ->
// [0] = 1 => busy
// [1] = 1 => odd

// MOVE_TO_STAGE ->
// [0] = 0 => move to peel stage
// [0] = 1 => move to grow stage   
