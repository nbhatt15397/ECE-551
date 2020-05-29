module RAMqueue_tb ();

  logic clk;
  logic we;
  logic [8:0] waddr;
  logic [8:0] raddr;
  logic [7:0] wdata;
  logic [7:0] rdata;
  logic [7:0] mem [0:383];

/////////////////////////////////////////////////////////////////
/////////////////////Instantiate DUT/////////////////////////////
////////////////////////////////////////////////////////////////
RAMqueue iDUT (.clk(clk), .we(we), .waddr(waddr), .raddr(raddr), .wdata(wdata), .rdata(rdata), .mem(mem));

  //Setting up clk signal
  initial clk = 0;
  always #10 clk = ~clk; 

  initial begin
  //Case 1
  clk =0;
  we = 0;
  waddr = 9'h123;
  raddr = 9'h123;
  wdata=8'hAB;
  #1;

  @(posedge clk);
  we =1;           //AB is scheduled to be written at 0x123 addr in mem

  @(posedge clk); // AB is written to 0x123 at this clk edge 
  we =0;         //AB is read from 0x123 addr in mem
  raddr= 9'h123;

  @(posedge clk);
  #1;
     if (rdata !== 8'hAB) begin 
       $display ("Error: rdata is %h , but it should be 8'hAB", rdata);
       $stop();
     end


  //Case 2
  waddr = 9'h124;
  raddr = 9'h123;
  wdata = 8'hCD;
  #1;

  @(posedge clk);
  we = 1; //CD is scheduled to be written at 0x124 addr

  @(posedge clk); //CD is written at 0x124 addr in mem
  we = 0; //AB is read from 0x123 addr in mem b/c 0x123 was not written again
  raddr= 9'h123;

  @(posedge clk);
  #1;
     if (rdata !== 8'hAB) begin 
       $display ("Error: rdata is %h , but it should be 8'hAB", rdata);
       $stop();
     end

  //Case 3
  waddr = 9'h124;
  raddr = 9'h124;
  wdata = 8'hEF;
  #1;

  @(posedge clk);
  we = 0; //The value stored in raddr 0x124 is scheduled to be read into rdata 

  @(posedge clk); 
  we = 0; //CD is read from 0x124 addr in mem 

  @(posedge clk);
  #1;
     if (rdata !== 8'hCD) begin 
       $display ("Error: rdata is %h , but it should be 8'hCD", rdata);
       $stop();
     end
  $display ("YAHOOOO, your test has passed");
  $stop ();

  end
endmodule
