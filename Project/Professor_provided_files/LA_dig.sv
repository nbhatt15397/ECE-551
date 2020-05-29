module LA_dig(clk400MHz,RST_n,locked,VIH_PWM,VIL_PWM,CH1L,CH1H,CH2L,CH2H,CH3L,CH3H,
              CH4L,CH4H,CH5L,CH5H,RX,TX);
	
  parameter ENTRIES = 384,	// defaults to 384 for simulation, use 12288 for DE-0 and 384 for sim
            LOG2 = 9;		// Log base 2 of number of entries, use 14 for DE-0 and 9 for sim
			
  input clk400MHz;		// 400MHz clock generated from 50MHz by 8xPLL
  input RST_n;			// reset from push button (not synched to clk)
  input locked;			// informs digital core that PLL is locked
  input CH1L,CH1H;		// channel1 inputs from comparators
  input CH2L,CH2H;		// channel2 inputs from comparators
  input CH3L,CH3H;		// channel3 inputs from comparators
  input CH4L,CH4H;		// channel4 inputs from comparators
  input CH5L,CH5H;		// channel5 inputs from comparators
  input RX;				// UART data in (command to core)

  output VIH_PWM,VIL_PWM;	// PWM outputs that set VIH & VIL levels
  output TX;				// UART data out (response from core)

  ////////////////////////////////////////////////
  // Declare internal connections as type wire //
  //////////////////////////////////////////////
  wire [7:0] VIL,VIH;	// from digital core to dual PWM
  wire [15:0] cmd;		// command from host to LA_dig
  wire cmd_rdy,clr_cmd_rdy;
  wire [7:0] resp;		// response to host from LA_dig
  wire send_resp,resp_sent;
  wire rst_n;			// reset synchronized
  wire [3:0] decimator;	// only capture every 2^decimator samples
  wire smpl_clk;		// goes to channel sample blocks.
  wire wrt_smpl;		// synchronized with when writes of sample could occur
  ///// RAMqueue interface is next //////
  wire clk,we;
  wire [LOG2-1:0] waddr,raddr;
  wire [7:0] wdataCH1,wdataCH2,wdataCH3,wdataCH4,wdataCH5;
  wire [7:0] rdataCH1,rdataCH2,rdataCH3,rdataCH4,rdataCH5;
  
  ////////////////////////////////////////
  // Instantiate the clock/reset block //
  //////////////////////////////////////
  clk_rst_smpl iCLKRST(.clk400MHz(clk400MHz),.RST_n(RST_n),.locked(locked),
                  .decimator(decimator),.clk(clk),.smpl_clk(smpl_clk),
				  .rst_n(rst_n),.wrt_smpl(wrt_smpl));
				  
  ////////////////////////////////////////////////
  // Instantiate Dual PWM that forms VIH & VIL //
  //////////////////////////////////////////////
  dual_PWM iPWM(.clk(clk), .rst_n(rst_n), .VIH(VIH), .VIL(VIL),
                .VIH_PWM(VIH_PWM), .VIL_PWM(VIL_PWM));
				
  ////////////////////////////////////////////////////////////
  // Instantiate UART_comm that handles host communication //
  //////////////////////////////////////////////////////////
  UART_wrapper iCOMM(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .resp(resp),
                  .send_resp(send_resp), .resp_sent(resp_sent),
			      .cmd_rdy(cmd_rdy), .cmd(cmd), .clr_cmd_rdy(clr_cmd_rdy));
			

  ///////////////////////////////////////////////////////
  // Instantiate the RAM queues that hold the samples //
  /////////////////////////////////////////////////////
  RAMqueue #(ENTRIES,LOG2) iRAMCH1(.clk(clk),.we(we),.waddr(waddr),
            .raddr(raddr),.wdata(wdataCH1),.rdata(rdataCH1));			
  RAMqueue #(ENTRIES,LOG2) iRAMCH2(.clk(clk),.we(we),.waddr(waddr),
            .raddr(raddr),.wdata(wdataCH2),.rdata(rdataCH2));
  RAMqueue #(ENTRIES,LOG2) iRAMCH3(.clk(clk),.we(we),.waddr(waddr),
            .raddr(raddr),.wdata(wdataCH3),.rdata(rdataCH3));
  RAMqueue #(ENTRIES,LOG2) iRAMCH4(.clk(clk),.we(we),.waddr(waddr),
            .raddr(raddr),.wdata(wdataCH4),.rdata(rdataCH4));
  RAMqueue #(ENTRIES,LOG2) iRAMCH5(.clk(clk),.we(we),.waddr(waddr),
            .raddr(raddr),.wdata(wdataCH5),.rdata(rdataCH5));
		
  ///////////////////////////////
  // Instantiate digital core //
  /////////////////////////////
  dig_core #(ENTRIES,LOG2) iDIG(.clk(clk), .rst_n(rst_n), .smpl_clk(smpl_clk),
           .wrt_smpl(wrt_smpl), .decimator(decimator), .VIH(VIH), .VIL(VIL),
		   .CH1L(CH1L), .CH1H(CH1H), .CH2L(CH2L), .CH2H(CH2H), .CH3L(CH3L), 
		   .CH3H(CH3H), .CH4L(CH4L), .CH4H(CH4H), .CH5L(CH5L), .CH5H(CH5H),
		   .cmd(cmd),.cmd_rdy(cmd_rdy), .clr_cmd_rdy(clr_cmd_rdy), .resp(resp),
		   .send_resp(send_resp), .resp_sent(resp_sent),
		   .we(we), .waddr(waddr), .raddr(raddr), .wdataCH1(wdataCH1),
		   .wdataCH2(wdataCH2), .wdataCH3(wdataCH3), .wdataCH4(wdataCH4),
		   .wdataCH5(wdataCH5), .rdataCH1(rdataCH1), .rdataCH2(rdataCH2), 
		   .rdataCH3(rdataCH3), .rdataCH4(rdataCH4), .rdataCH5(rdataCH5));

endmodule