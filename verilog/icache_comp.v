module icache_comp #(
    parameter CACHE_SIZE = 1*1024, // Size of cache in B
    parameter NUM_BLOCKS = 1, // Number of blocks per cache line
    parameter BLOCK_SIZE = 4  // Block size in B
) (
    input            clk,
    input            resetn,

    input               proc_valid,
    output reg          proc_ready,
    input        [31:0] proc_addr,
    output reg   [31:0] proc_rdata,

    // Interface to memory
    output reg         mem_req_valid,
    input              mem_req_ready,
    output reg [31:0]  mem_req_addr,
    input      [31:0]  mem_req_rdata


);

    localparam NUM_LINES   = CACHE_SIZE / (NUM_BLOCKS * BLOCK_SIZE);
    localparam INDEX_BITS  = $clog2(NUM_LINES);
    localparam OFFSET_BITS = $clog2(NUM_BLOCKS);
    localparam TAG_BITS    = 32 - INDEX_BITS - OFFSET_BITS - 2;
    
    reg [TAG_BITS-1:0]                  tags  [0:NUM_LINES-1];
    reg [8*BLOCK_SIZE*NUM_BLOCKS-1:0]   data  [0:NUM_LINES-1];
    reg                                 valid [0:NUM_LINES-1];

    wire [INDEX_BITS-1:0] index; 
    wire [TAG_BITS-1:0]   tag;   

    integer i;
    reg cache_miss;
    reg xfer;


    assign index = proc_addr[OFFSET_BITS + INDEX_BITS - 1 + 2: OFFSET_BITS + 2];
    assign tag = proc_addr[31:31-TAG_BITS];

    always @(posedge clk) begin
        if (~resetn) begin
            proc_ready      <= 0;
            mem_req_valid   <= 0;
            cache_miss      <= 0;
            xfer            <= 0;
            for (i = 0; i < CACHE_SIZE; i = i + 1) begin
                valid[i] <= 0;
            end
        end 
        else begin
            if (proc_valid & ~xfer) begin
                if (~cache_miss && valid[index] && (tags[index] == tag)) begin
                    // Cache hit and read
                    proc_ready <= 1;
                    proc_rdata <= data[index];
                    xfer <= 1;
                end else begin
                    // Cache miss
                    proc_ready <= 0;
                    cache_miss <= 1;
                end
                if(cache_miss) begin
                    if(~mem_req_ready) begin
                        mem_req_valid <= 1;
                        mem_req_addr  <= proc_addr;
                    end
                    else begin
                        mem_req_valid     <= 0;
                        tags[index]       <= tag;
                        data[index]       <= mem_req_rdata;
                        valid[index]      <= 1;
                        cache_miss        <= 0;
                    end
                end
            end
            else begin 
                proc_ready <= 0;
                mem_req_valid <= 0;
                xfer <= 0;
            end
      end
    end
endmodule
