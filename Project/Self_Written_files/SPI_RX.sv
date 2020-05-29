module SPI_RX (clk, rst_n, SS_n, SCLK, MOSI, edg, len8, mask, match, SPItrig);

	input  clk, rst_n; //clk signal and asynch low reset 
	input  SS_n;
	input  SCLK;
	input  MOSI;
	input  edg; 
	input  len8; //Is high if the incoming MOSI signal is 1 byte long and is low if it's 2 bytes long
	input  [15:0] mask, match; //mask: DontCare bits, match bits: are the actual bits the incoming data is to be compared against 
	output SPItrig; 

	reg [15:0] shft_reg; //Holds incoming MOSI signal while the different bits are shifted
	wire data_comp_high_result, data_comp_low_result; //Defines the comparison result for low and high bits
	reg SS_n_ff1, SCLK_ff1, MOSI_ff1 ,SS_n_ff2, SCLK_ff2, MOSI_ff2 ,SS_n_ff3, SCLK_ff3, MOSI_ff3; 

	wire SCLK_rise_edge, SCLK_fall_edge; //Detects rising and falling edges of incoming SCLK signal 
	reg shift, done; 
	logic edge_detect;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//////////Instantiating two instances of data_compare to compare the high and low 8 bits of the shft_reg against match//////////
	////////////////////////////Data is only compared when the done signal from the FSM is asserted/////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	data_comp higher_8_bits (.prot_trig(data_comp_high_result) ,.match(match[15:8]) ,.mask(mask[15:8]) ,.serial_vld(done) ,.serial_data(shft_reg[15:8]));

	data_comp lower_8_bits (.prot_trig(data_comp_low_result) ,.match(match[7:0]) ,.mask(mask[7:0]) ,.serial_vld(done) ,.serial_data(shft_reg[7:0]));
	
	//Defining state variables 
	typedef enum reg {IDLE, RX} state_t;
	state_t state, next_state;

	/////////////////////////////////
	/// Detecting rise/fall of SCLK//
	/////////////////////////////////
	assign SCLK_fall_edge = (!SCLK_ff2 && SCLK_ff3) ? 1'b1 : 1'b0 ;
	assign SCLK_rise_edge = (SCLK_ff2 && !SCLK_ff3) ? 1'b1 : 1'b0 ; 
	//We determine what SCLK edge to shift on based on edg value
	assign edge_detect = edg ? SCLK_rise_edge : SCLK_fall_edge;  
	//Ouput signal assserted if either both the hgh and low bytes match or low byte matches and len8 =1
	assign SPItrig = (data_comp_high_result | len8) & data_comp_low_result  ; 

	/////////////////////////////////////////////////////
	//Always block modelling the MOSI sampling logic////
	///////////////////////////////////////////////////
	always @(posedge clk or negedge rst_n) begin
		if (~rst_n)         
			shft_reg <= 16'b0;
		else if (shift)     
			shft_reg <= {shft_reg[14:0], MOSI_ff3};
		else 		    
			shft_reg <= shft_reg;
	end

	///////////////////////////////////////////
	//Double Flopping Asynch Inputs of module//
	///////////////////////////////////////////
	always_ff @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			MOSI_ff1 <= 1'b0;
			MOSI_ff2 <= 1'b0;
			MOSI_ff3 <= 1'b0;
			SS_n_ff1 <= 1'b0;
			SS_n_ff2 <= 1'b0;
			SS_n_ff3 <= 1'b0;
			SCLK_ff1 <= 1'b0; 
			SCLK_ff2 <= 1'b0;
			SCLK_ff3 <= 1'b0;
		end 
		else begin
			MOSI_ff1 <= MOSI;
			MOSI_ff2 <=	MOSI_ff1;
			MOSI_ff3 <= MOSI_ff2;
			SS_n_ff1 <= SS_n;
			SS_n_ff2 <= SS_n_ff1;
			SS_n_ff3 <= SS_n_ff2;
			SCLK_ff1 <= SCLK;
			SCLK_ff2 <= SCLK_ff1;
			SCLK_ff3 <= SCLK_ff2;
		end
	end 

	
	//////////////////////////////
    //Implement state register //
    /////////////////////////////
	always_ff @(posedge clk or negedge rst_n) begin
		if(~rst_n)
			state <= IDLE;
		else
			state <= next_state;
	end
	/////////////////////////////////////
   //Implement SM that controls output//
   ////////////////////////////////////
   always_comb begin
   	//Defaulting outputs
   	shift = 1'b0;
   	done = 1'b0; 
   	next_state = state; 

   	case (state)
   		IDLE:  if (~SS_n_ff3) 
   					next_state = RX; //When SS_n is low, move to next state
   		       
   		RX:    if (edge_detect) begin	
   					shift = 1'b1; 
   					next_state = RX; 
   		       end
   			   else if (SS_n_ff3) begin
   			   		done = 1'b1 ;
   			   		next_state = IDLE;
   		       end 
   	endcase
   end
endmodule
