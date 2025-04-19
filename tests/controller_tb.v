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
    .mem_req_rdata(mem_req_rdata)
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
    #10;
    proc_valid = 1;
    proc_addr = 32'h00000000; // Issue a request to the controller
    //cache miss. Respond with data that should theoretically fit in the compressed cache as well.
    #40 
    mem_req_ready <= 1;
    mem_req_rdata <= 32'h0002202; // Provide fake memory data
    #10
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