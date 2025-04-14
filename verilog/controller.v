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
    input reg   [(FIELD1_IDX_SIZE + FIELD2_IDX_SIZE + FIELD3_IDX_SIZE) - 1:0]   comp_proc_rdata,

    input reg         mem_req_valid,
    output              mem_req_ready,
    input reg     [31:0]  mem_req_addr,
    output        [31:0]  mem_req_rdata


    // Interface to Compression Tables

    output       [FIELD1_IDX_SIZE-1:0]       field1_key_data_in; 
    output       [FIELD1_SIZE-1:0]           field1_val_lookup_in;
    input        [FIELD1_SIZE-1:0]           field1_val_out;
    input                                    field1_val_lookup_res;

    output       [FIELD2_IDX_SIZE-1:0]       field2_key_data_in; 
    output       [FIELD2_SIZE-1:0]           field2_val_lookup_in;
    input        [FIELD2_SIZE-1:0]           field2_val_out;
    input                                    field2_val_lookup_res;

    output       [FIELD3_IDX_SIZE-1:0]         field3_key_data_in; 
    output       [FIELD3_SIZE-1:0]             field3_val_lookup_in;
    input        [FIELD3_SIZE-1:0]             field3_val_out;
    input                                      field3_val_lookup_res;

)
    //connect regular icache to memory as usual...
    assign icache_proc_valid = proc_valid;
    assign icache_proc_addr = proc_addr;

    assign proc_ready = icache_proc_ready;
    assign proc_rdata = icache_proc_rdata;

    assign icache_mem_req_ready = mem_req_ready;
    assign icache_mem_req_rdata = mem_req_rdata;
    
    assign mem_req_valid = icache_mem_req_valid;
    assign mem_req_addr = icache_mem_req_addr;


    //connect compressed icache to custom control signals...


    always @(posedge clk) begin
    //if PC in regular cache hits, we don't care about anything else:
        if (icache_ready) begin 
            // pass on the instruction to the processor 
            
        end
        //if PC in compressed cache but not the regular cache, decompress the instruction:
        if (comp_cache_ready) begin
            // decompress the instruction and pass to the processor.
        end

        if (~comp_cache_ready && field1_lookup() && field2_lookup() && field3_lookup()) begin

        //if inst *can* be compressed and the compressed cache doesn't have it already, return it to the compressed cache.
        
        
        
        end


