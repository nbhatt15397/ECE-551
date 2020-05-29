module AFE_1CH (clk400MHz, CH_H, CH_L);

	input clk400MHz; //400Mhz input clk signal
	output CH_L, CH_H;	
	logic [7:0] CHmemory [8191:0]; //Created an array of 8192 x 8
	logic [7:0] sigval; //Output read from the memory unit
	logic [12:0] ptr;   //Pointer variable that acts like an "addr" of the memory

	//Defining values of VIL and VIH to compare our signal low and high values against
	localparam VIL = 8'h55; 
	localparam VIH = 8'hAA;

	//Reads contents of CHmem.txt into the memory
	initial $readmemh("CHmem.txt", CHmemory); 

	//Since we are not synthesizing this module, it is okay to initialise ptr to 0
	initial ptr = 12'h000;

	//Counter used to count up the 400Mhz clock signal to read from memory
	always @(posedge clk400MHz) 
    	ptr <= ptr + 1;

    //Reading from CHmemory and storing the output value in sigval variable
	always @(posedge clk400MHz) 
		sigval <= CHmemory[ptr]; 

	//Analog comparatorrs that are generating the CHANNEL Low and High values for a single channel
	assign CH_L = (sigval > VIL) ? 1'b1 : 1'b0; 
    assign CH_H = (sigval > VIH) ? 1'b1 : 1'b0; 

endmodule