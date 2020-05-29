module AFE(smpl_clk,VIH_PWM,VIL_PWM,CH1L,CH1H,CH2L,CH2H,CH3L,CH3H,
           CH4L,CH4H,CH5L,CH5H);
		   
  input smpl_clk;			// new sample presented every clock
  input VIH_PWM, VIL_PWM;	// PWM inputs that specify thresholds.
							// thresholds assumed at 0.33 and 0.66 till first PWM period completes
  output CH1L,CH1H;			// Logic low and logic high outputs for CH1
  output CH2L,CH2H;			// Logic low and logic high outputs for CH2
  output CH3L,CH3H;			// Logic low and logic high outputs for CH3
  output CH4L,CH4H;			// Logic low and logic high outputs for CH4
  output CH5L,CH5H;			// Logic low and logic high outputs for CH5
  
  reg [7:0] CH1mem[8191:0];		// 2^13 entries of 8-bits analog for CH1
  reg [7:0] CH2mem[8191:0];		// 2^13 entries of 8-bits analog for CH2
  reg [7:0] CH3mem[8191:0];		// 2^13 entries of 8-bits analog for CH3
  reg [7:0] CH4mem[8191:0];		// 2^13 entries of 8-bits analog for CH4 
  reg [7:0] CH5mem[8191:0];		// 2^13 entries of 8-bits analog for CH5

  reg [12:0] ptr;					// pointer into CHXmem used for comparison
  reg [7:0] VIL,VIH;				// VIL & VIH as 8-bit quantities, start at .33 and .66
  reg en_VIL_PWM,en_VIH_PWM;
  reg [9:0] VIL_cntr,VIH_cntr;		// counters for capturing duty cycle of PWM signals. 

  wire [7:0] CH1val,CH2val,CH3val,CH4val,CH5val;	// analog 8-bit values (for plotting)  
  
  initial begin
    ptr = 13'h0000;
	$readmemh("CH1mem.txt",CH1mem);
	$readmemh("CH2mem.txt",CH2mem);
	$readmemh("CH3mem.txt",CH3mem);
	$readmemh("CH4mem.txt",CH4mem);
	$readmemh("CH5mem.txt",CH5mem);
	VIL = 8'h55;	// starts at 0.33 then modified according to duty of VIL_PWM
	VIH = 8'hAA;	// starts at 0.66 then modified according to duty of VIH_PWM
	en_VIL_PWM = 0;
	en_VIH_PWM = 0;
  end
  
  always @(posedge smpl_clk)
    ptr <= ptr + 1;
	
  always @(posedge VIL_PWM)		// don't start monitoring VIL_PWM till positive edge occurs
    begin
      en_VIL_PWM <= 1;
	  VIL_cntr <= 0;			// zero the counter on pos edge and capture on neg edge
	end
	
  always @(posedge VIH_PWM)		// don't start monitoring VIL_PWM till positive edge occurs
    begin
      en_VIH_PWM <= 1;
	  VIH_cntr <= 0;			// zero the counter on pos edge and capture on neg edge
	end

  always @(posedge smpl_clk)
    if ((en_VIL_PWM) && (VIL_PWM))	// if monitoring VIL_PWM and it is high then
	  VIL_cntr <= VIL_cntr + 1;		// increment the VIL_cntr
	  
  always @(posedge smpl_clk)
    if ((en_VIH_PWM) && (VIH_PWM))	// if monitoring VIH_PWM and it is high then
	  VIH_cntr <= VIH_cntr + 1;	  	// increment the VIH_cntr
	
  always @(negedge VIL_PWM)		// on negative edge we capture new VIL value
    if (en_VIL_PWM)
	  VIL <= VIL_cntr[9:2];
	  
  always @(negedge VIH_PWM)		// on negative edge we capture new VIH value
    if (en_VIH_PWM)
	  VIH <= VIH_cntr[9:2];

  /////////////////////////////////////////////////////////////
  // Now model comparator function for the various channels //
  ///////////////////////////////////////////////////////////
  assign CH1val = CH1mem[ptr];		// gives you something to plot in waveforms
  assign CH1L = (CH1val<VIL) ? 1'b0 : 1'b1;
  assign CH1H = (CH1val>VIH) ? 1'b1 : 1'b0; 

  assign CH2val = CH2mem[ptr];		// gives you something to plot in waveforms
  assign CH2L = (CH2val<VIL) ? 1'b0 : 1'b1;
  assign CH2H = (CH2val>VIH) ? 1'b1 : 1'b0; 
 
  assign CH3val = CH3mem[ptr];		// gives you something to plot in waveforms
  assign CH3L = (CH3val<VIL) ? 1'b0 : 1'b1;
  assign CH3H = (CH3val>VIH) ? 1'b1 : 1'b0; 

  assign CH4val = CH4mem[ptr];		// gives you something to plot in waveforms
  assign CH4L = (CH4val<VIL) ? 1'b0 : 1'b1;
  assign CH4H = (CH4val>VIH) ? 1'b1 : 1'b0; 

  assign CH5val = CH5mem[ptr];		// gives you something to plot in waveforms
  assign CH5L = (CH5val<VIL) ? 1'b0 : 1'b1;
  assign CH5H = (CH5val>VIH) ? 1'b1 : 1'b0; 

endmodule  
	
  
	