`timescale 1 ns / 1 ps

//`define WRITE_VCD
`define DEBUG_CACHE

module testbench;
    reg clk = 1;
    reg resetn = 0;
    wire trap;

    always #2 clk = ~clk;

    initial begin
        repeat (100) @(posedge clk);
        resetn <= 1;
    end

    // Memory wires
    wire        proc_mem_valid;
    wire        proc_mem_instr;
    wire        proc_mem_ready;
    wire [31:0] proc_mem_addr; 
    wire [31:0] proc_mem_wdata;
    wire [3:0]  proc_mem_wstrb;
    wire [31:0] proc_mem_rdata;

    wire        icache_valid;
    wire        icache_ready;
    wire [31:0] icache_addr; 
    wire [31:0] icache_rdata;

    wire        icache_mem_valid;
    wire        icache_mem_ready;
    wire [31:0] icache_mem_addr; 
    wire [31:0] icache_mem_rdata;

    wire        imem_valid;
    wire        imem_ready;
    wire [31:0] imem_addr; 
    wire [31:0] imem_rdata;

    wire        dmem_valid;
    wire        dmem_ready;
    wire [31:0] dmem_addr; 
    wire [31:0] dmem_wdata;
    wire [3:0]  dmem_wstrb;
    wire [31:0] dmem_rdata;

    // Trace wires
	wire        trace_valid;
	wire [35:0] trace_data;

    // Filenames and descriptors
    reg [239:0] program_memory_file;
    reg [239:0] program_trace_file;
    reg [239:0] memory_access_file;
    integer     trace_fd;
    integer     mem_access_fd;
    
    // Cache stat signals
    `ifdef DEBUG_CACHE
        wire        dbg_miss;   // From cache
        wire [31:0]  icache_occupancy;

        real dbg_imem_access_count = 0;
        real dbg_cache_miss_count = 0;
    `endif

    picorv32 #(
    ) proc (
        .clk         (clk        ),
        .resetn      (resetn     ),
        .trap        (trap       ),
        .trace_valid (trace_valid),
		.trace_data  (trace_data),
        .mem_valid   (proc_mem_valid  ),
        .mem_instr   (proc_mem_instr  ),
        .mem_ready   (proc_mem_ready  ),
        .mem_addr    (proc_mem_addr   ),
        .mem_wdata   (proc_mem_wdata  ),
        .mem_wstrb   (proc_mem_wstrb  ),
        .mem_rdata   (proc_mem_rdata  )
    );


    controller #(
    ) cache_controller (
        .clk(clk),
        .resetn(resetn),
        
        .proc_valid(icache_valid),
        .proc_ready(icache_ready),
        .proc_addr(icache_addr),
        .proc_rdata(icache_addr),

        .mem_req_valid(imem_valid),
        .mem_req_ready(imem_ready),
        .mem_req_addr(imem_addr),
        .mem_req_rdata(imem_req_rdata),

        .dict1_write_enable(dict1_write_enable),
        .dict1_write_val(dict1_write_val),

        .dict2_write_enable(dict2_write_enable),
        .dict2_write_val(dict2_write_val),

        .dict3_write_enable(dict3_write_enable),
        .dict3_write_val(dict3_write_val)
    );

    assign proc_mem_ready  = proc_mem_instr ? icache_ready : dmem_ready;
    assign proc_mem_rdata = proc_mem_instr ? icache_rdata : dmem_rdata;

    assign icache_valid = proc_mem_valid && proc_mem_instr;
    assign icache_addr  = proc_mem_addr;


    assign imem_valid = icache_mem_valid;
    assign imem_addr  = icache_mem_addr;
    assign icache_mem_ready = imem_ready;
    assign icache_mem_rdata = imem_rdata;


    imem #(
    ) instr_mem (
        .clk         (clk        ),
        .mem_valid   (imem_valid  ),
        .mem_ready   (imem_ready  ),
        .mem_addr    (imem_addr   ),
        .mem_rdata   (imem_rdata  )
    );

    assign dmem_valid = proc_mem_valid && !proc_mem_instr;
    assign dmem_addr  = proc_mem_addr;
    assign dmem_wdata = proc_mem_wdata;
    assign dmem_wstrb = proc_mem_wstrb;

    dmem #(
    ) data_mem (
        .clk         (clk        ),
        .mem_valid   (dmem_valid  ),
        .mem_ready   (dmem_ready  ),
        .mem_addr    (dmem_addr   ),
        .mem_wdata   (dmem_wdata  ),
        .mem_wstrb   (dmem_wstrb  ),
        .mem_rdata   (dmem_rdata  )
    );

    localparam MEM_SIZE = 1*1024*1024; //1MB

	initial begin
    
        // Load program into memory
        if ($value$plusargs("MEMORY=%s", program_memory_file)) begin
            $display("Loading memory file: %s", program_memory_file);
        end else begin
            $display("Loading default memory file: program.mem");
            program_memory_file = "program.mem";
        end
        $display("Loading RAM contents starting at: 0x%h", 0);
        $readmemh(program_memory_file, instr_mem.memory);
        $readmemh(program_memory_file, data_mem.memory);
        $display("Finished loading RAM contents ending at: 0x%h", MEM_SIZE - 1);

        
        // Open trace file
        if ($value$plusargs("TRACE=%s", program_trace_file)) begin
            $display("Using trace output file: %s", program_trace_file);
        end else begin
            $display("Using default writeback output file: trace.out");
            program_trace_file = "trace.out";
        end
        trace_fd = $fopen(program_trace_file, "w");
        
        
        // Open memaccess file
        if ($value$plusargs("MEMACCESS=%s", memory_access_file)) begin
            $display("Using memory access output file: %s", memory_access_file);
        end else begin
            $display("Using default memory access file: mem_access.out");
            memory_access_file = "mem_access.out";
        end
        mem_access_fd = $fopen(memory_access_file, "w");
        
        $display("=================================");
        $display("============BEGIN================");
        $display("=================================");
	end

    // Write to the trace file
    
    initial
    begin
        repeat (10) @(posedge clk);
        while (!trap) begin
            @(posedge clk);
            if (trace_valid)
                $fwrite(trace_fd, "%x\n", trace_data);
        end
        $fclose(trace_fd);
    end
    
    // Finish the program when we trap
    always @(posedge clk) begin
        if (resetn && trap) begin
            repeat (10) @(posedge clk);
            `ifdef DEBUG_CACHE
                // Print cache stats
                $display("\nIcache Statistics:");
                $display("Hits: %d, Misses: %d, Imem Accesses: %d",
                        dbg_imem_access_count - dbg_cache_miss_count,
                        dbg_cache_miss_count,
                        dbg_imem_access_count);
                $display("Miss rate: %f",
                        (dbg_cache_miss_count) / dbg_imem_access_count);
                $display("Icache occupancy: %d", icache_occupancy);
            `endif
            $display("=================================");
            $display("============TRAP=================");
            $display("=================================");
            $finish;
        end
    end

    always @(posedge clk) begin
        // Print memory access information upon a succsesful transaction
        if (proc_mem_valid & proc_mem_ready) begin
            //if ((proc_mem_wstrb_o == 4'h0) && (mem_rdata_o === 32'bx)) $display("READ FROM UNITIALIZED ADDR=%x", proc_mem_addr_o);

            if(proc_mem_addr == 32'h 1000_0000) $write("%c", proc_mem_wdata[7:0]);

            if(~(proc_mem_addr < MEM_SIZE) && (proc_mem_addr != 32'h 1000_0000)) begin
                $display("Tried to access mem outside MEM_SIZE: %h", proc_mem_addr);
                $finish;
            end

            if (|proc_mem_wstrb)
                $fwrite(mem_access_fd, "WR: ADDR=%x DATA=%x MASK=%b\n", proc_mem_addr, proc_mem_wdata, proc_mem_wstrb);
            else begin
                $fwrite(mem_access_fd, "RD: ADDR=%x DATA=%x%s\n", proc_mem_addr, proc_mem_rdata, proc_mem_instr ? " INSN" : "");
                // Count imem accesses
                `ifdef DEBUG_CACHE
                    if(proc_mem_instr)
                        dbg_imem_access_count <= dbg_imem_access_count + 1;
                `endif
                end

            if (^proc_mem_addr === 1'bx ||
                    (proc_mem_wstrb[0] && ^proc_mem_wdata[ 7: 0] == 1'bx) ||
                    (proc_mem_wstrb[1] && ^proc_mem_wdata[15: 8] == 1'bx) ||
                    (proc_mem_wstrb[2] && ^proc_mem_wdata[23:16] == 1'bx) ||
                    (proc_mem_wstrb[3] && ^proc_mem_wdata[31:24] == 1'bx)) begin
                $display("CRITICAL UNDEF MEM TRANSACTION");
                $finish;
            end
        end
    end

    // Cache stats
    `ifdef DEBUG_CACHE
        always @(posedge dbg_miss) begin
            dbg_cache_miss_count <= dbg_cache_miss_count + 1;
        end
    `endif

`ifdef WRITE_VCD
    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench.icache);
        //$dumpvars(0, testbench.proc);
    end
`endif


endmodule
