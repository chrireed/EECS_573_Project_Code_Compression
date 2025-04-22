//TODO: Make the logic here combinational (for a preloaded dictionary, we don't need this to be clocked...)
//We can make use of that saved cycle though.

//Inputs:
//key_data_in: Compressed key (index into LUT)
//val_lookup_in: Enter an uncompressed bitstring, returns existence in val_lookup_res.
module dictionary_field2 #(
//   parameter KEY_WIDTH  = 5,      // R TYPE
//   parameter VAL_WIDTH  = 10
    parameter KEY_WIDTH  = 6,       // I TYPE
    parameter VAL_WIDTH  = 12
  ) (
  //------------Input Ports--------------                        
  input  [KEY_WIDTH-1:0]   key_lookup_in, //Lookup this key (index bits / compressed bits)
  input  [VAL_WIDTH-1:0]   val_lookup_in, //lookup this value (uncompressed bits for field)
  //----------Output Ports--------------
  output reg [VAL_WIDTH-1:0]   val_out,  // found this value (uncompressed bits) for the compressed bits given.
  output reg [KEY_WIDTH-1:0]   key_out,  // found this value (compressed bits) for the uncompressed bits given.
  output reg                   val_lookup_result,  //is the uncompressed bits an entry in the table?
  //------------Init Ports--------
  input clk,
  input write_enable,
  input [VAL_WIDTH-1:0] write_val,
  input resetn
  );
  // Stored CAM memory (KEY_WIDTH entries, each 8-bit wide)
  reg [VAL_WIDTH-1:0] memory [2**KEY_WIDTH - 1:0];

  reg [KEY_WIDTH-1:0] write_idx;

  // Make the dictionary writeable so we can init it at startup
  always @(posedge clk) begin
      if(write_enable) begin
          memory[write_idx] <= write_val;
          write_idx <= write_idx + 1;
      end else begin 
          write_idx <= 0;
      end
      
  end

  integer i;
  
  // Dictionary lookup logic
  always @* begin
      val_out = memory[key_lookup_in];
      val_lookup_result = 1'b0;  
      key_out = 0;                  
      
      for (i = 0; i < (2**KEY_WIDTH); i = i + 1) begin
          if (memory[i] == val_lookup_in && ~val_lookup_result) begin
              val_lookup_result = 1'b1;
              key_out = i;   
          end
      end
  end

endmodule