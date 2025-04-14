//TODO: Make the logic here combinational (for a preloaded dictionary, we don't need this to be clocked...)
//We can make use of that saved cycle though.

//Inputs:
//key_data_in: Compressed key (index into LUT)
//val_lookup_in: Enter an uncompressed bitstring, returns existence in val_lookup_res.
module dictionary #(
  parameter KEY_WIDTH  = 4,
  parameter VAL_WIDTH  = 8)
  (
  //------------Input Ports--------------
  input                    clk;                          
  input                    lookup_enable;   
  input  [KEY_WIDTH-1:0]   key_data_in; 
  input  [VAL_WIDTH-1:0]   val_lookup_in;
  //----------Output Ports--------------
  output reg [VAL_WIDTH-1:0]   val_out;
  output reg                   val_lookup_res;  
  //------------Internal Variables--------
  )
  // Stored CAM memory (KEY_WIDTH entries, each 8-bit wide)
  reg [VAL_WIDTH-1:0] cam_memory [2**KEY_WIDTH - 1:0];

  integer i;

  initial begin
    val_lookup_res = 1'b0;
    val_out <= {VAL_WIDTH{1'b0}};  // VAL_WIDTH-bit zero

    //insert mem init stuff here
  end


  always @(posedge clk) begin
    val_out <= memory[key_data_in];

    if (lookup_enable) begin
    for (i = 0; i < (2**KEY_WIDTH); i = i + 1) begin
        if (cam_memory[i] == key_data_in) begin
            val_lookup_res <= 1;
        end
    end
    end
  end

endmodule