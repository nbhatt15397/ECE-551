module chnnl_trig(clk,armed,CH_Hff5,CH_Lff5,CH_TrigCfg,CH_Trig);

  input clk;				// system clock
  input armed;				// Trigger armed signal
  input CH_Hff5;			// CHx high flopped version 5
  input CH_Lff5;			// CHx low flopped version 5
  input [4:0] CH_TrigCfg;	// Channel trigger configuration from cmd_reg
  output CH_Trig;			// trigger event exists for channel
  
  reg pos_trig1,pos_trig2;	// used for positive edge trigger detection
  reg neg_trig1,neg_trig2;	// used for negative edge trigger detection
  reg lvlH,lvlL;			// used for level triggering
  
  wire pos_trig, neg_trig;
  wire lvlH_trig, lvlL_trig;
  
  always_ff @(posedge CH_Hff5, negedge armed)
    if (!armed)
	  pos_trig1 <= 1'b0;
	else
	  pos_trig1 <= 1'b1;
	  
  always_ff @(negedge CH_Lff5, negedge armed)
    if (!armed)
	  neg_trig1 <= 1'b0;
	else
	  neg_trig1 <= 1'b1;
	  
  always_ff @(posedge clk)
    begin
	  pos_trig2 <= pos_trig1;
	  neg_trig2 <= neg_trig1;
	end

  assign pos_trig = pos_trig2 & CH_TrigCfg[4];
  assign neg_trig = neg_trig2 & CH_TrigCfg[3];
  
  always_ff @(posedge clk)
    begin
      lvlH <= CH_Hff5;
	  lvlL <= CH_Lff5;
    end

  assign lvlH_trig = lvlH & CH_TrigCfg[2];
  assign lvlL_trig = ~lvlL & CH_TrigCfg[1];
	
  assign CH_Trig = pos_trig | neg_trig | lvlH_trig | lvlL_trig | CH_TrigCfg[0];

endmodule  
	  
  