module CommMaster(clk, rst_n, snd_cmd, cmd, TX, cmd_cmplt);

	input clk, rst_n;  //Clock signal and synch low reset
	input snd_cmd;    //input of Control SM
	input [15:0] cmd; //Incoming 16 bit command
	output logic TX;        //Output connected to UART_tx module TX output
	output logic cmd_cmplt; //Output controlled by the Control SM

	//Internal signal definitions that serve as conenctions between fsm and UART transmitter
	logic tx_done;          //Output of UART-Tx block that is input of Control SM
	logic trmt; 			//SM output, connected to UART_tx input
	logic sel; 
	logic [7:0] tx_data_CM; //input to UART_tx coming through logic in CommMaster block
	logic [7:0] lower_byte; 

	////////////////////////////////////////////////////////
	///////////Instance of the UART TRANSMITTER////////////
	//////////////////////////////////////////////////////
	UART_tx DUT_UART_tx (.clk(clk),.rst_n(rst_n),.TX(TX),.trmt(trmt),.tx_data(tx_data_CM),.tx_done(tx_done)) ;

	/////////////////////////////////////////////////////////////
	//Flop to assign lower_byte of cmd to a snd_cmd enabled flop/
	/////////////////////////////////////////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin 
		if(snd_cmd)   lower_byte <= cmd[7:0] ; 
		else          lower_byte <= lower_byte;
	end

	//Models a mux that selects the low_byte or high 8 bytes of incoming cmd based on sel signal 
	assign tx_data_CM = sel ? cmd [15:8] : lower_byte ;

	//State definition using enum type 
	typedef enum reg [1:0] {IDLE, SEND_HIGH, SEND_LOW, CMD_SENT} state_t;
	state_t state, next_state;
	////////////FLOPPING Control SM STATES///////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if  (!rst_n)  state <= IDLE;
		else          state <= next_state; 
	end 
	///////////////////////////////////////////
	///////// FSM COMBINATIONAL BLCK ////////
	/////inputs: clk,rst,snd_cmd,tx_done;////   
	//////outputs: sel,trmt,cmd_cmplt; /////
	///////////////////////////////////////
	always_comb begin
	//Defaulting all outputs to 0
		next_state = IDLE;
		cmd_cmplt = 1'b0;
		trmt = 1'b0;
		sel = 1'b0;

		case (state) 
			IDLE:      if (snd_cmd) begin
						  trmt = 1'b1;
						  sel = 1'b1;
						  next_state = SEND_HIGH;
				   	   end 
				       else 
				       	  next_state = IDLE;

			SEND_HIGH: if (tx_done) begin
						  trmt = 1'b1;
						  next_state =SEND_LOW;
					   end
				       else
				          next_state = SEND_HIGH;

			SEND_LOW: if (tx_done) begin
						  next_state = CMD_SENT;
						  cmd_cmplt = 1'b1;
					   end
				       else
				          next_state = SEND_LOW ;

			CMD_SENT: if (snd_cmd) begin
						  trmt = 1'b1;
						  sel = 1'b1;
						  next_state = SEND_HIGH;
					   end
				       else if (!snd_cmd) begin
				       	  cmd_cmplt = 1'b1;
				          next_state = CMD_SENT;
				       end
		endcase 
	end 
    
endmodule