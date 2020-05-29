module ss_A2D_SM(clk,rst_n,strt_cnv,smp_eq_8,gt,clr_dac,inc_dac,
                 clr_smp,inc_smp,accum,cnv_cmplt);

  input clk,rst_n;			// clock and asynch reset
  input strt_cnv;			// asserted to kick off a conversion
  input smp_eq_8;			// from datapath, tells when we have 8 samples
  input gt;				// gt signal, has to be double flopped
  output reg clr_dac;			// clear the input counter to the DAC
  output reg inc_dac;			// increment the counter to the DAC
  output reg clr_smp;			// clear the sample counter
  output reg inc_smp;			// increment the sample counter
  output reg accum;			// asserted to make accumulator accumulate sample
  output reg cnv_cmplt;			// indicates when the conversion is complete


  /////////////////////////////////////////////////////////////////
  // You fill in the SM implementation. I want to see the use   //
  // of enumerated type for state, and proper SM coding style. //
  //////////////////////////////////////////////////////////////
	
  //Defining states using tyoedef for easier debugging	
  typedef enum reg [1:0] {IDLE, CNV, ACCUM} state_t;      
  state_t state, next_state;

   //Flopping the state assignments
  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)  state <= IDLE;
    else        state <= next_state;
  end

 //////////////////////////////////////////////////
///////////////////STATE MACHINE///////////////////
///////////////////////////////////////////////////
  always_comb begin

    //Assigning all output values to 0 to prevent latching 
    next_state = IDLE;  
    inc_dac = 1'b0;
    clr_smp = 1'b0;   
    inc_smp = 1'b0;
    accum = 1'b0;
    cnv_cmplt = 1'b0;
    clr_dac = 1'b0;        
  
    //Case statement for state selection 
    case(state)
	IDLE: if (strt_cnv) begin
		 clr_smp = 1'b1; 
                 clr_dac = 1'b1;      //Assert clr_dac and clr_smp signals after strt_cnv signal is asserted 
		 next_state = CNV;    //If start_cnv is assrted, the next state is CNV
              end
              else next_state = IDLE; //If start_cnv is not asserted, we stay in the IDLE state

	     
	CNV: if (!gt) begin            //When gt is unasserted, we remain in the CNV state and inc_dac remains 1
 		 inc_dac = 1'b1;
                 next_state = CNV;
	      end
	      else if(gt) begin      //Once gt is asserted, we move to ACCUM state, and assert accum signal
                 next_state = ACCUM;     
		 accum = 1'b1;               
	      end

	ACCUM: if (smp_eq_8) begin  //If smp_eq_8 is asserted, we move to the IDLE state and assert cnv_cmplt
		 cnv_cmplt = 1'b1;    
 		 next_state = IDLE;
	       end
              else if(!smp_eq_8) begin    
		 clr_dac = 1'b1;         
		 inc_smp = 1'b1;
		 next_state = CNV;
	       end
        //Default case is set to IDLE incase the FSM glitches 
        default: next_state = IDLE;

    endcase
  end 
  
					 
endmodule
  
					   