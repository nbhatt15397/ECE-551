module dig_core(clk,rst_n,smpl_clk,wrt_smpl, decimator, VIH, VIL, CH1L, CH1H,
				CH2L, CH2H, CH3L, CH3H, CH4L, CH4H, CH5L, CH5H, cmd, cmd_rdy,
                clr_cmd_rdy, resp, send_resp, resp_sent, we, waddr,
				raddr, wdataCH1, wdataCH2, wdataCH3, wdataCH4, wdataCH5, rdataCH1,
                rdataCH2, rdataCH3, rdataCH4, rdataCH5);
				
  parameter ENTRIES = 384,	// defaults to 384 for simulation, use 12288 for DE-0
            LOG2 = 9;		// Log base 2 of number of entries
			
  input clk,rst_n;			// 100MHz clock and active low asynch reset
  input wrt_smpl;			// indicates when timing is right to write a smpl
  input smpl_clk;			// goes to channel sample logic (decimated 400MHz clock)
  input CH1L,CH1H;			// signals from CH1 comparators
  input CH2L,CH2H;			// signals from CH2 comparators
  input CH3L,CH3H;			// signals from CH3 comparators
  input CH4L,CH4H;			// signals from CH4 comparators
  input CH5L,CH5H;			// signals from CH5 comparators
  input [15:0] cmd;			// command from host
  input cmd_rdy;			// indicates command from host is ready
  input resp_sent;			// indicates response has been sent to host
  input [7:0] rdataCH1;		// sample read from CH1 RAM
  input [7:0] rdataCH2;		// sample read from CH2 RAM
  input [7:0] rdataCH3;		// sample read from CH3 RAM
  input [7:0] rdataCH4;		// sample read from CH4 RAM
  input [7:0] rdataCH5;		// sample read from CH5 RAM  
  
  output [7:0] VIH,VIL;		// sets PWM level for VIH and VIL thresholds
  output clr_cmd_rdy;		// asserted to knock down cmd_rdy after command interpretted
  output [7:0] resp;		// response to host
  output send_resp;			// asserted to initiate transmission of response to host
  output we;				// write enable to all channel RAMS
  output [LOG2-1:0] waddr;	// write address to all RAMs
  output [LOG2-1:0] raddr;	// read address to all RAMs
  output [3:0] decimator;	// only every 2^decimator samples is taken
  output [7:0] wdataCH1;	// sample to write to CH1 RAM
  output [7:0] wdataCH2;	// sample to write to CH2 RAM
  output [7:0] wdataCH3;	// sample to write to CH3 RAM
  output [7:0] wdataCH4;	// sample to write to CH4 RAM
  output [7:0] wdataCH5;	// sample to write to CH5 RAM

  //////////////////////////////////////////
  // delcare any needed internal signals //
  ////////////////////////////////////////
  wire CH1Hff5,CH1Lff5,CH2Hff5,CH2Lff5,CH3Hff5;
  wire CH3Lff5,CH4Hff5,CH4Lff5,CH5Hff5,CH5Lff5;
  wire [4:0] CH1TrigCfg,CH2TrigCfg,CH3TrigCfg,CH4TrigCfg,CH5TrigCfg;
  wire [5:0] TrigCfg;
  wire CH1Trig,CH2Trig,CH3Trig,CH4Trig,CH5Trig;
  wire [7:0] maskL,maskH;
  wire [7:0] matchL,matchH;
  wire [7:0] baud_cntL,baud_cntH;
  wire armed,set_capture_done;
  wire [LOG2-1:0] trig_pos;
  wire triggered;
  
  ///////////////////////////////////////////////////
  // Instantiate 5 copies of channel sample logic //
  /////////////////////////////////////////////////
  channel_sample iCH1smpl(.smpl_clk(smpl_clk),.clk(clk),.CH_H(CH1H),.CH_L(CH1L),
                      .CH_Hff5(CH1Hff5),.CH_Lff5(CH1Lff5),.smpl(wdataCH1));
  channel_sample iCH2smpl(.smpl_clk(smpl_clk),.clk(clk),.CH_H(CH2H),.CH_L(CH2L),
                      .CH_Hff5(CH2Hff5),.CH_Lff5(CH2Lff5),.smpl(wdataCH2));
  channel_sample iCH3smpl(.smpl_clk(smpl_clk),.clk(clk),.CH_H(CH3H),.CH_L(CH3L),
                      .CH_Hff5(CH3Hff5),.CH_Lff5(CH3Lff5),.smpl(wdataCH3));
  channel_sample iCH4smpl(.smpl_clk(smpl_clk),.clk(clk),.CH_H(CH4H),.CH_L(CH4L),
                      .CH_Hff5(CH4Hff5),.CH_Lff5(CH4Lff5),.smpl(wdataCH4));
  channel_sample iCH5smpl(.smpl_clk(smpl_clk),.clk(clk),.CH_H(CH5H),.CH_L(CH5L),
                      .CH_Hff5(CH5Hff5),.CH_Lff5(CH5Lff5),.smpl(wdataCH5));					  

  ////////////////////////////////
  // Instantiate trigger logic //
  //////////////////////////////
  trigger iTRG(.clk(clk),.rst_n(rst_n),.CH1TrigCfg(CH1TrigCfg),.CH2TrigCfg(CH2TrigCfg),
               .CH3TrigCfg(CH3TrigCfg),.CH4TrigCfg(CH4TrigCfg),.CH5TrigCfg(CH5TrigCfg),
               .TrigCfg(TrigCfg[3:0]),.CH1L(CH1L),.CH2L(CH2L),.CH3L(CH3L),.CH1Lff5(CH1Lff5),
			   .CH1Hff5(CH1Hff5),.CH2Lff5(CH2Lff5),.CH2Hff5(CH2Hff5),.CH3Lff5(CH3Lff5),
			   .CH3Hff5(CH3Hff5),.CH4Lff5(CH4Lff5),.CH4Hff5(CH4Hff5),.CH5Lff5(CH5Lff5),
			   .CH5Hff5(CH5Hff5),.armed(armed),.maskL(maskL),.maskH(maskH),
			   .matchL(matchL),.matchH(matchH),.baud_cntH(baud_cntH),.baud_cntL(baud_cntL),
			   .set_capture_done(set_capture_done),.triggered(triggered));
	
  /////////////////////////////////////
  // Instantiate capture control SM //
  ///////////////////////////////////  
  capture #(ENTRIES,LOG2) iCAP_SM(.clk(clk),.rst_n(rst_n),.wrt_smpl(wrt_smpl),
          .run(TrigCfg[4]),.capture_done(TrigCfg[5]),.triggered(triggered),
		  .trig_pos(trig_pos),.we(we),.waddr(waddr),.set_capture_done(set_capture_done),
		  .armed(armed));
		  
  ////////////////////////////////////
  // Instantiate command config SM //
  ////////////////////////////////// 		   
  cmd_cfg #(ENTRIES,LOG2) iCMD(.clk(clk),.rst_n(rst_n),.resp(resp),.send_resp(send_resp),
          .resp_sent(resp_sent),.cmd(cmd),.cmd_rdy(cmd_rdy),.clr_cmd_rdy(clr_cmd_rdy),
		  .set_capture_done(set_capture_done),.raddr(raddr),.rdataCH1(rdataCH1),
		  .rdataCH2(rdataCH2),.rdataCH3(rdataCH3),.rdataCH4(rdataCH4),.rdataCH5(rdataCH5),
		  .waddr(waddr),.trig_pos(trig_pos),.decimator(decimator),.maskL(maskL),
		  .maskH(maskH),.matchL(matchL),.matchH(matchH),.baud_cntL(baud_cntL),
		  .baud_cntH(baud_cntH),.TrigCfg(TrigCfg),.CH1TrigCfg(CH1TrigCfg),
		  .CH2TrigCfg(CH2TrigCfg),.CH3TrigCfg(CH3TrigCfg),.CH4TrigCfg(CH4TrigCfg),
	      .CH5TrigCfg(CH5TrigCfg),.VIH(VIH),.VIL(VIL));
			   
endmodule  