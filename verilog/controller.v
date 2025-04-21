module controller #(
    //should add to 16 (currently)
    parameter FIELD1_KEY_WIDTH = 3,
    parameter FIELD2_KEY_WIDTH = 8,
    parameter FIELD3_KEY_WIDTH = 5,

    //should add to 32.
    parameter FIELD1_VAL_WIDTH = 7,
    parameter FIELD2_VAL_WIDTH = 15,
    parameter FIELD3_VAL_WIDTH = 10,

      parameter CACHE_SIZE = 4*1024,
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
    input      [31:0]  mem_req_rdata,

    input dict1_write_enable,
    input [FIELD1_VAL_WIDTH-1:0] dict1_write_val,

    input dict2_write_enable,
    input [FIELD2_VAL_WIDTH-1:0] dict2_write_val,

    input dict3_write_enable,
    input [FIELD3_VAL_WIDTH-1:0] dict3_write_val
);

    localparam NUM_LINES   = CACHE_SIZE / (NUM_BLOCKS * BLOCK_SIZE);
    localparam INDEX_BITS  = $clog2(NUM_LINES);
    localparam OFFSET_BITS = $clog2(NUM_BLOCKS);
    localparam BYTE_OFFSET_BITS = $clog2(BLOCK_SIZE);
    localparam TAG_BITS    = 32 - INDEX_BITS - OFFSET_BITS - BYTE_OFFSET_BITS;


    // Interface to regular icache 
    wire            icache_proc_valid;
    wire            icache_proc_ready;
    wire    [31:0]  icache_proc_addr;
    wire    [31:0]  icache_proc_rdata;
    wire            icache_mem_req_valid;
    reg            icache_mem_req_ready;
    wire    [31:0]  icache_mem_req_addr;
    wire    [32*NUM_BLOCKS - 1:0]  icache_mem_req_rdata;
    wire icache_cache_miss;

    // Interface to compressed icache
    wire comp_cache_miss;
    wire            comp_proc_valid;
    wire            comp_proc_ready;
    wire    [31:0]  comp_proc_addr;
    wire    [(FIELD1_KEY_WIDTH + FIELD2_KEY_WIDTH + FIELD3_KEY_WIDTH) - 1:0]  comp_proc_rdata;
    wire            comp_mem_req_valid;
    reg            comp_mem_req_ready;
    wire    [31:0]  comp_mem_req_addr;
    reg    [(FIELD1_KEY_WIDTH + FIELD2_KEY_WIDTH + FIELD3_KEY_WIDTH)*NUM_BLOCKS - 1:0]  comp_mem_req_rdata;

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
    icache_1wa_wide #(
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
    icache_1wa_wide #(
        .CACHE_SIZE(CACHE_SIZE),
        .NUM_BLOCKS(NUM_BLOCKS),
        .BLOCK_SIZE(BLOCK_SIZE)
    ) icache_comp (
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
        .val_lookup_result(field1_val_lookup_result),
        .write_enable(dict1_write_enable),
        .write_val(dict1_write_val)
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
        .val_lookup_result(field2_val_lookup_result),
        .write_enable(dict2_write_enable),
        .write_val(dict2_write_val)
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
        .val_lookup_result(field3_val_lookup_result),
        .write_enable(dict3_write_enable),
        .write_val(dict3_write_val)
    );

    reg   controller_cache_miss;
    reg   icache_hit_last_cycle;

    wire    [31:0] decompressedInst;
    
    reg [31:0] icache_buffer [0:NUM_BLOCKS-1];
    reg [(FIELD1_KEY_WIDTH + FIELD2_KEY_WIDTH + FIELD3_KEY_WIDTH) - 1 : 0] comp_cache_buffer [0:NUM_BLOCKS-1];


    //connect caches to processor.
    assign icache_proc_valid = proc_valid;
    assign icache_proc_addr = proc_addr;
    
    //compressed valid needs to be held another cycle so we can process the actual instruction and "return it from memory"
    assign comp_proc_valid = proc_valid ;
    assign comp_proc_addr = proc_addr;

    assign proc_ready = icache_proc_ready | comp_proc_ready;
    assign decompressedInst = {field3_val_out[9:3],field2_val_out[14:5],field3_val_out[2:0],field2_val_out[4:0],field1_val_out[6:0]};
    assign proc_rdata = icache_proc_read ? icache_proc_rdata : comp_proc_ready ? decompressedInst : 32'b0;

    assign field1_key_lookup = comp_proc_rdata[FIELD1_KEY_WIDTH -1 :0];
    assign field2_key_lookup = comp_proc_rdata[(FIELD2_KEY_WIDTH + FIELD1_KEY_WIDTH) -1 : FIELD1_KEY_WIDTH];
    assign field3_key_lookup = comp_proc_rdata[15 : FIELD1_KEY_WIDTH + FIELD2_KEY_WIDTH];

    assign icache_mem_req_rdata = icache_buffer; 
    assign comp_mem_req_rdata = comp_cache_buffer;

    reg compressible;

    assign field1_val_lookup = mem_req_rdata[6:0];
    assign field2_val_lookup = {mem_req_rdata[24:15],mem_req_rdata[11:7]};
    assign field3_val_lookup = {mem_req_rdata[31:25],mem_req_rdata[14:12]};

    
    always @(posedge clk) begin
        comp_mem_req_ready <= 1'b0;
        icache_mem_req_ready <= 1'b0;
        controller_cache_miss <= proc_valid & icache_mem_req_valid & comp_mem_req_valid;

        //both caches don't have the instruction...
        if(controller_cache_miss) begin
            mem_req_addr  <= {proc_req_addr[31:OFFSET_BITS + BYTE_OFFSET_BITS], write_block, {BYTE_OFFSET_BITS{1'b0}}};
            if(~mem_req_ready) begin
                // Initiate a read transaction with mem
                mem_req_valid <= 1;
            end else begin
                // Mem has data on bus, read it in
                icache_buffer[write_block] <= mem_req_rdata;
                //can all instructions so far be compressed?
                compressible <= compressible & field1_val_lookup_result & field2_val_lookup_result & field3_val_lookup_result;
                if (compressible & field1_val_lookup_result & field2_val_lookup_result & field3_val_lookup_result) begin
                    comp_cache_buffer[write_block] <= {field3_key_found, field2_key_found, field1_key_found};
                end

                mem_req_valid     <= 0;
            end

                // Check if we've recieved all blocks of data
            if(write_block == NUM_BLOCKS - 1) begin
                    controller_cache_miss <= 0;
                    if (compressible) begin
                        comp_mem_req_ready = 1'b1;
                    end

                    else begin
                        icache_mem_req_ready = 1'b1;
                    end
            end
            else begin
                write_block <= write_block + 1;
            end // end if write_block == OFFSET_BITS - 1

        end 

        end else begin 
            comp_cache_miss      <= 0;
            write_block <= 0;
    end
    // end if cache miss
    endmodule


