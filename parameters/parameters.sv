//`ifndef DEFINE_DUF_PARAMETERS

// global stage of the algorithm
localparam STAGE_WIDTH = 3;
localparam [STAGE_WIDTH-1:0]
    STAGE_IDLE = 0,
    STAGE_MEASUREMENT_LOADING = 1,
    STAGE_GROW = 2,
    STAGE_MERGE = 3,
    STAGE_PEELING = 4,
    STAGE_RESULT_VALID = 5;

//`define DEFINE_DUF_PARAMETERS 1
//`endif
