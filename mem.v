module mem #(
    parameter MEM_SIZE = 1*1024*1024
) (
    input            clk,
    input            mem_valid,
	input            mem_instr,
	output reg       mem_ready,

	input        [31:0] mem_addr,
	input        [31:0] mem_wdata,
	input        [ 3:0] mem_wstrb,
	output reg   [31:0] mem_rdata
);

    reg [31:0] memory [0:MEM_SIZE/4-1];

    always @(posedge clk) begin
        mem_ready <= 0;
        // Handle a memory access
        if (mem_valid && !mem_ready) begin
            mem_ready <= 1;
            mem_rdata <= 'bx;
            if ((|mem_wstrb)) begin
                if(mem_addr != 32'h 1000_0000) begin
                    if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
                    if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
                    if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
                    if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
                end
            end else begin
                mem_rdata <= memory[mem_addr >> 2];
            end
        end
    end
endmodule