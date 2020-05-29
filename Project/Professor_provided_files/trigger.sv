module trigger(clk,rst_n,CH1TrigCfg,CH2TrigCfg,CH3TrigCfg,CH4TrigCfg,CH5TrigCfg,
               TrigCfg,CH1L,CH2L,CH3L,CH1Lff5,CH1Hff5,CH2Lff5,CH2Hff5,CH3Lff5,
			   CH3Hff5,CH4Lff5,CH4Hff5,CH5Lff5,CH5Hff5,armed,maskL,maskH,matchL,
			   matchH,baud_cntH,baud_cntL,set_capture_done,triggered);
			   
  input clk,rst_n;					// system clock and active low asynch reset
  input [4:0] CH1TrigCfg;			// Trig Config register bits for CH1
  input [4:0] CH2TrigCfg;			// Trig Config register bits for CH2
  input [4:0] CH3TrigCfg;			// Trig Config register bits for CH3
  input [4:0] CH4TrigCfg;			// Trig Config register bits for CH4
  input [4:0] CH5TrigCfg;			// Trig Config register bits for CH5
  input [3:0] TrigCfg;				// lower 4-bits of Trig Config register
  input CH1L,CH2L,CH3L;				// Raw channel inputs for protocol triggering
  input CH1Lff5,CH1Hff5;			// Sampled channel inputs for CH1 triggering
  input CH2Lff5,CH2Hff5;			// Sampled channel inputs for CH2 triggering
  input CH3Lff5,CH3Hff5;			// Sampled channel inputs for CH3 triggering
  input CH4Lff5,CH4Hff5;			// Sampled channel inputs for CH4 triggering
  input CH5Lff5,CH5Hff5;			// Sampled channel inputs for CH5 triggering
  input armed;						// needed for edge triggering on channels
  input [7:0] maskL,maskH;			// set bits indicate don't care in comparison vs match
  input [7:0] matchL,matchH;    	// match inputs for protocol triggering
  input [7:0] baud_cntH,baud_cntL;	// used to set baud rate for UART protocol
  input set_capture_done;			// knocks down triggered output
  output triggered;					// the output...trigger condition has been seen
  
  wire CH1Trig,CH2Trig,CH3Trig,CH4Trig,CH5Trig;
  wire protTrig,trig_set;
  
  //// Instantiate trigger logic for CH1 ////
  chnnl_trig iCH1(.clk(clk),.armed(armed),.CH_Hff5(CH1Hff5),.CH_Lff5(CH1Lff5),
                  .CH_TrigCfg(CH1TrigCfg),.CH_Trig(CH1Trig));

  //// Instantiate trigger logic for CH2 ////
  chnnl_trig iCH2(.clk(clk),.armed(armed),.CH_Hff5(CH2Hff5),.CH_Lff5(CH2Lff5),
                  .CH_TrigCfg(CH2TrigCfg),.CH_Trig(CH2Trig));

  //// Instantiate trigger logic for CH3 ////
  chnnl_trig iCH3(.clk(clk),.armed(armed),.CH_Hff5(CH3Hff5),.CH_Lff5(CH3Lff5),
                  .CH_TrigCfg(CH3TrigCfg),.CH_Trig(CH3Trig));

  //// Instantiate trigger logic for CH4 ////
  chnnl_trig iCH4(.clk(clk),.armed(armed),.CH_Hff5(CH4Hff5),.CH_Lff5(CH4Lff5),
                  .CH_TrigCfg(CH4TrigCfg),.CH_Trig(CH4Trig));

  //// Instantiate trigger logic for CH5 ////
  chnnl_trig iCH5(.clk(clk),.armed(armed),.CH_Hff5(CH5Hff5),.CH_Lff5(CH5Lff5),
                  .CH_TrigCfg(CH5TrigCfg),.CH_Trig(CH5Trig));				  
				  
  //// Instantiate protocol trigger logic ////
  prot_trig iProt(.clk(clk),.rst_n(rst_n),.CH1L(CH1Lff5),.CH2L(CH2Lff5),.CH3L(CH3Lff5),
                  .TrigCfg(TrigCfg),.maskH(maskH),.maskL(maskL),.matchH(matchH),
				  .matchL(matchL),.baud_cntH(baud_cntH),.baud_cntL(baud_cntL),
				  .protTrig(protTrig));

  //// Instantiate combined trigger_logic ////
  trigger_logic iTRG(.clk(clk),.rst_n(rst_n),.CH1Trig(CH1Trig),.CH2Trig(CH2Trig),
                     .CH3Trig(CH3Trig),.CH4Trig(CH4Trig),.CH5Trig(CH5Trig),
					 .protTrig(protTrig),.armed(armed),.set_capture_done(set_capture_done),
					 .triggered(triggered));


endmodule	  
	  