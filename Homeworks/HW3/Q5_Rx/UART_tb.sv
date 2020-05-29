module UART_tb ();

  logic clk, rst_n, RX, clr_rdy, rdy, trmt;
  logic [7:0] rx_data;  //Receives data from the receiver as output
  logic [7:0] tx_data; //Passes data into the transmitter as input 
  reg [8:0] x ;       //Variable used to count up values assigned to tx_data for testing

  //////////////////////////////////////////////////////////////////////////////////
  ////////////////////////INSTANTIATE DUT FOR UART UNIT/////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////

  UART iDut (.clk(clk), .rst_n(rst_n), .trmt(trmt), .tx_data(tx_data), .clr_rdy(clr_rdy), .tx_done(tx_done), .rdy(rdy), .rx_data(rx_data));


initial begin
	//Resetting all input signals so we can start from a fresh slate
	clk = 0;
	rst_n = 0;
	trmt = 0;
	clr_rdy = 0;
	tx_data = 0;
	#60;
	rst_n = 1;
        #20; 
	@(posedge clk);
        //Looping through all possible values of tx_data to check if they pass through the UART correctly
	@(posedge clk);
	  for(x = 0; x < 9'h100; x = x++) begin
            trmt = 1;
	    tx_data = x;
	    #15;
	    trmt = 0;	

	      @(posedge clk);
	      if (rdy) begin  //Only checks if rx_data and tx_data are equal when rdy is asserted because that is when all the bits have been receieved
	        if (rx_data != tx_data) begin
		   $display("THE VALUES OF RX_DATA AND TX_DATA DO NOT MATCH! YOU GOT rx_data = %h, tx_data = %h", rx_data, tx_data);
		   $stop;
	        end
              end
	  $display("WOOOOHOOOO!!! YOU PASSED THE TEST!!!!!!!!");
	  $stop;
           end
end
 
  always 
   #15 clk = ~clk;

endmodule