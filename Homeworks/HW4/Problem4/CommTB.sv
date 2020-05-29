module CommTB ();
	logic clk, rst_n;          //clock signal and asynch low reset connection 
	logic snd_cmd;            //Sort of an enable for cmd_to_snd
	logic [15:0] cmd_to_send; //Internal tb signal that defines the command to be sent 
	logic cmd_cmplt;         //Internal signal connected to CommMaster that is asserted when a command is sent succesfully to UART_Wrapper
	logic TX_RX;             //Internal connection that connects the TX port of CommMaster to the RX port of UART_Wrapper 
	logic [15:0] cmd_rcvd;   //Is the output of the TB, to be checked against the cmd_to_send
	logic cmd_rdy;          //Is asserted once the command has been completely received by the UART_Wrapper

	//////////////////////////////////////////////////////////////////
	//////Instantiating modules for UART_wrapper and CommMaster//////
	////////////////////////////////////////////////////////////////
	CommMaster iDUT_CommMaster_CommTB (.clk(clk), .snd_cmd(snd_cmd), .rst_n(rst_n), .cmd(cmd_to_send), .cmd_cmplt(cmd_cmplt), .TX(TX_RX)) ;
	UART_wrapper iDUT_UART_wrapper_CommTB (.clk(clk), .rst_n(rst_n), .cmd_rdy(cmd_rdy), .cmd(cmd_rcvd), .RX(TX_RX), .send_resp(), .resp(), .clr_cmd_rdy(), .resp_sent(), .TX());

	initial begin
		//Resetting 
		clk = 1'b0; 
		rst_n = 1'b0;
		repeat(30)@(posedge clk);
		rst_n = 1'b1; //Deassert Reset
		repeat(30)@(posedge clk);

		///////////////////////////////////////
		//Test Command 1 sent into CommMaster//
		//////////////////////////////////////	
		@(negedge clk) 
		snd_cmd = 1'b1; 
		cmd_to_send = 16'h0101; 
		@(negedge clk)
		snd_cmd = 1'b0; 

		/*When the command has been fully received and trasmitted through the UART_wrapper, 
		it asserts cmd_cmplt and so the check needs to be conducted at that point*/
		 @(posedge cmd_cmplt)
			if(cmd_rcvd != cmd_to_send) begin
				$display("Error, your received signal did not match the command sent. You received: %h , The command sent was: %h", cmd_rcvd, cmd_to_send );
				$stop;
			end
		repeat(10)@(posedge clk);

		/////////////////////////////////////////
		//Test Command II sent into CommMaster//
		////////////////////////////////////////
		@(negedge clk) 
		snd_cmd = 1'b1; 
		cmd_to_send = 16'habcd; 
		@(negedge clk)
		snd_cmd = 1'b0;
		
		@(posedge cmd_cmplt)
			if(cmd_rcvd != cmd_to_send) begin
				$display("Error, your received signal did not match the command sent. You received: %h , The command sent was: %h", cmd_rcvd, cmd_to_send );
				$stop;
			end

		$display("YOOOOHOOO! Test Passed!!!!!");
		$stop;

	end 

	/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
	/*~~~~~~~Defining the clk signal~~~~~~~*/
	/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
	always #10 clk = ~clk ; 

endmodule 
