module controller #(
    //should add to 16 (currently)
    parameter FIELD1_IDX_SIZE = 3,
    parameter FIELD2_IDX_SIZE = 8,
    parameter FIELD3_IDX_SIZE = 5,

    //should add to 32.
    parameter FIELD1_SIZE = 7,
    parameter FIELD2_SIZE = 15,
    parameter FIELD3_SIZE = 10
)(
    input            clk,
    input            resetn,

    input               proc_valid,
    output wire         proc_ready,
    input        [31:0] proc_addr,
    output wire   [31:0] proc_rdata,

    // Interface to memory
    output wire         mem_req_valid,
    input              mem_req_ready,
    output wire [31:0]  mem_req_addr,
    input      [31:0]  mem_req_rdata,

    // Interface to regular icache 
    output   wire            icache_proc_valid,
    input                icache_proc_ready,
    output  wire    [31:0]   icache_proc_addr,
    input    [31:0]   icache_proc_rdata,
    input             icache_mem_req_valid,
    output  wire            icache_mem_req_ready,
    input  [31:0]     icache_mem_req_addr,
    output   wire   [31:0]   icache_mem_req_rdata,

    // Interface to compressed icache
    output   wire            comp_proc_valid,
    input             comp_proc_ready,
    output  wire    [31:0]   comp_proc_addr,
    input    [(FIELD1_IDX_SIZE + FIELD2_IDX_SIZE + FIELD3_IDX_SIZE) - 1:0]  comp_proc_rdata,
    input             comp_mem_req_valid,
    output  reg       comp_mem_req_ready,
    input  [31:0]     comp_mem_req_addr,
    output reg     [(FIELD1_IDX_SIZE + FIELD2_IDX_SIZE + FIELD3_IDX_SIZE) - 1:0]    comp_mem_req_rdata,

    // Interface to Compression Tables
    output  wire     [FIELD1_IDX_SIZE-1:0]       field1_key_lookup, 
    output  wire    [FIELD1_SIZE-1:0]           field1_val_lookup,
    input                                    field1_val_lookup_res,
    input        [FIELD1_SIZE-1:0]           field1_val_found,
    input        [FIELD1_IDX_SIZE-1:0]       field1_key_found,

    output  wire     [FIELD2_IDX_SIZE-1:0]       field2_key_lookup, 
    output   wire   [FIELD2_SIZE-1:0]           field2_val_lookup,
    input                                    field2_val_lookup_res,
    input        [FIELD2_SIZE-1:0]           field2_val_found,
    input        [FIELD2_IDX_SIZE-1:0]       field2_key_found,

    output  wire    [FIELD3_IDX_SIZE-1:0]       field3_key_lookup, 
    output  wire    [FIELD3_SIZE-1:0]           field3_val_lookup,
    input                                    field3_val_lookup_res,
    input        [FIELD3_SIZE-1:0]           field3_val_found,
    input        [FIELD3_IDX_SIZE-1:0]       field3_key_found
);

    //latch the icache hit so we can update the compressed cache in the next cycle if applicable
    reg   icache_hit_last_cycle;
    reg   [32:0] icache_proc_addr_latched;

    reg     field1_val_lookup_res_latched;
    reg     field2_val_lookup_res_latched;
    reg     field3_val_lookup_res_latched;

    reg    [FIELD1_IDX_SIZE-1:0] field1_key_found_latched;
    reg    [FIELD2_IDX_SIZE-1:0] field2_key_found_latched;
    reg    [FIELD3_IDX_SIZE-1:0] field3_key_found_latched;
    wire    [31:0] decompressedInst;
    //connect caches to processor.
    assign icache_proc_valid = proc_valid;
    assign icache_proc_addr = proc_addr;
    
    //compressed valid needs to be held another cycle so we can process the actual instruction and "return it from memory"
    assign comp_proc_valid = proc_valid | icache_hit_last_cycle;
    assign comp_proc_addr = proc_valid ? proc_addr : icache_hit_last_cycle ? icache_proc_addr_latched : 32'b0;

    assign proc_ready = icache_proc_ready | comp_proc_ready;
    assign decompressedInst = {field3_val_found[9:3],field2_val_found[14:5],field3_val_found[2:0],field2_val_found[4:0],field1_val_found[6:0]};
    assign proc_rdata = icache_proc_ready ? icache_proc_rdata : (comp_proc_ready ? 
    decompressedInst : 32'b0);

    assign field1_key_lookup = comp_proc_rdata[FIELD1_IDX_SIZE -1 :0];
    assign field2_key_lookup = comp_proc_rdata[(FIELD2_IDX_SIZE + FIELD1_IDX_SIZE) -1 : FIELD1_IDX_SIZE];
    assign field3_key_lookup = comp_proc_rdata[15 : FIELD1_IDX_SIZE + FIELD2_IDX_SIZE];
    //only actual icache should be interfacing with memory....
    assign icache_mem_req_ready = mem_req_ready;
    assign icache_mem_req_rdata = mem_req_rdata;
    assign mem_req_valid = icache_mem_req_valid;
    assign mem_req_addr = icache_mem_req_addr;

    assign field1_val_lookup = icache_proc_rdata[6:0];
    assign field2_val_lookup = {icache_proc_rdata[24:15],icache_proc_rdata[11:7]};
    assign field3_val_lookup = {icache_proc_rdata[31:25],icache_proc_rdata[14:12]};

    always @(posedge clk) begin
    //if PC in regular cache hits, we don't care about anything else:
    //latching because on a regular icache miss, the icache signals the processor for one cycle with proc_ready...we want to grab the values (instruction) based on
    //the last complete transaction

        icache_hit_last_cycle <= icache_proc_ready;
        icache_proc_addr_latched <= icache_proc_addr;

        comp_mem_req_ready <= 1'b0;
        field1_val_lookup_res_latched <= field1_val_lookup_res;
        field2_val_lookup_res_latched <= field2_val_lookup_res;
        field3_val_lookup_res_latched <= field3_val_lookup_res;

        field1_key_found_latched <= field1_key_found;
        field2_key_found_latched <= field2_key_found;
        field3_key_found_latched <= field3_key_found;

        //if inst *can* be compressed and the compressed cache doesn't have it already, return it to the compressed cache.
        if (icache_hit_last_cycle && ~comp_proc_ready && field1_val_lookup_res_latched && field2_val_lookup_res_latched && field3_val_lookup_res_latched) begin
                comp_mem_req_ready <= 1'b1;
                comp_mem_req_rdata <= {field3_key_found_latched, field2_key_found_latched, field1_key_found_latched};
        end
        
        

       

        end
        endmodule


