// SIMPLE DIRECT MAPPED SIZE CONFIGURABLE CACHE WITH RDATA WIDTH = BLOCK_SIZE * NUM_BLOCKS

//`define DEBUG_CACHE

module icache_1wa_wide_comp #(
    parameter CACHE_SIZE = 1*1024, // Size of cache in B
    parameter NUM_BLOCKS = 4, // Number of blocks per cache line
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
    input      [8*BLOCK_SIZE*NUM_BLOCKS - 1:0]  mem_req_rdata

);
    localparam NUM_LINES   = CACHE_SIZE / (NUM_BLOCKS * BLOCK_SIZE);
    localparam INDEX_BITS  = $clog2(NUM_LINES);
    localparam OFFSET_BITS = $clog2(NUM_BLOCKS);
    //localparam BYTE_OFFSET_BITS = $clog2(BLOCK_SIZE);
    localparam BYTE_OFFSET_BITS = 2;
    localparam TAG_BITS    = 32 - INDEX_BITS - OFFSET_BITS - BYTE_OFFSET_BITS;

    
    reg [TAG_BITS-1:0]                  tags  [0:NUM_LINES-1];
    reg [8*BLOCK_SIZE*NUM_BLOCKS-1:0]   data  [0:NUM_LINES-1];
    reg                                 valid [0:NUM_LINES-1];

    wire [INDEX_BITS-1:0]   index;
    wire [TAG_BITS-1:0]     tag;   
    wire [OFFSET_BITS-1:0]  block_offset;  

    integer i;
    reg cache_miss;
    reg xfer;
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
            for (i = 0; i < NUM_LINES; i = i + 1) begin
                valid[i] <= 0;
            end
            `ifdef DEBUG_CACHE
                occupancy <= 0;
            `endif
        end 
        else begin
            if (proc_valid & ~xfer) begin
                if (~cache_miss && valid[index] && (tags[index] == tag)) begin
                    // Cache hit and read
                    proc_ready <= 1;
                    proc_rdata <= data[index][block_offset*(8*BLOCK_SIZE) +: (8*BLOCK_SIZE)]; // Cool way to select bit rage [LSB +: WIDTH UPWARDS]
                    xfer <= 1;
                end else if(~cache_miss) begin
                    // Cache miss
                    proc_ready      <= 0;
                    cache_miss      <= 1;
                    proc_req_addr   <= proc_addr;
                end
                if(cache_miss) begin
                    mem_req_addr  <= {proc_req_addr[31:OFFSET_BITS + BYTE_OFFSET_BITS], {OFFSET_BITS{1'b0}}, {BYTE_OFFSET_BITS{1'b0}}};
                    if(~mem_req_ready) begin
                        // Initiate a read transaction with mem
                        mem_req_valid <= 1;
                    end else begin
                        // Mem has data on bus, read it in
                        data[index]     <= mem_req_rdata;
                        mem_req_valid   <= 0;
                        tags[index]     <= tag;
                        valid[index]    <= 1;
                        cache_miss      <= 0;
                         `ifdef DEBUG_CACHE
                                if(~valid[index]) begin
                                    occupancy <= occupancy + 1;
                                end
                            `endif
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
