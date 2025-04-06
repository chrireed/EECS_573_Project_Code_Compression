`timescale 1 ns / 1 ns

module icache_dwa_tb;
    reg clk;
    reg resetn;

    always #2 clk = ~clk;


    // Memory wires
    reg         proc_cache_valid;
    wire        proc_cache_ready;
    reg  [31:0] proc_cache_addr;
    wire [31:0] proc_cache_rdata;

    wire        cache_mem_valid;
    wire        cache_mem_ready;
    wire [31:0] cache_mem_addr;
    wire [31:0] cache_mem_rdata;

    reg        proc_control_instr;
    reg [31:0] proc_mem_wdata;
    reg [3:0]  proc_mem_wstrb;

    // Filenames and descriptors
    reg [239:0] program_memory_file;

    initial begin
        proc_control_instr  = 0;
        proc_mem_wdata      = 32'h0000_0000;
        proc_mem_wstrb      = 4'h0;

        proc_cache_valid    = 0;
        proc_cache_addr     = 32'h0000_0000;

        clk = 1;
        resetn = 0;

        // Load program into memory
        if ($value$plusargs("MEMORY=%s", program_memory_file)) begin
            $display("Loading memory file: %s", program_memory_file);
        end else begin
            $display("Loading default memory file: program.mem");
            program_memory_file = "program.mem";
        end
        $display("Loading RAM contents starting at: 0x%h", 0);
        $readmemh(program_memory_file, memory.memory);

        $display("=================================");
        $display("============BEGIN================");
        $display("=================================");

        $display("Time\tp_v\tc_r\tp_addr\t\tc_rdata\t\tc_v\tm_ready\tc_addr\tm_rdata\trst");

        // Monitor the specified signals
        $monitor("%0t\t\t%b\t%b\t%h\t%h\t%b\t%b\t%h\t%h\t",
                 $time,
                 proc_cache_valid,
                 proc_cache_ready,
                 proc_cache_addr,
                 proc_cache_rdata,
                 cache_mem_valid,
                 cache_mem_ready,
                 cache_mem_addr,
                 cache_mem_rdata,
                 resetn);
        #3
        resetn <= 1;

        #4
        proc_cache_valid    = 1;
        proc_cache_addr     = 32'h0000_0000;

        #20
        proc_cache_valid    = 0;


        #4
        proc_cache_valid    = 1;
        proc_cache_addr     = 32'h0000_0004;
        #20
        proc_cache_valid    = 0;

        #4
        proc_cache_valid    = 1;
        proc_cache_addr     = 32'h0000_0000;
        #20
        proc_cache_valid    = 0;

        #4

        $display("=================================");
        $display("============END==================");
        $display("=================================");
        $finish;
    end


    icache_direct_mapped #(
    ) icache (
        .clk         (clk        ),
        .resetn      (resetn     ),

        .proc_valid   (proc_cache_valid  ),
        .proc_ready   (proc_cache_ready  ),
        .proc_addr    (proc_cache_addr   ),
        .proc_rdata   (proc_cache_rdata  ),

        .mem_req_valid   (cache_mem_valid  ),
        .mem_req_ready   (cache_mem_ready  ),
        .mem_req_addr    (cache_mem_addr   ),
        .mem_req_rdata   (cache_mem_rdata  )
    );

    mem #(
    ) memory (
        .clk         (clk        ),
        .mem_valid   (cache_mem_valid  ),
        .mem_ready   (cache_mem_ready  ),
        .mem_addr    (cache_mem_addr   ),
        .mem_wdata   (proc_mem_wdata  ),
        .mem_wstrb   (proc_mem_wstrb  ),
        .mem_rdata   (cache_mem_rdata  )
    );

endmodule
