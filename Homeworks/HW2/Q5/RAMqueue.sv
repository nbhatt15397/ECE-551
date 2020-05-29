module RAMqueue (clk, we, waddr, raddr, wdata, rdata, mem);
  
  //Parametrized values 
  parameter ENTRIES = 384 ;  // # of entries in the circular queue
  parameter LOG2 = 9 ;       // Width of Address bus 

  input logic clk, we;
  input logic [LOG2-1:0] waddr;
  input logic [LOG2-1:0] raddr;

  //RAM Queue stores data in the form of 8-bit words
  input logic [7:0] wdata; 
  output logic [7:0] rdata; 
  output logic [7:0] mem [0:ENTRIES-1]; //Memory is an array of entries that are 8 bits each

 always @(posedge clk) begin

   if (we) 
      mem[waddr] <= wdata; //Assigns the value to be written to the address in mem on next posedge clk
        
   else
      rdata <=  mem[raddr]; //Else outputs read value from memory present at raddr
  end 

endmodule