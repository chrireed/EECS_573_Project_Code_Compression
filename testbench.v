`timescale 1 ns / 1 ps

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
    wire proc_mem_valid_o;
    wire proc_mem_instr_o;
    wire proc_mem_ready_i;
    wire [31:0] proc_mem_addr_o;
    wire [31:0] proc_mem_wdata_o;
    wire [3:0]  proc_mem_wstrb_o;
    wire [31:0] proc_mem_rdata_i;

    wire mem_valid_i;
    wire mem_instr_i;
    wire mem_ready_o;
    wire [31:0] mem_addr_i;
    wire [31:0] mem_wdata_i;
    wire [3:0]  mem_wstrb_i;
    wire [31:0] mem_rdata_o;

    // Trace wires
	wire        trace_valid;
	wire [35:0] trace_data;

    // Filenames and descriptors
    reg [239:0] program_memory_file;
    reg [239:0] program_trace_file;
    reg [239:0] memory_access_file;
    integer     trace_fd;
    integer     mem_access_fd;
    

    picorv32 #(
    ) proc (
        .clk         (clk        ),
        .resetn      (resetn     ),
        .trap        (trap       ),
        .trace_valid (trace_valid),
		.trace_data  (trace_data),
        .mem_valid   (proc_mem_valid_o  ),
        .mem_instr   (proc_mem_instr_o  ),
        .mem_ready   (proc_mem_ready_i  ),
        .mem_addr    (proc_mem_addr_o   ),
        .mem_wdata   (proc_mem_wdata_o  ),
        .mem_wstrb   (proc_mem_wstrb_o  ),
        .mem_rdata   (proc_mem_rdata_i  )
    );

    mem #(
    ) memory (
        .clk         (clk        ),
        .mem_valid   (mem_valid_i  ),
        .mem_instr   (mem_instr_i  ),
        .mem_ready   (mem_ready_o  ),
        .mem_addr    (mem_addr_i   ),
        .mem_wdata   (mem_wdata_i  ),
        .mem_wstrb   (mem_wstrb_i  ),
        .mem_rdata   (mem_rdata_o  )
    );


    assign mem_valid_i      = proc_mem_valid_o;
    assign mem_instr_i      = proc_mem_instr_o;
    assign proc_mem_ready_i = mem_ready_o;
    assign mem_addr_i       = proc_mem_addr_o;
    assign mem_wdata_i      = proc_mem_wdata_o;
    assign mem_wstrb_i      = proc_mem_wstrb_o;
    assign proc_mem_rdata_i = mem_rdata_o;

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
        $readmemh(program_memory_file, memory.memory);
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
            $display("=================================");
            $display("============TRAP=================");
            $display("=================================");
            $finish;
        end
    end

    always @(posedge clk) begin
        // Print memory access information upon a succsesful transaction
        if (proc_mem_valid_o & proc_mem_ready_i) begin
            //if ((proc_mem_wstrb_o == 4'h0) && (mem_rdata_o === 32'bx)) $display("READ FROM UNITIALIZED ADDR=%x", proc_mem_addr_o);

            if(proc_mem_addr_o == 32'h 1000_0000) $write("%c", proc_mem_wdata_o[7:0]);

            if(~(proc_mem_addr_o < MEM_SIZE) && (proc_mem_addr_o != 32'h 1000_0000)) $display("Tried to access mem outside MEM_SIZE: %h", proc_mem_addr_o);

            if (|proc_mem_wstrb_o)
                $fwrite(mem_access_fd, "WR: ADDR=%x DATA=%x MASK=%b\n", proc_mem_addr_o, proc_mem_wdata_o, proc_mem_wstrb_o);
            else 
                $fwrite(mem_access_fd, "RD: ADDR=%x DATA=%x%s\n", proc_mem_addr_o, proc_mem_rdata_i, proc_mem_instr_o ? " INSN" : "");

            if (^proc_mem_addr_o === 1'bx ||
                    (proc_mem_wstrb_o[0] && ^proc_mem_wdata_o[ 7: 0] == 1'bx) ||
                    (proc_mem_wstrb_o[1] && ^proc_mem_wdata_o[15: 8] == 1'bx) ||
                    (proc_mem_wstrb_o[2] && ^proc_mem_wdata_o[23:16] == 1'bx) ||
                    (proc_mem_wstrb_o[3] && ^proc_mem_wdata_o[31:24] == 1'bx)) begin
                $display("CRITICAL UNDEF MEM TRANSACTION");
                $finish;
            end
        end
    end

// `ifdef WRITE_VCD
//     initial begin
//         $dumpfile("testbench.vcd");
//         $dumpvars(0, testbench);
//     end
// `endif


endmodule
