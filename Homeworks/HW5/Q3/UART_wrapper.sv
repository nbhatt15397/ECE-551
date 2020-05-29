module UART_wrapper (clk, rst_n, send_resp, RX, resp, clr_cmd_rdy, cmd_rdy, resp_sent, TX, cmd); 

	input logic clk, rst_n; //Clock signal and Asynch low reset   	 
	input logic send_resp;  //Input signal connected to trmt port in UART
	input logic RX ;       //Incoming signal connected to RX in the UART module
	input logic [7:0] resp; //Incoming 8 bit data to be transmitted throught the tx_data port in UART
	input logic clr_cmd_rdy; //Input to the whole wrapper that clears the cmd_rdy
	output logic cmd_rdy;   //Output of Wrapper SM when cmd is ready with 16 bits
	output logic resp_sent; //Output signal connected to tx_done in UART
	output logic TX;		//Data transmitted out of the UART module 
	output reg [15:0] cmd; //Final Data received is stored in this register

	logic rx_rdy; 			//Input to UART Wrapper SM connected to clr_rdy input in UART, When this signal is asserted, the FSM transfers incoming byte of data
	logic [7:0] rec_data;  //Date received from the rx_data port of the Transceiver
	logic [7:0] high_byte; //Register that holds the first 8 bytes to be stored in cmd register
	logic set_cmd_rdy;	  //Signal that needs to be asserted when we need to set cmd_rdy 
	logic load_sel;       //Output from UART Wrapper SM , Select signal for the mux that transmits rec_data signal for high_byte being transmitted
    logic clr_rdy;	      //Output from UART Wrapper SM connected to clr_rdy input in UART

    /////////////////////////////////
	//Instantiating the Transciever//
	/////////////////////////////////
	UART iDUT (.clk(clk) ,.rst_n(rst_n), .RX(RX), .TX(TX), .rx_rdy(rx_rdy), .clr_rx_rdy(clr_rdy), .rx_data(rec_data), 
		  	   .trmt(send_resp), .tx_data(resp), .tx_done(resp_sent));

	typedef enum reg {IDLE, HIGHBYTE} state_t ;
	state_t state, next_state; 

	/////////////////////////////////
	//Defining flop for Wrapper FSM//
	/////////////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if  (!rst_n)  state <= IDLE;
		else          state <= next_state; 
	end 

	/////////////////////////////////////////////////////////
	//Defining Combinational logic for the Wrapper FSM Blck//
	////////////////////////////////////////////////////////
	always_comb begin
		//Defaulting all outputs to 0
		next_state = IDLE;
		clr_rdy = 0;
		load_sel = 0;
		set_cmd_rdy = 0; 

		case (state) 
			IDLE :   if (rx_rdy) begin
				   		clr_rdy = 1'b1;
				   		load_sel = 1'b1; //Asserted because [15:8] of the cmd come in first
				   		next_state = HIGHBYTE;
				   	end
				   	else
						next_state = IDLE;
			HIGHBYTE:
					if (rx_rdy) begin
						clr_rdy = 1;
						set_cmd_rdy = 1;
						next_state = IDLE;
					end
				    else begin
						next_state = HIGHBYTE;
					end 
		endcase 
	end 

	/////////////////////////////////////////////////////////////
    //Logic to store the first 8 bytes of the incoming 16 bytes//
    /////////////////////////////////////////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) 
			high_byte <= 8'h0;
		else if (load_sel)
			high_byte <= rec_data;
		else 
			high_byte <= high_byte;
	end

    /* cmd signal is the concatenation of the high byte received and stored in
     the high_byte register and the rec_data signal that transmits the low byte of data */
	assign cmd = {high_byte, rec_data}; 

	//////////////////////
	//cmd_rdy flop logic//
	//////////////////////
	always_ff @(posedge clk, negedge rst_n) begin 
		if(!rst_n) 
			 cmd_rdy <= 1'b0 ;
		//cmd_rdy is cleared either when we start first transmission of byte, or when clr_cmd_rdy an external signal is connected
		else if (clr_cmd_rdy | load_sel) 
			 cmd_rdy <= 1'b0 ;
		else if (set_cmd_rdy) //comes from SM 
		 	cmd_rdy <= 1'b1 ;
		else
			cmd_rdy <= cmd_rdy;
	end

endmodule 