module SPI_RX_tb ();
	logic clk, rst_n;
	logic [15:0] tx_data; //Input of SPI_TX
	logic wrt; 
	logic len8; //only needs to work for len8=0 (i.e. length 16) as said by prof 
	logic MOSI;
	logic SCLK;
	logic SS_n;
	logic done; //output of SPI_TX
	logic SPItrig; //output of SPI_RX
	logic [15:0] match, mask;
	logic edg; 
	logic pos_edge;
	logic pass; //reg to help determine if test was passed  
	
	///////////////////////////////////////////////////////
	/////////Instantiatiating SPI_rx and SPI_tx///////////
	/////////////////////////////////////////////////////
	SPI_TX tx1_tb (.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .wrt(wrt), .done(done), .tx_data(tx_data), .MOSI(MOSI), .pos_edge(pos_edge), .width8(len8));
	SPI_RX rx1_tb (.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .edg(edg) ,.len8(len8) ,.mask(mask) ,.match(match) ,.SPItrig(SPItrig));
     // (serial_data | mask) == (match | mask) ---> match
	initial begin
		//Resetting
		clk = 1'b0;
		rst_n = 1'b0;
		repeat(5)@(posedge clk);
		rst_n = 1;
		repeat(5)@(posedge clk);
		///////////Test 1a : edg =1, tx_data and match don't match////////////
		pass = 1'b0;
		len8 = 1'b0;
		edg = 1'b1;
		pos_edge = 1'b0;
		repeat(20)@(negedge clk);
		tx_data = 16'h0001; //tx_data | mask =  0001
		mask = 16'h0000;
		match = 16'h0000; //mask | match = 0000
		repeat(5)@(posedge clk);
		wrt = 1'b1;
		repeat(2)@(negedge clk);
		wrt = 1'b0;
		repeat(2)@(posedge clk);

			while (!done) begin 
				#1;	
    			if (SPItrig == 1) begin
        			 $display("Error: SPItrig was asserted even when match and tx_data were different");
        			 $stop;
        		end	
        	end

        ////////////Test 1b :edg = 1, tx_data and match will match////////////
        tx_data = 16'h0010;
		mask = 16'h0000;  
		match = 16'h0010; 
		repeat(5)@(posedge clk);
        pass = 1'b0;
		len8 = 1'b0;
		edg = 1'b1;
		pos_edge = 1'b0;
		repeat(50)@(negedge clk);
		wrt = 1'b1;
		repeat(2)@(negedge clk);
		wrt = 1'b0;
		repeat(2)@(posedge clk);

			while (!done) begin 
				#10;
				if (SPItrig == 1 && pass != 1) begin
        			 $display("PASSED TEST: SPItrig asserted b/c match and tx_data are same after considering mask bits");
        			 pass = 1;
        		end	
        	end
        	if(pass != 1) begin
        		$display("Error: tx_data and mask were same but still SPItri was not asserted");
        		$stop;
        	end 

       /////////Test 2a: edg =0, tx_data and match will not match
        pass = 1'b0;
		len8 = 1'b0;
		edg = 1'b0;
		pos_edge = 1'b1;
		repeat(20)@(negedge clk);
		tx_data = 16'h0001; //tx_data | mask =  16'h0101
		mask = 16'h0100;
		match = 16'h0000; //mask | match = 16'h0100
		repeat(5)@(posedge clk);
		wrt = 1'b1;
		repeat(2)@(negedge clk);
		wrt = 1'b0;
		repeat(2)@(posedge clk);

			while (!done) begin 
				#1;	
    			if (SPItrig == 1) begin
        			 $display("Error: SPItrig was asserted even when match and tx_data were different");
        			 $stop;
        		end	
        	end

       /////////Test 2b:edg =0, tx_data and match will match
        tx_data = 16'h0010;
		mask = 16'h1010;  //tx_data | mask = 16'h1010
		match = 16'h1000; //match | mask = 16'h1010
		repeat(5)@(posedge clk);
        pass = 1'b0;
		len8 = 1'b0;
		edg = 1'b0;
		pos_edge = 1'b1;
		repeat(50)@(negedge clk);
		wrt = 1'b1;
		repeat(2)@(negedge clk);
		wrt = 1'b0;
		repeat(2)@(posedge clk);

			while (!done) begin 
				#10;
				if (SPItrig == 1 && pass != 1) begin
        			 $display("PASSED TEST: SPItrig asserted b/c match and tx_data are same after considering mask bits");
        			 pass = 1;
        		end	
        	end
        	if(pass != 1) begin
        		$display("Error:tx_data and mask were same but still SPItri was not asserted");
        		$stop;
        	end 
       $display("YAHOOO!!!! All the tests passed!!!!");
       $stop;
	end

	///////////////////////
	///Creating clk sig////
	///////////////////////
	always 
		#10 clk = ~clk; 

endmodule 