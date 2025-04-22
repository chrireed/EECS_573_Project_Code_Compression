// SIMPLE CACHE FOR 1 < WAYS < FULL ASSOCIATIVE

`define DEBUG_CACHE

module icache_Xwa #(
    parameter CACHE_SIZE = 1*1024, // Size of cache in B
    parameter NUM_WAYS   = 64, // Number of ways
    parameter NUM_BLOCKS = 2, // Number of blocks per cache line
    parameter BLOCK_SIZE = 4  // Block size in B

) (
    `ifdef DEBUG_CACHE
        output                    debug_miss,
        output reg [31:0]         occupancy,
    `endif

    input            clk,
    input            resetn,

    input               proc_valid,
    output reg          proc_ready,
    input        [31:0] proc_addr,
    output reg   [8*BLOCK_SIZE - 1:0] proc_rdata,

    // Interface to memory
    output reg         mem_req_valid,
    input              mem_req_ready,
    output reg [31:0]  mem_req_addr,
    input      [8*BLOCK_SIZE - 1:0]  mem_req_rdata

);
    localparam NUM_LINES   = CACHE_SIZE / (NUM_BLOCKS * BLOCK_SIZE);
    localparam LINE_BITS   = $clog2(NUM_LINES);
    localparam NUM_SETS    = NUM_LINES/NUM_WAYS;
    localparam INDEX_BITS  = $clog2(NUM_SETS);
    localparam WAY_BITS    = $clog2(NUM_WAYS);
    localparam OFFSET_BITS = $clog2(NUM_BLOCKS);
    localparam BYTE_OFFSET_BITS = $clog2(BLOCK_SIZE);
    localparam TAG_BITS    = 32 - INDEX_BITS - OFFSET_BITS - BYTE_OFFSET_BITS;

    
    reg [TAG_BITS-1:0]                  tags    [0:NUM_SETS-1][0:NUM_LINES/NUM_SETS-1];
    reg [8*BLOCK_SIZE*NUM_BLOCKS-1:0]   data    [0:NUM_SETS-1][0:NUM_LINES/NUM_SETS-1];
    reg                                 valid   [0:NUM_SETS-1][0:NUM_LINES/NUM_SETS-1];
    reg [WAY_BITS-1:0]                  replace [0:NUM_SETS-1];

    wire [INDEX_BITS-1:0]   index;
    wire [TAG_BITS-1:0]     tag;   
    wire [OFFSET_BITS-1:0]  block_offset;  

    integer i;
    integer j;
    integer k;
    integer way_idx;

    reg cache_miss;
    reg xfer;
    reg [OFFSET_BITS-1:0] write_block;
    reg [2**OFFSET_BITS-2:0] write_counter;
    reg [31:0] proc_req_addr;


    assign block_offset = proc_addr[OFFSET_BITS + BYTE_OFFSET_BITS - 1: BYTE_OFFSET_BITS];
    assign index = proc_addr[INDEX_BITS - 1 + OFFSET_BITS + BYTE_OFFSET_BITS: OFFSET_BITS + BYTE_OFFSET_BITS];
    assign tag = proc_addr[31:32-TAG_BITS];

    `ifdef DEBUG_CACHE
        assign debug_miss = cache_miss;
    `endif

    always @(posedge clk) begin
        if (~resetn) begin
            proc_ready      <= 0;
            mem_req_valid   <= 0;
            cache_miss      <= 0;
            xfer            <= 0;
            for (i = 0; i < NUM_SETS; i = i + 1) begin
                for(j = 0; j < NUM_WAYS; j = j + 1) begin
                    valid[i][j] <= 0;
                end
            end
            for (k = 0; k < NUM_SETS; k = k + 1) begin
                replace[k] <= 0;
            end
            `ifdef DEBUG_CACHE
                occupancy <= 0;
            `endif
        end else begin
            // Make sure a transfer isn't already in progress
            if (proc_valid & ~xfer) begin
                if(~cache_miss) begin
                    // Assume cache miss
                    proc_ready      <= 0;
                    cache_miss      <= 1;
                    proc_req_addr   <= proc_addr;
                    write_block     <= {OFFSET_BITS{1'b0}};
                    // Check for hit
                    for (way_idx = 0; way_idx < NUM_WAYS; way_idx = way_idx + 1) begin
                        if (~cache_miss && valid[index][way_idx] && (tags[index][way_idx] == tag)) begin
                            // Cache hit and read
                            proc_ready <= 1;
                            proc_rdata <= data[index][way_idx][block_offset*(8*BLOCK_SIZE) +: (8*BLOCK_SIZE)]; // Cool way to select bit rage [LSB +: WIDTH UPWARDS]
                            xfer <= 1;
                            cache_miss <= 0; // Cancel miss
                        end
                    end // end for way_idx
                end else begin
                    mem_req_addr  <= {proc_req_addr[31:OFFSET_BITS + BYTE_OFFSET_BITS], write_block, {BYTE_OFFSET_BITS{1'b0}}};
                    if(~mem_req_ready) begin
                        // Initiate a read transaction with mem
                        mem_req_valid <= 1;
                    end else begin
                        // Mem has data on bus, read it in
                        data[index][replace[index]][write_block*32 +: 32] <= mem_req_rdata;
                        mem_req_valid     <= 0;

                        // Check if we've recieved all blocks of data
                        if(write_block == NUM_BLOCKS - 1) begin
                            tags[index][replace[index]]  <= tag;
                            valid[index][replace[index]] <= 1;
                            replace[index]          <= replace[index] + 1;
                            cache_miss              <= 0;
                            `ifdef DEBUG_CACHE
                                if(~valid[index][replace[index]]) begin
                                    occupancy <= occupancy + 1;
                                end
                            `endif
                        end else begin
                            write_block <= write_block + 1;
                        end // end if write_block == NUM_BLOCKS - 1

                    end // end if ~mem_req_ready

                end // end if cache miss

            end else begin 
                proc_ready      <= 0;
                mem_req_valid   <= 0;
                xfer            <= 0;
                cache_miss      <= 0;
            end // end if proc_valid
        end // ~end if resetn
    end // end always posedge clk
endmodule
