module trigger_logic(CH1Trig, CH2Trig, CH3Trig, CH4Trig, CH5Trig, protTrig, armed, set_capture_done, clk, rst_n, triggered);

  input clk, rst_n;  //Async Low Reset and Clk signal
  input CH1Trig, CH2Trig, CH3Trig, CH4Trig, CH5Trig, protTrig ; //Different channel signals that re fed from outside the trigger logic block
  input armed, set_capture_done;  //Other external signals that are inputs to our unit
  output reg triggered; //Output of the trigger logic from the flop
  reg trigger_input;

  // The combinational logic feeds into a flop designed by this block
  always @(posedge clk, negedge rst_n) begin
	if(~rst_n) //If rstt_n is set to 0, triggered is reset to value of 0 
    triggered <= 0;

	else 
    triggered <= trigger_input;
 end

  //Combinational logic required to set a signal trigger_input that feeds into the flop, If set_capture_done is asserted, value stored in triggered is knocked down 
  assign trigger_input = ~(set_capture_done | ~(triggered | (armed & (CH1Trig & CH2Trig & CH3Trig & CH4Trig & CH5Trig & protTrig))));

endmodule
