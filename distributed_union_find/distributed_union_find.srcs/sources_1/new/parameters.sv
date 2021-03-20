
// global stage of the algorithm
localparam [1:0]
    STAGE_IDLE = 0,
    STAGE_SPREAD_CLUSTER = 1,
    STAGE_GROW_BOUNDARY = 2,
    STAGE_SYNC_IS_ODD_CLUSTER = 3;
