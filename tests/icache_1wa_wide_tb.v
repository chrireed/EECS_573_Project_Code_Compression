`timescale 1 ns / 1 ns

module icache_1wa_wide_tb;

    localparam NUM_BLOCKS = 4;

    reg clk;
    reg resetn;
    reg resetn_proc;
    always #2 clk = ~clk;

    // Memory wires
    reg         proc_cache_valid;
    wire        proc_cache_ready;
    reg  [31:0] proc_cache_addr;
    wire [31:0] proc_cache_rdata;

    reg         tb_cache_valid;
    reg  [31:0] tb_cache_addr;

    wire        cache_mem_valid;
    wire        cache_mem_ready;
    wire [31:0] cache_mem_addr;
    wire [32*NUM_BLOCKS - 1:0] cache_mem_rdata;

    // Debug signals
`ifdef DEBUG_CACHE
    wire        dbg_miss;   // From cache

    reg [31:0] dbg_mem_access_count = 0;
    reg [31:0] dbg_cache_miss_count = 0;
`endif

    // Filenames
    reg [239:0] program_memory_file;

    always@(posedge tb_cache_valid) begin
        proc_cache_addr = tb_cache_addr;
        proc_cache_valid = 1;
    end

    always@(negedge proc_cache_ready) begin
        proc_cache_valid = 0;
    end


    initial begin
`ifdef DEBUG_CACHE
        dbg_mem_access_count = 0;
        dbg_cache_miss_count = 0;
`endif

        clk = 1;
        resetn <= 0;
        //resetn_proc <= 0;

        if ($value$plusargs("MEMORY=%s", program_memory_file)) begin
            $display("Loading memory file: %s", program_memory_file);
        end else begin
            $display("Loading default memory file: program.mem");
            program_memory_file = "program.mem";
        end
        $readmemh(program_memory_file, memory.memory);

        $display("=================================");
        $display("============BEGIN================");
        $display("=================================");

`ifdef DEBUG_CACHE
        $display("Time    p_v  c_r  p_addr      c_rdata     c_v  m_r   m_addr      m_rdata   miss");
        $monitor("%-8t %b    %b    %-8h    %-8h    %b    %b    %-8h    %-8h   %b",
                 $time,
                 proc_cache_valid,
                 proc_cache_ready,
                 proc_cache_addr,
                 proc_cache_rdata,
                 cache_mem_valid,
                 cache_mem_ready,
                 cache_mem_addr,
                 cache_mem_rdata,
                 dbg_miss);
`else
        $display("Time    p_v  c_r  p_addr      c_rdata     c_v  m_r  m_addr");
        $monitor("%-8t %b    %b    %-8h    %-8h    %b    %b    %-8h",
                 $time,
                 proc_cache_valid,
                 proc_cache_ready,
                 proc_cache_addr,
                 proc_cache_rdata,
                 cache_mem_valid,
                 cache_mem_ready,
                 cache_mem_addr);
`endif

        #100 
        resetn <= 1;
        resetn_proc <= 1;

        #50 tb_cache_valid = 1; tb_cache_addr = 32'h0000_0000;
        #50 tb_cache_valid = 0;
        #50 tb_cache_valid = 1; tb_cache_addr = 32'h0000_0004;
        #50 tb_cache_valid = 0;
        #50 tb_cache_valid = 1; tb_cache_addr = 32'h0000_0000;
        #50 tb_cache_valid = 0;
        #50 tb_cache_valid = 1; tb_cache_addr = 32'h0000_0004;
        #50 tb_cache_valid = 0;
        #50 tb_cache_valid = 1; tb_cache_addr = 32'h0000_0008;
        #50 tb_cache_valid = 0;
        #50 tb_cache_valid = 1; tb_cache_addr = 32'h0000_0010;
        #50 tb_cache_valid = 0;
        #50 tb_cache_valid = 1; tb_cache_addr = 32'h0000_000C;
        #50 tb_cache_valid = 0;
        #50 tb_cache_valid = 1; tb_cache_addr = 32'h0000_0000;
        #50 tb_cache_valid = 0;
        #50 tb_cache_valid = 1; tb_cache_addr = 32'h0000_0004;
        #50 tb_cache_valid = 0;
        #50 tb_cache_valid = 1; tb_cache_addr = 32'h0000_0010;
        #50 tb_cache_valid = 0;

        // // Run for awhile and check that cache isnt missing anymore
        // #500 resetn_proc <= 0;
        // #100 resetn_proc <= 1;
        // #500


`ifdef DEBUG_CACHE
        $display("\nCache Statistics:");
        $display("Hits: %d, Misses: %d, Memory Accesses: %d",
                dbg_mem_access_count - dbg_cache_miss_count,
                dbg_cache_miss_count,
                dbg_mem_access_count);
`endif

        $display("=================================");
        $display("============END==================");
        $display("=================================");
        $finish;
    end

`ifdef DEBUG_CACHE
    always @(posedge dbg_miss) begin
        dbg_cache_miss_count <= dbg_cache_miss_count + 1;
    end
     always @(posedge proc_cache_valid) begin
        dbg_mem_access_count <= dbg_mem_access_count + 1;
    end
`endif

    // picorv32 #(
    // ) proc (
    //     .clk         (clk        ),
    //     .resetn      (resetn_proc     ),
    //     .mem_valid   (proc_cache_valid  ),
    //     .mem_ready   (proc_cache_ready  ),
    //     .mem_addr    (proc_cache_addr   ),
    //     .mem_rdata   (proc_cache_rdata  )
    // );


    icache_1wa_wide #(
        .CACHE_SIZE(32), // Size of cache in B
        .NUM_BLOCKS(NUM_BLOCKS), // Number of blocks per cache line
        .BLOCK_SIZE(4)  // Block size in B
    ) icache (
        `ifdef DEBUG_CACHE
            .debug_miss    (dbg_miss),
        `endif

        .clk         (clk        ),
        .resetn      (resetn     ),
        .proc_valid    (proc_cache_valid),
        .proc_ready    (proc_cache_ready),
        .proc_addr     (proc_cache_addr),
        .proc_rdata    (proc_cache_rdata),
        .mem_req_valid (cache_mem_valid),
        .mem_req_ready (cache_mem_ready),
        .mem_req_addr  (cache_mem_addr),
        .mem_req_rdata (cache_mem_rdata)
    );

    imem_wide #(
        .NUM_BLOCKS(NUM_BLOCKS) // Number of blocks per cache line
    ) memory (
        .clk         (clk        ),
        .mem_valid   (cache_mem_valid),
        .mem_ready   (cache_mem_ready),
        .mem_addr    (cache_mem_addr),
        .mem_rdata   (cache_mem_rdata)
    );

endmodule