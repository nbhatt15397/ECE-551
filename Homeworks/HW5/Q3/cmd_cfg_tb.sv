module cmd_cfg_tb();

  localparam ENTRIES = 384;
  localparam LOG2 = 9;
  
  reg clk,rst_n;
  reg [LOG2-1:0] waddr;		// write address to RAMqueues
  reg [7:0] wdata1;			// data to write to RAMqueues
  reg we;					// WE strobe to RAMqueues
  reg [15:0] host_cmd;		// command host software is sending to cmd_cfg
  reg send_cmd;				// strobe this high for 1 clock to send host_cmd
  reg set_capture_done;		// when asserted should set bit 5 of trigCfg register
  reg clr_resp_rdy;
  
  wire RX_TX,TX_RX;			// UART_wrapper to CommMstr connections
  wire [7:0] resp;			// 8-bit data to send as response: cmd_cfg -> UART_wrapper
  wire [7:0] resp_rcvd;		// 8-bit response received by CommMstr
  wire send_resp,resp_sent;
  wire [15:0] cmd;			// command received from CommMstr
  wire cmd_rdy,clr_cmd_rdy;
  wire [LOG2-1:0] raddr;	// read address to RAMqueues
  wire [LOG2-1:0] trig_pos;
  wire [7:0] rdataCH1,rdataCH2;
  wire [7:0] rdataCH3,rdataCH4;
  wire [7:0] rdataCH5;
  ////// register outputs follow //////
  wire [3:0] decimator;
  wire [7:0] maskL,maskH;
  wire [7:0] matchL,matchH;
  wire [7:0] baud_cntL,baud_cntH;
  wire [5:0] TrigCfg;
  wire [4:0] CH1TrigCfg,CH2TrigCfg;
  wire [4:0] CH3TrigCfg,CH4TrigCfg,CH5TrigCfg;
  wire [7:0] VIL,VIH;
  
  ///////////////////////////
  // Define command bytes //
  /////////////////////////
  localparam DUMP_CH1  = 8'h81;		// Dump channel 1
  localparam DUMP_CH2  = 8'h82;		// Dump channel 2
  localparam DUMP_CH3  = 8'h83;		// Dump channel 3
  localparam DUMP_CH4  = 8'h84;		// Dump channel 4
  localparam DUMP_CH5  = 8'h85;		// Dump channel 5
  localparam TRIG_CFG_RD = 8'h00;		// Used to read TRIG_CFG register
  localparam WRT_DEC     = 8'h46;		// Write to decimator register
  localparam WRT_VIH_PWM = 8'h47;		// Set VIH trigger level [255:0] are valid values
  localparam WRT_VIL_PWM = 8'h48;		// Set VIL trigger level [255:0] are valid values
  localparam WRT_CH1_TRG = 8'h41;		// Write to CH1 trigger config register 
  localparam WRT_CH2_TRG = 8'h42;		// Write to CH2 trigger config register
  localparam WRT_CH3_TRG = 8'h43;		// Write to CH3 trigger config register
  localparam WRT_CH4_TRG = 8'h44;		// Write to CH4 trigger config register
  localparam WRT_CH5_TRG = 8'h45;		// Write to CH5 trigger config register
  localparam WRT_TRG_CFG = 8'h40;		// Write to TrigCfg register
  localparam WRT_TRGPOSH = 8'h4F;		// Write to trig_posH register
  localparam WRT_TRGPOSL = 8'h50;		// Write to trig_posL register
  localparam WRT_MATCHH  = 8'h49;		// Write to matchH register
  localparam WRT_MATCHL  = 8'h4A;		// Write to matchL register
  localparam WRT_MASKH   = 8'h4B;		// Write to maskH register
  localparam WRT_MASKL   = 8'h4C;		// Write to maskL register
  localparam WRT_BAUDH   = 8'h4D;		// Write to baudD register
  localparam WRT_BAUDL   = 8'h4E;		// Write to baudL register
  //// define responses /////
  localparam POS_ACK = 8'hA5;
  localparam NEG_ACK = 8'hEE;
  
  localparam READ_baudcntL =  8'b00001110;
  localparam dump_CH1 = 8'b10000001;
  //////////////////////
  // Instantiate DUT //
  ////////////////////
  cmd_cfg #(ENTRIES,LOG2) iCMD(.clk(clk),.rst_n(rst_n),.resp(resp),.send_resp(send_resp),
          .resp_sent(resp_sent),.cmd(cmd),.cmd_rdy(cmd_rdy),.clr_cmd_rdy(clr_cmd_rdy),
		  .set_capture_done(set_capture_done),.raddr(raddr),.waddr(waddr),
		  .trig_pos(trig_pos),.rdataCH1(rdataCH1),.rdataCH2(rdataCH2),.rdataCH3(rdataCH3),
		  .rdataCH4(rdataCH4),.rdataCH5(rdataCH5),.decimator(decimator),.maskL(maskL),
		  .maskH(maskH),.matchL(matchL),.matchH(matchH),.baud_cntL(baud_cntL),
		  .baud_cntH(baud_cntH),.TrigCfg(TrigCfg),.CH1TrigCfg(CH1TrigCfg),
		  .CH2TrigCfg(CH2TrigCfg),.CH3TrigCfg(CH3TrigCfg),.CH4TrigCfg(CH4TrigCfg),
	      .CH5TrigCfg(CH5TrigCfg),.VIH(VIH),.VIL(VIL));
		  
  ////////////////////////////////////////////////////////////
  // Instantiate UART_comm that handles host communication //
  //////////////////////////////////////////////////////////
  UART_wrapper iCOMM(.clk(clk), .rst_n(rst_n), .RX(TX_RX), .TX(RX_TX), .resp(resp),
                  .send_resp(send_resp), .resp_sent(resp_sent),
			      .cmd_rdy(cmd_rdy), .cmd(cmd), .clr_cmd_rdy(clr_cmd_rdy));
				  
  //// Instantiate Master UART (mimics host commands) //////
  CommMstr iMSTR(.clk(clk), .rst_n(rst_n), .RX(RX_TX), .TX(TX_RX),
                     .cmd(host_cmd), .send_cmd(send_cmd),
					 .cmd_sent(cmd_sent), .resp_rdy(resp_rdy),
					 .resp(resp_rcvd), .clr_resp_rdy(clr_resp_rdy));	

  ///////////////////////////////////////////////////////
  // Instantiate the RAM queues that hold the samples //
  /////////////////////////////////////////////////////
  RAMqueue #(ENTRIES,LOG2) iRAMCH1(.clk(clk),.we(we),.waddr(waddr),
            .raddr(raddr),.wdata(wdata1),.rdata(rdataCH1));
  /// you can instantiate all 5 if you like...just one done for you ///
  integer i;

