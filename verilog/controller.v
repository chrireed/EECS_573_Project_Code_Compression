module controller #(
    //should add to 16 (currently)
    parameter FIELD1_IDX_SIZE = 3
    parameter FIELD2_IDX_SIZE = 8
    parameter FIELD3_IDX_SIZE = 5

    //should add to 32.
    parameter FIELD1_SIZE = 7
    parameter FIELD2_SIZE = 15
    parameter FIELD3_SIZE = 10
)(
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

    // Interface to regular icache 
    output               icache_proc_valid,
    input                icache_proc_ready,
    output      [31:0]   icache_proc_addr,
    input reg   [31:0]   icache_proc_rdata,
    input reg            icache_mem_req_valid,
    output               icache_mem_req_ready,
    input reg [31:0]     icache_mem_req_addr,
    output      [31:0]   icache_mem_req_rdata

    // Interface to compressed icache
    output               comp_proc_valid,
    input reg            comp_proc_ready,
    output      [31:0]   comp_proc_addr,
    input reg   [(FIELD1_IDX_SIZE + FIELD2_IDX_SIZE + FIELD3_IDX_SIZE) - 1:0]  comp_proc_rdata,
    input reg            comp_mem_req_valid,
    output               comp_mem_req_ready,
    input reg [31:0]     comp_mem_req_addr,
    output      [(FIELD1_IDX_SIZE + FIELD2_IDX_SIZE + FIELD3_IDX_SIZE) - 1:0]    comp_mem_req_rdata

   

    // Interface to Compression Tables

    output       [FIELD1_IDX_SIZE-1:0]       field1_key_data; 
    output       [FIELD1_SIZE-1:0]           field1_val_lookup;
    input        [FIELD1_SIZE-1:0]           field1_val;
    input                                    field1_val_lookup_res;

    output       [FIELD2_IDX_SIZE-1:0]       field2_key_data; 
    output       [FIELD2_SIZE-1:0]           field2_val_lookup;
    input        [FIELD2_SIZE-1:0]           field2_val;
    input                                    field2_val_lookup_res;

    output       [FIELD3_IDX_SIZE-1:0]         field3_key_data; 
    output       [FIELD3_SIZE-1:0]             field3_val_lookup;
    input        [FIELD3_SIZE-1:0]             field3_val;
    input                                      field3_val_lookup_res;

)

    //latch the icache hit so we can update the compressed cache in the next cycle if applicable
    reg icache_hit; 
    reg [31:0] icache_proc_addr_latched;
    reg [31:0] decompressedInst;

    //connect caches to processor.
    assign icache_proc_valid = proc_valid;
    assign icache_proc_addr = proc_addr;
    

    assign comp_proc_valid = proc_valid | icache_hit;
    assign comp_proc_addr = proc_valid ? proc_addr : icache_hit ? icache_proc_addr_latched : 32'b0;

    assign proc_ready = icache_proc_ready | comp_cache_ready;
    assign proc_rdata = icache_proc_ready ? icache_proc_rdata : (comp_cache_ready ? decompressedInst : 32'b0);

    
    //only actual icache should be interfacing with memory....
    assign icache_mem_req_ready = mem_req_ready;
    assign icache_mem_req_rdata = mem_req_rdata;
    assign mem_req_valid = icache_mem_req_valid;
    assign mem_req_addr = icache_mem_req_addr;

    
    //connect compressed icache to custom control signals...



    always @(posedge clk) begin
    //if PC in regular cache hits, we don't care about anything else:
        if (icache_ready) begin 
            // pass on the instruction to the processor...hardwired already so we don't waste a cycle 
            icache_hit <= icache_proc_ready;
            icache_proc_addr_latched <= icache_proc_addr;
            //if inst *can* be compressed and the compressed cache doesn't have it already, return it to the compressed cache.
            //the actual inputs of this is done in the top level...
            if (~comp_cache_ready && field1_val_lookup_res && field2_val_lookup_res && field3_val_lookup_res) begin
                comp_mem_req_ready <= 1'b1;
                comp_mem_req_rdata <= {field1_val, field2_val, field3_val};
            end
            
        
        end
        //if PC in compressed cache but not the regular cache, decompress the instruction:
        if (comp_cache_ready) begin
            // decompress the instruction and pass to the processor.
            decompressedInst = 
        end

       
        
        
        end


