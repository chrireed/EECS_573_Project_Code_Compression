`timescale 1ns / 1ps

module controller_tb;

  // Parameters for cache and dictionary configurations
  parameter FIELD1_KEY_WIDTH = 3;
  parameter FIELD1_VAL_WIDTH = 7;
  parameter FIELD2_KEY_WIDTH = 8;
  parameter FIELD2_VAL_WIDTH = 15;
  parameter FIELD3_KEY_WIDTH = 5;
  parameter FIELD3_VAL_WIDTH = 10;

  parameter FIELD1_SIZE = 7;
  parameter FIELD2_SIZE = 15;
  parameter FIELD3_SIZE = 10;

  parameter CACHE_SIZE = 1024;
  parameter NUM_BLOCKS = 4;
  parameter BLOCK_SIZE = 4;

  // Testbench signals
  reg clk;
  reg resetn;
  reg proc_valid;
  wire proc_ready;
  reg [31:0] proc_addr;
  wire [31:0] proc_rdata;

  wire mem_req_valid;
  reg mem_req_ready;
  wire [31:0] mem_req_addr;
  reg [31:0] mem_req_rdata;

  // Outputs from dictionary
  wire [FIELD1_VAL_WIDTH-1:0] field1_val_out;
  wire [FIELD1_KEY_WIDTH-1:0] field1_key_out;
  wire                        field1_val_lookup_result;

  wire [FIELD2_VAL_WIDTH-1:0] field2_val_out;
  wire [FIELD2_KEY_WIDTH-1:0] field2_key_out;
  wire                        field2_val_lookup_result;

  wire [FIELD3_VAL_WIDTH-1:0] field3_val_out;
  wire [FIELD3_KEY_WIDTH-1:0] field3_key_out;
  wire                        field3_val_lookup_result;

  // Cache interface wires
  wire icache_proc_valid;
  wire icache_proc_ready;
  wire [31:0] icache_proc_addr;
  wire [31:0] icache_proc_rdata;
  wire icache_mem_req_valid;
  wire icache_mem_req_ready;
  wire [31:0] icache_mem_req_addr;
  wire [31:0] icache_mem_req_rdata;

  wire comp_proc_valid;
  wire comp_proc_ready;
  wire [31:0] comp_proc_addr;
  wire [(FIELD1_KEY_WIDTH + FIELD2_KEY_WIDTH + FIELD3_KEY_WIDTH) - 1 : 0] comp_proc_rdata;
  wire comp_mem_req_valid;
  wire comp_mem_req_ready;
  wire [31:0] comp_mem_req_addr;
  wire [(FIELD1_KEY_WIDTH + FIELD2_KEY_WIDTH + FIELD3_KEY_WIDTH) - 1 : 0] comp_mem_req_rdata;

  // Dictionary lookup wires
  wire [FIELD1_KEY_WIDTH-1:0] field1_key_lookup;
  wire [FIELD1_VAL_WIDTH-1:0] field1_val_lookup;
  wire [FIELD2_KEY_WIDTH-1:0] field2_key_lookup;
  wire [FIELD2_VAL_WIDTH-1:0] field2_val_lookup;
  wire [FIELD3_KEY_WIDTH-1:0] field3_key_lookup;
  wire [FIELD3_VAL_WIDTH-1:0] field3_val_lookup;

  // Dummy Memory for simulation purposes
  reg [31:0] fake_memory[0:255];
  integer mem_idx;

  // Instantiate the Controller
  controller #(
    .FIELD1_IDX_SIZE(FIELD1_KEY_WIDTH),
    .FIELD2_IDX_SIZE(FIELD2_KEY_WIDTH),
    .FIELD3_IDX_SIZE(FIELD3_KEY_WIDTH),
    .FIELD1_SIZE(FIELD1_SIZE),
    .FIELD2_SIZE(FIELD2_SIZE),
    .FIELD3_SIZE(FIELD3_SIZE)
  ) uut (
    .clk(clk),
    .resetn(resetn),
    .proc_valid(proc_valid),
    .proc_ready(proc_ready),
    .proc_addr(proc_addr),
    .proc_rdata(proc_rdata),
    .mem_req_valid(mem_req_valid),
    .mem_req_ready(mem_req_ready),
    .mem_req_addr(mem_req_addr),
    .mem_req_rdata(mem_req_rdata),
    // Connect to icache
    .icache_proc_valid(icache_proc_valid),
    .icache_proc_ready(icache_proc_ready),
    .icache_proc_addr(icache_proc_addr),
    .icache_proc_rdata(icache_proc_rdata),
    .icache_mem_req_valid(icache_mem_req_valid),
    .icache_mem_req_ready(icache_mem_req_ready),
    .icache_mem_req_addr(icache_mem_req_addr),
    .icache_mem_req_rdata(icache_mem_req_rdata),
    // Connect to comp_cache
    .comp_proc_valid(comp_proc_valid),
    .comp_proc_ready(comp_proc_ready),
    .comp_proc_addr(comp_proc_addr),
    .comp_proc_rdata(comp_proc_rdata),
    .comp_mem_req_valid(comp_mem_req_valid),
    .comp_mem_req_ready(comp_mem_req_ready),
    .comp_mem_req_addr(comp_mem_req_addr),
    .comp_mem_req_rdata(comp_mem_req_rdata),
    // Dictionary connections for field1
    .field1_key_lookup(field1_key_lookup),
    .field1_val_lookup(field1_val_lookup),
    .field1_val_lookup_res(field1_val_lookup_result),
    .field1_val_found(field1_val_out),
    .field1_key_found(field1_key_out),
    // Dictionary connections for field2
    .field2_key_lookup(field2_key_lookup),
    .field2_val_lookup(field2_val_lookup),
    .field2_val_lookup_res(field2_val_lookup_result),
    .field2_val_found(field2_val_out),
    .field2_key_found(field2_key_out),
    // Dictionary connections for field3
    .field3_key_lookup(field3_key_lookup),
    .field3_val_lookup(field3_val_lookup),
    .field3_val_lookup_res(field3_val_lookup_result),
    .field3_val_found(field3_val_out),
    .field3_key_found(field3_key_out)
  );

  // Instantiate Regular ICache
  icache_1wa #(
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

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // Clock signal with a period of 10 time units (100 MHz)
  end

  // Reset and simulation stimulus
  initial begin
    // Reset sequence
    resetn = 0;
    #10 resetn = 1; // De-assert reset after 10ns

    // Initialize inputs
    proc_valid = 0;
    proc_addr = 32'h0;
    mem_req_ready = 0;

    // Stimulate inputs
    #20;
    proc_valid = 1;
    proc_addr = 32'h00000000; // Issue a request to the controller
    //cache miss. Respond with data that should theoretically fit in the compressed cache as well.
    #40 
    mem_req_ready <= 1;
    mem_req_rdata <= 32'h0002202; // Provide fake memory data
    #40
    proc_valid <= 0;
    #20;
    proc_valid = 1;
    proc_addr = 32'h00000000; // Issue a request to the controller
    //cache hit. Both caches should be responding with data...
    #40 

    #40


    // Finish the simulation after verifying behavior
    #100;
    $finish;
  end

endmodule