/////////////////////////////////////
	
  //Task that writes and populated RAM queue
  task fill_RAM;
  	  @(negedge clk);
	  we = 1;
	  @(negedge clk);
  	   for(i=0; i<384; i++) begin
  		   fork
      	    begin: TIMEOUT5;
	   	    repeat(2000) @(negedge clk);
			$display("ERR: timed out waiting for response from DUT");
			$stop();
		    end

	        begin
	         @(posedge resp_rdy);
		    disable TIMEOUT5;
	        end

           join
            waddr = 0;
            wdata1 = i ;
	        iRAMCH1.mem[i] = wdata1;	
         		$display("writing data into ram CH1") ;
         		$stop();
	$display("GOOD: Dump write done");
   end//for
  endtask

   //Task that reads the dumped values and checks them from the RAMqueue
  task check_dump;
    @(negedge clk);
	send_cmd = 1;		
	@(negedge clk);
	send_cmd = 0;
   for(i=0;i<384;i++) begin
   	  fork
        begin: TIMEOUT6;
	    repeat(2000) @(negedge clk);
		$display("ERR: timed out waiting for response from DUT");
		$stop();
	     end

	    begin
	    @(posedge resp_rdy);
		disable TIMEOUT6;
	    end

        join
      	clr_resp_rdy = 1;
	  	@(negedge clk);
	  	clr_resp_rdy = 0;
         	if (resp_rcvd == iRAMCH1.mem[i])  begin
         		$display("Correct data received through ram dump_CH1") ;
         		$stop();
         	end
	$display("GOOD: Dump read case passed");
   end //for
