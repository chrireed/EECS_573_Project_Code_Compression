module imem_wide #(
    parameter MEM_SIZE = 1*1024*1024,
    parameter NUM_BLOCKS = 4
) (
    input            clk,
    input            mem_valid,
	output reg       mem_ready,

	input        [31:0] mem_addr,
	output reg   [32*NUM_BLOCKS - 1:0] mem_rdata
);
    localparam OFFSET_BIT_SHIFT = $clog2(NUM_BLOCKS);

    reg [32*NUM_BLOCKS-1:0] memory [0:MEM_SIZE/(4*NUM_BLOCKS)-1];

    always @(posedge clk) begin
        mem_ready <= 0;
        // Handle a memory access
        if (mem_valid && !mem_ready) begin
            mem_ready <= 1;
            mem_rdata <= memory[mem_addr >> (2 + OFFSET_BIT_SHIFT)];
        end
    end
endmodule