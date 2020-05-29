module channel_sample (smpl_clk, CH_L, CH_H, clk, smpl, CH_Lff5, CH_Hff5);
	input smpl_clk;    //Incoming clock signal
	input CH_L, CH_H;  //Input to be doible flopped for metastability
	input clk;		  //Inout clk signal
	output reg [7:0] smpl; //8 bit reg that stores the 8 bits of data samples
	output logic CH_Lff5, CH_Hff5; 
	reg ff1xL, ff1xH, ff2xL, ff2xH, ff3xL, ff3xH, ff4xL, ff4xH, ff5xL, ff5xH;

	assign CH_Lff5 = ff5xL ;
	assign CH_Hff5 = ff5xH ;

	//Generating 5 flops to flop channel values for metastability first and then to propagate the 8 bits for the smpl  
	always_ff @ (negedge smpl_clk) begin

			 ff1xL <= CH_L;
			 ff1xH <= CH_H;

			 ff2xL <= ff1xL;
			 ff2xH <= ff1xH;

			 ff3xL <= ff2xL;      
			 ff3xH <= ff2xH;

			 ff4xL <= ff3xL;
			 ff4xH <= ff3xH;
			 
			 ff5xL <= ff4xL;
			 ff5xH <= ff4xH;
	end

	//Concatenating specific flop outputs to generate the 8 bit sample value
	always_ff @(posedge clk) begin
				smpl <= {ff2xH, ff2xL, ff3xH, ff3xL, ff4xH, ff4xL, ff5xH, ff5xL} ;
	end

endmodule