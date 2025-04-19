module controller #(
    //should add to 16 (currently)
    parameter FIELD1_KEY_WIDTH = 3,
    parameter FIELD2_KEY_WIDTH = 8,
    parameter FIELD3_KEY_WIDTH = 5,

    //should add to 32.
    parameter FIELD1_VAL_WIDTH = 7,
    parameter FIELD2_VAL_WIDTH = 15,
    parameter FIELD3_VAL_WIDTH = 10,

      parameter CACHE_SIZE = 1024,
    parameter NUM_BLOCKS = 4,
    parameter BLOCK_SIZE = 4
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
    input      [31:0]  mem_req_rdata


);

    // Interface to regular icache 
    wire            icache_proc_valid;
    wire            icache_proc_ready;
    wire    [31:0]  icache_proc_addr;
    wire    [31:0]  icache_proc_rdata;
    wire            icache_mem_req_valid;
    wire            icache_mem_req_ready;
    wire    [31:0]  icache_mem_req_addr;
    wire    [31:0]  icache_mem_req_rdata;

    // Interface to compressed icache
    wire            comp_proc_valid;
    wire            comp_proc_ready;
    wire    [31:0]  comp_proc_addr;
    wire    [(FIELD1_KEY_WIDTH + FIELD2_KEY_WIDTH + FIELD3_KEY_WIDTH) - 1:0]  comp_proc_rdata;
    wire            comp_mem_req_valid;
    reg            comp_mem_req_ready;
    wire    [31:0]  comp_mem_req_addr;
    reg    [(FIELD1_KEY_WIDTH + FIELD2_KEY_WIDTH + FIELD3_KEY_WIDTH) - 1:0]  comp_mem_req_rdata;

    // Interface to Compression Tables
    wire    [FIELD1_KEY_WIDTH-1:0]   field1_key_lookup; 
    wire    [FIELD1_VAL_WIDTH-1:0]       field1_val_lookup;
    wire                            field1_val_lookup_result;
    wire    [FIELD1_VAL_WIDTH-1:0]       field1_val_out;
    wire    [FIELD1_KEY_WIDTH-1:0]   field1_key_out;

    wire    [FIELD2_KEY_WIDTH-1:0]   field2_key_lookup; 
    wire    [FIELD2_VAL_WIDTH-1:0]       field2_val_lookup;
    wire                            field2_val_lookup_result;
    wire    [FIELD2_VAL_WIDTH-1:0]       field2_val_out;
    wire    [FIELD2_KEY_WIDTH-1:0]   field2_key_out;

    wire    [FIELD3_KEY_WIDTH-1:0]   field3_key_lookup; 
    wire    [FIELD3_VAL_WIDTH-1:0]       field3_val_lookup;
    wire                            field3_val_lookup_result;
    wire    [FIELD3_VAL_WIDTH-1:0]       field3_val_out;
    wire    [FIELD3_KEY_WIDTH-1:0]   field3_key_out;

    // Instantiate Regular ICache
    icache_comp #(
        .CACHE_SIZE(CACHE_SIZE),
        .NUM_BLOCKS(NUM_BLOCKS),
        .BLOCK_SIZE(BLOCK_SIZE)
    ) icache (
        .clk(clk),
        .resetn(resetn),
        .proc_valid(icache_proc_valid),
        .proc_ready(icache_proc_ready),
        .proc_addr(icache_proc_addr),
        .proc_rdata(icache_proc_rdata),
        .mem_req_valid(icache_mem_req_valid),
        .mem_req_ready(icache_mem_req_ready),
        .mem_req_addr(icache_mem_req_addr),
        .mem_req_rdata(icache_mem_req_rdata)
    );

    // Instantiate Compressed ICache
    icache_comp #(
        .CACHE_SIZE(CACHE_SIZE),
        .NUM_BLOCKS(NUM_BLOCKS),
        .BLOCK_SIZE(BLOCK_SIZE)
    ) comp_cache (
        .clk(clk),
        .resetn(resetn),
        .proc_valid(comp_proc_valid),
        .proc_ready(comp_proc_ready),
        .proc_addr(comp_proc_addr),
        .proc_rdata(comp_proc_rdata),
        .mem_req_valid(comp_mem_req_valid),
        .mem_req_ready(comp_mem_req_ready),
        .mem_req_addr(comp_mem_req_addr),
        .mem_req_rdata(comp_mem_req_rdata)
    );

    // Instantiate Dictionary for Field1
    dictionary #(
        .KEY_WIDTH(FIELD1_KEY_WIDTH),
        .VAL_WIDTH(FIELD1_VAL_WIDTH)
    ) dict1 (
        .key_lookup_in(field1_key_lookup),
        .val_lookup_in(field1_val_lookup),
        .val_out(field1_val_out),
        .key_out(field1_key_out),
        .val_lookup_result(field1_val_lookup_result)
    );

    // Instantiate Dictionary for Field2
    dictionary #(
        .KEY_WIDTH(FIELD2_KEY_WIDTH),
        .VAL_WIDTH(FIELD2_VAL_WIDTH)
    ) dict2 (
        .key_lookup_in(field2_key_lookup),
        .val_lookup_in(field2_val_lookup),
        .val_out(field2_val_out),
        .key_out(field2_key_out),
        .val_lookup_result(field2_val_lookup_result)
    );

    // Instantiate Dictionary for Field3
    dictionary #(
        .KEY_WIDTH(FIELD3_KEY_WIDTH),
        .VAL_WIDTH(FIELD3_VAL_WIDTH)
    ) dict3 (
        .key_lookup_in(field3_key_lookup),
        .val_lookup_in(field3_val_lookup),
        .val_out(field3_val_out),
        .key_out(field3_key_out),
        .val_lookup_result(field3_val_lookup_result)
    );

    reg   icache_hit_last_cycle;
    reg   [32:0] icache_proc_addr_latched;

    reg     field1_val_lookup_result_latched;
    reg     field2_val_lookup_result_latched;
    reg     field3_val_lookup_result_latched;

    reg    [FIELD1_KEY_WIDTH-1:0] field1_key_found_latched;
    reg    [FIELD2_KEY_WIDTH-1:0] field2_key_found_latched;
    reg    [FIELD3_KEY_WIDTH-1:0] field3_key_found_latched;
    
    wire    [31:0] decompressedInst;
    
    //connect caches to processor.
    assign icache_proc_valid = proc_valid;
    assign icache_proc_addr = proc_addr;
    
    //compressed valid needs to be held another cycle so we can process the actual instruction and "return it from memory"
    assign comp_proc_valid = proc_valid | icache_hit_last_cycle;
    assign comp_proc_addr = proc_valid ? proc_addr : icache_hit_last_cycle ? icache_proc_addr_latched : 32'b0;

    assign proc_ready = icache_proc_ready | comp_proc_ready;
    assign decompressedInst = {field3_val_out[9:3],field2_val_out[14:5],field3_val_out[2:0],field2_val_out[4:0],field1_val_out[6:0]};
    assign proc_rdata = icache_proc_ready ? icache_proc_rdata : (comp_proc_ready ? 
    decompressedInst : 32'b0);

    assign field1_key_lookup = comp_proc_rdata[FIELD1_KEY_WIDTH -1 :0];
    assign field2_key_lookup = comp_proc_rdata[(FIELD2_KEY_WIDTH + FIELD1_KEY_WIDTH) -1 : FIELD1_KEY_WIDTH];
    assign field3_key_lookup = comp_proc_rdata[15 : FIELD1_KEY_WIDTH + FIELD2_KEY_WIDTH];
    
    //only actual icache should be interfacing with memory....
    assign icache_mem_req_ready = mem_req_ready;
    assign icache_mem_req_rdata = mem_req_rdata;
    assign mem_req_valid = icache_mem_req_valid;
    assign mem_req_addr = icache_mem_req_addr;

    assign field1_val_lookup = icache_proc_rdata[6:0];
    assign field2_val_lookup = {icache_proc_rdata[24:15],icache_proc_rdata[11:7]};
    assign field3_val_lookup = {icache_proc_rdata[31:25],icache_proc_rdata[14:12]};

    always @(posedge clk) begin

        icache_hit_last_cycle <= icache_proc_ready;
        icache_proc_addr_latched <= icache_proc_addr;

        comp_mem_req_ready <= 1'b0;
        field1_val_lookup_result_latched <= field1_val_lookup_result;
        field2_val_lookup_result_latched <= field2_val_lookup_result;
        field3_val_lookup_result_latched <= field3_val_lookup_result;

        field1_key_found_latched <= field1_key_out;
        field2_key_found_latched <= field2_key_out;
        field3_key_found_latched <= field3_key_out;

        //if inst *can* be compressed and the compressed cache doesn't have it already, return it to the compressed cache.
        if (icache_hit_last_cycle && ~comp_proc_ready && field1_val_lookup_result_latched && field2_val_lookup_result_latched && field3_val_lookup_result_latched) begin
                comp_mem_req_ready <= 1'b1;
                comp_mem_req_rdata <= {field3_key_found_latched, field2_key_found_latched, field1_key_found_latched};
        end
        
        

       

        end
        endmodule


