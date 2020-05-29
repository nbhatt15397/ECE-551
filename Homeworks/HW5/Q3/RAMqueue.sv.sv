module RAMqueue (clk, we, waddr, raddr, wdata, rdata); 

parameter ENTRIES = 384 ;
parameter LOG2 = 9 ;

input logic clk, we;
input logic [LOG2-1:0] waddr;
input logic [LOG2-1:0] raddr;

input logic [7:0] wdata; //data stored as 8-bit words
output logic [7:0] rdata; //data stored as 8-bit words

logic [7:0] mem [0:ENTRIES-1];

always @(posedge clk) begin

  if (we == 1) 
         mem[waddr] <= wdata;
        
  else
        rdata <=  mem[raddr];
end
endmodule	