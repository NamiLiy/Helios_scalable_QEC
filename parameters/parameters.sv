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
    STAGE_LOAD_ARTIFICAL_DEFECTS = 11;

localparam [7:0]
    HEADER_INITIALIZE_DECODING = 8'h00,
    HEADER_SET_BOUNDARIES = 8'h01,
    HEADER_DECODE_BLOCK = 8'h02,
    HEADER_TRANSFER_ARTIFICIAL_BOUNDARY = 8'h03,
    HEADER_LOAD_ARTIFICIAL_BOUNDARY = 8'h04,
    HEADER_REPORT_RESULT = 8'h05,
    HEADER_RESULT = 8'h06,
    HEADER_RESET_CLOCK = 8'h07;

//`define DEFINE_DUF_PARAMETERS 1
//`endif

// Message format | Dest 8 bit | Header 8 bit | Payload 48 bits |
// Dest 8 bit == 0 is root
// Dest FF is broadcast

// HEADER_INITIALIZE_DECODING -> NO parameters

// HEADER_SET_BOUNDARIES -> Set boundaries of the bloclk
// |ID of the group of boundaries|Mask of that boundary|
// ID goes as -- first and || then

// HEADER_DECODE_BLOCK -> Decode the block
// |0| indicate peel and finish this block (T and F)
// |1| indicate report latency at the end of the block (T and F)
// |2| indicate wait for latency before sending next measurement
// |3| indicate latency from all FPGAs

// HEADER_RESULT -> Result of the block including decoding latency
// |15:0| decoding latency
// |47:42| ID of the sender


localparam MSG_DEST_MSB = 64 - 1;
localparam MSG_DEST_LSB = MSG_DEST_MSB - 7;
localparam MSG_HEADER_MSB = MSG_DEST_LSB - 1;
localparam MSG_HEADER_LSB = MSG_HEADER_MSB - 7;

`define SLICE_VEC(vec, idx, width) (vec[idx*width +: width])


`define NEIGHBOR_IDX_NW 0 // In RSC North means North West
`define NEIGHBOR_IDX_SE 1 
`define NEIGHBOR_IDX_SW 2
`define NEIGHBOR_IDX_NE 3
`define NEIGHBOR_IDX_DOWN 4
`define NEIGHBOR_IDX_UP 5

`define NORMAL_EDGE 0
`define BOUNDARY_EDGE 1
`define NO_EDGE 2
`define FUSION_EDGE 3
//fusion edge is connected on both ends but acts like a boundary

