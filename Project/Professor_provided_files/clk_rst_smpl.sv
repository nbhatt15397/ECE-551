module clk_rst_smpl(clk400MHz,RST_n,locked,decimator,clk,smpl_clk,rst_n,wrt_smpl);

input clk400MHz;		// 400MHz clock from PLL
input RST_n;			// non synched reset from push button
input locked;			// Indicates the PLL is locked
input [3:0] decimator;	// determines how many sample we keep 1 of every 2^decimator
output clk;				// 100MHz system clock
output logic smpl_clk;	// decimated sample clock (use negative edge!)
output reg rst_n;		// synched on deassert to negedge of clock
output reg wrt_smpl;	// asserted when timing is correct for sample to be written to RAM

reg q1;
reg cnt_full;			// needed for a knock down on wrt_smpl if high for more than 1 clock.
reg [1:0] clk_cnt;
reg locked_ff1,locked_ff2;		// locked is asynch and should be double flopped
reg [9:0] decimator_cnt;
reg [1:0] smpl_cnt;
reg synch_smpl_cnt;
reg locked_synched;		// version of locked synched to main system clock
reg smpl_clk_div;

reg smpl_clk_mux;

////////////////////////////////////////////////////
// double flop locked for meta-stability reasons //
//////////////////////////////////////////////////
always_ff @(posedge clk400MHz, negedge RST_n)
  if (!RST_n) begin
    locked_ff1 <= 1'b0;
	locked_ff2 <= 1'b0;
  end else begin
    locked_ff1 <= locked;
	locked_ff2 <= locked_ff1;
  end
  
///////////////////////////////////////////////
// Next infer the counter that divides      //
// 400MHz clk to produce 100MHz system clk //
////////////////////////////////////////////
always_ff @(posedge clk400MHz)
  if (!locked_ff2)				// clock stays 0 till PLL locked
    clk_cnt <= 2'b00;
  else
    clk_cnt <= clk_cnt + 1;
assign clk = clk_cnt[1];		// 100MHz system clock

/////////////////////////////////////////////////////
// Create version of locked synched to system clk //
///////////////////////////////////////////////////
always_ff @(negedge clk, negedge RST_n)
  if (!RST_n)
    locked_synched <= 1'b0;
  else 
    locked_synched <= locked_ff2;

////////////////////////////////////////////////
// rst_n is asserted asynch, but deasserted  //
// syncronized to negedge clock.  Two flops //
// are used for metastability purposes.    //
////////////////////////////////////////////
always_ff @(negedge clk, negedge RST_n)
  if (!RST_n)
    begin
	  q1    <= 1'b0;
	  rst_n <= 1'b0;
	end
  else if (locked_synched)
    begin
	  q1    <= 1;
	  rst_n <= q1;
	end
	
//////////////////////////////////////////////////
// Create smpl_clk which is 400MHz/2^decimator //
////////////////////////////////////////////////
always_ff @(negedge clk400MHz)
  if (!locked_synched)
    decimator_cnt <= 10'h000;
  else
    decimator_cnt <= decimator_cnt + 1;

always_comb
  case (decimator)
	4'h1 : smpl_clk_mux = decimator_cnt[0];	// 200MHz
	4'h2 : smpl_clk_mux = decimator_cnt[1];	// 100MHz
	4'h3 : smpl_clk_mux = decimator_cnt[2];	// 50MHz
	4'h4 : smpl_clk_mux = decimator_cnt[3];	// 25MHz
	4'h5 : smpl_clk_mux = decimator_cnt[4]; // 12.5MHz
	4'h6 : smpl_clk_mux = decimator_cnt[5]; // 6.25MHz
	4'h7 : smpl_clk_mux = decimator_cnt[6];	// 3.13MHz
	4'h8 : smpl_clk_mux = decimator_cnt[7]; // 1.56MHz
	4'h9 : smpl_clk_mux = decimator_cnt[8]; // 781kHz
	default : smpl_clk_mux = decimator_cnt[9];	// 391kHz
  endcase
  
always @(negedge clk400MHz)
  smpl_clk_div <= smpl_clk_mux;
 
assign smpl_clk = (|decimator) ? smpl_clk_div : clk400MHz; 
  

  /////////////////////////////////////////////////////
  // When this 2-bit sample counter is full we know //
  // we have 4 sample ready to be written to RAM.  //
  //////////////////////////////////////////////////
  always @(negedge smpl_clk, negedge locked_synched)
    if (!locked_synched)
	  smpl_cnt <= 2'b00;
	else if (&smpl_cnt)		// sync its reset to system clock
	  if (synch_smpl_cnt)
	    smpl_cnt <= 2'b00;
	  else
	    smpl_cnt <= smpl_cnt;
    else
	  smpl_cnt <= smpl_cnt + 1;

  always @(posedge clk, negedge rst_n)
    if (!rst_n)
	  synch_smpl_cnt <= 1'b0;
	else if (&smpl_cnt)
	  synch_smpl_cnt <= 1'b1;
	else
	  synch_smpl_cnt <= 1'b0;
	  
	
  always @(posedge clk, negedge rst_n)
    if (!rst_n) begin
	  wrt_smpl <= 1'b0;
	  cnt_full <= 1'b0;
	end else begin
	  ///////////////////////////////////////////////////
	  // This is a little complex, but in cases where //
	  // smpl_clk is slower than clk we only want    //
	  // wrt_smpl asserted for 1 clk cycle.         //
	  ///////////////////////////////////////////////
	  wrt_smpl <= &smpl_cnt & (~cnt_full | ~|decimator);
	  cnt_full <= &smpl_cnt;
	end
  
endmodule