endtask


  initial begin
    //// default all stimulus ////
    clk = 0;
	rst_n = 0;				// assert reset
	waddr = 0;
	wdata1 = 8'h00;
	we = 0;
	host_cmd = {WRT_TRG_CFG,8'h13};	// write to TrigCfg running with prot trig disabled
	send_cmd = 0;
	set_capture_done = 0;
	clr_resp_rdy = 0;
	
	/// wait 1.5 clocks with reset asserted ///
	@(posedge clk);
	@(negedge clk);
	rst_n = 1;						// deassert reset
	
	///////////////////////////////////////
	// case 1: writing TrigCfg register //
	/////////////////////////////////////
	@(negedge clk);
	send_cmd = 1;					// send first cmd
	@(negedge clk);
	send_cmd = 0;
	fork
	  begin: TIMEOUT1;
	    repeat(2000) @(negedge clk);
		$display("ERR: timed out waiting for response from DUT");
		$stop();
	  end
	  begin
	    @(posedge resp_rdy);
		disable TIMEOUT1;
	  end
	join
	clr_resp_rdy = 1;
	@(negedge clk);
	clr_resp_rdy = 0;
	if (resp_rcvd!=POS_ACK) begin
	  $display("ERR: expecting POS_ACK on write to TrigCfg");
	  $stop();
	end
	$display("GOOD: case1 passed");
	
	//////////////////////////////////////////////////////////////////////////
	// case 2: setting set_capture_done high to see if TrigCfg[5] gets set //
	////////////////////////////////////////////////////////////////////////
	set_capture_done = 1;
	@(negedge clk)
	set_capture_done = 0;
	host_cmd = {TRIG_CFG_RD,8'hxx};	// write to TrigCfg running with prot trig disabled	
	@(negedge clk);
	send_cmd = 1;					// send first cmd
	@(negedge clk);
	send_cmd = 0;
	fork
	  begin: TIMEOUT2;
	    repeat(2000) @(negedge clk);
		$display("ERR: timed out waiting for response from DUT");
		$stop();
	  end
	  begin
	    @(posedge resp_rdy);
		disable TIMEOUT2;
	  end
	join
	clr_resp_rdy = 1;
	@(negedge clk);
	clr_resp_rdy = 0;
	if (resp_rcvd!=8'h33) begin
	  $display("ERR: expecting 0x33 for read of TrigCfg");
	  $stop();
	end
	$display("GOOD: case2 passed");
	
    //....Now you fill in more test cases....
    ///////////////////////////////////////
	// case 3: writing baud_cntL register //
	/////////////////////////////////////
	host_cmd = {WRT_BAUDL, 8'h10};	// write to baud_cntL 
	@(negedge clk);
	send_cmd = 1;					
	@(negedge clk);
	send_cmd = 0;
	fork
	  begin: TIMEOUT3;
	    repeat(2000) @(negedge clk);
		$display("ERR: timed out waiting for response from DUT");
		$stop();
	  end
	  begin
	    @(posedge resp_rdy);
		disable TIMEOUT3;
	  end
	join
	clr_resp_rdy = 1;
	@(negedge clk);
	clr_resp_rdy = 0;
	if (resp_rcvd!=POS_ACK) begin
	  $display("ERR: expecting POS_ACK on write to baud_cntL");
	  $stop();
	end
	$display("GOOD: case3 passed");

	//////////////////////////////////////////////////////////////////////////
	// case 4: Reading data stored in baud_cntL register                   //
	////////////////////////////////////////////////////////////////////////
	
	host_cmd = {READ_baudcntL,8'hxx};	// cmd to read from reg baudcnt_L	
	@(negedge clk);
	send_cmd = 1;					// send first cmd
	@(negedge clk);
	send_cmd = 0;
	fork
	  begin: TIMEOUT4;
	    repeat(2000) @(negedge clk);
		$display("ERR: timed out waiting for response from DUT");
		$stop();
	  end
	  begin
	    @(posedge resp_rdy);
		disable TIMEOUT4;
	  end
	join
	clr_resp_rdy = 1;
	@(negedge clk);
	clr_resp_rdy = 0;
	if (resp_rcvd!=8'h10) begin
	  $display("ERR: expecting 0x10 for read of baudcnt_L");
	  $stop();
	end

	////////////////////////////////////////////////////////////////////////////////////
	// case 5&6: First populate RAMqueue and then check for Channel dump of CHANNEL1///
	//////////////////////////////////////////////////////////////////////////////////

	host_cmd = {dump_CH1,8'hxx};	// cmd to read from reg baudcnt_L	
	@(negedge clk);
	task fill_RAM;
	@(negedge clk);
	task check_dump;

	$display("Yahoo! Test passed");
	$stop();

end//initial
  
  always
    #5 clk = ~clk;
  
endmodule