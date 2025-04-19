`timescale 1 ns / 1 ns


module dictionary_test;
  // Parameters
  parameter KEY_WIDTH = 3;
  parameter VAL_WIDTH = 7;

  // Inputs
  reg [KEY_WIDTH-1:0] key_lookup_in;
  reg [VAL_WIDTH-1:0] val_lookup_in;

  // Outputs
  wire [VAL_WIDTH-1:0] val_out;
  wire [KEY_WIDTH-1:0] key_out;
  wire                val_lookup_result;

  // Initialization
  reg clk;
  reg [VAL_WIDTH-1:0] write_val;
  reg write_enable;

  // Instantiate the dictionary module
  dictionary #(
    .KEY_WIDTH(KEY_WIDTH), 
    .VAL_WIDTH(VAL_WIDTH)
  ) uut (
    .key_lookup_in(key_lookup_in), 
    .val_lookup_in(val_lookup_in),
    .val_out(val_out), 
    .key_out(key_out), 
    .val_lookup_result(val_lookup_result),
    .clk(clk),
    .write_enable(write_enable),
    .write_val(write_val)
  );

  reg [VAL_WIDTH-1:0] dict_vals [2**KEY_WIDTH - 1:0];

  always #2 clk = ~clk;

  integer i;

  initial begin
    // Initialize inputs
    key_lookup_in = 0;
    val_lookup_in = 0;

    clk           = 0;
    write_enable  = 0;
    write_val     = 0;

    #4;
    $readmemb("tests/dictionary_test.mem", dict_vals);

    for(i = 0; i < 2**KEY_WIDTH; i = i +1) begin
        write_enable = 1;
        write_val = dict_vals[i];
        #4;
    end

    write_enable = 0;

    // Test a few cases
    #10; // wait for 10 time units
    key_lookup_in = 3'b000; // Test lookup for key 0
    // Expected val_out should be 2 (as per the initialization `memory[i] = i + 1`)
    #10;
    $display("Test 1: key_lookup_in = %b, val_out = %b", key_lookup_in, val_out);
    #10
    // Test if a value exists
    val_lookup_in = 7'b0010111; // Test lookup for value 7
    #10;
    $display("Test 2: val_lookup_in = %b, val_lookup_result = %b, key_out = %b", val_lookup_in, val_lookup_result, key_out);
    #10
    // Test another key
    key_lookup_in = 3'b111; // Test lookup for key 7
    #10;
    $display("Test 3: key_lookup_in = %b, val_out = %b", key_lookup_in, val_out);
    #10
    // Test if another value exists
    val_lookup_in = 7'b0010111; // Test lookup for value 2
    #10;
    $display("Test 4: val_lookup_in = %b, val_lookup_result = %b, key_out = %b", val_lookup_in, val_lookup_result, key_out);
    #10

    //     // Test a few cases
    // #10; // wait for 10 time units
    // key_lookup_in = 4'b0001; // Test lookup for key 1
    // // Expected val_out should be 2 (as per the initialization `memory[i] = i + 1`)
    // #10;
    // $display("Test 1: key_lookup_in = %b, val_out = %b", key_lookup_in, val_out);
    // #10
    // // Test if a value exists
    // val_lookup_in = 8'b00000101; // Test lookup for value 5
    // #10;
    // $display("Test 2: val_lookup_in = %b, val_lookup_result = %b, key_out = %b", val_lookup_in, val_lookup_result, key_out);
    // #10
    // // Test another key
    // key_lookup_in = 4'b0010; // Test lookup for key 2
    // #10;
    // $display("Test 3: key_lookup_in = %b, val_out = %b", key_lookup_in, val_out);
    // #10
    // // Test if another value exists
    // val_lookup_in = 8'b00000010; // Test lookup for value 2
    // #10;
    // $display("Test 4: val_lookup_in = %b, val_lookup_result = %b, key_out = %b", val_lookup_in, val_lookup_result, key_out);
    // #10
    // Finish simulation
    $finish;
  end
endmodule