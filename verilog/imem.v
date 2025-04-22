module imem #(
    parameter MEM_SIZE = 1*1024*1024
) (

`ifdef DEBUG_CACHE
    output        dbg_mem_valid,
`endif
    input            clk,
    input            mem_valid,
	output reg       mem_ready,

	input        [31:0] mem_addr,
	output reg   [31:0] mem_rdata
);

    `ifdef DEBUG_CACHE
        assign  dbg_mem_valid = mem_valid;
    `endif
    reg [31:0] memory [0:MEM_SIZE/4-1];

    always @(posedge clk) begin
        mem_ready <= 0;
        // Handle a memory access
        if (mem_valid && !mem_ready) begin
            mem_ready <= 1;
            mem_rdata <= memory[mem_addr >> 2];
        end
    end
endmodule