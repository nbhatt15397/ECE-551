module trigger_logic (clk, rst_n, CH1Trig, CH2Trig, CH3Trig, CH4Trig, CH5Trig, protTrig, armed, set_capture_done, triggered);

  input clk, rst_n;  //Async Low Reset and Clk signal
  input CH1Trig, CH2Trig, CH3Trig, CH4Trig, CH5Trig, protTrig ; //Different channel signals that re fed from outside the trigger logic block
  input armed, set_capture_done;  //Other external signals that are inputs to our unit
  output reg triggered; //Output of the trigger logic from the flop
  reg trigger_input;  //Local Signal

   //Combinational logic required to set a signal trigger_input that feeds into the flop
   assign trigger_input = armed && CH1Trig && CH2Trig && CH3Trig && CH4Trig && CH5Trig && protTrig; //The triggered signal output can only be set if armed is set

  // The combinational logic feeds into a flop designed by this block
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        triggered <= 1'b0;     //If rstt_n is set to 0, triggered is reset to value of 0

    else if (triggered) begin
       if (set_capture_done)
          triggered <= 1'b0;  //If set_capture_done is asserted, value stored in triggered is knocked down 
    end 

   else 
        triggered <= trigger_input; //Trigger gets value set using combinational logic 
  end

endmodule
