//////////////////////////////////////////////////////////////////////
//// This file has all the tasks used in the LA_dig_tb testbench//////
//////////////////////////////////////////////////////////////////////
//localparam SET_TRG_CFG = 8'h40;		// Write to TrigCfg register
//localparam posAck = 8'ha5;
//localparam SET_CH1_TRG = 8'h41;		// Write to CH1 trigger config register


///////////////////////////////////////////////////////////////////////
////////////// TASK TO INIIALIZE THE LOGIC ANALYZER  //////////////////
///////////////////////////////////////////////////////////////////////
task initialization;
	begin
		  $display("Starting initializing");
		   send_cmd = 0;
   	    REF_CLK = 0;
        RST_n = 0;						// assert reset
        repeat (2) @(posedge REF_CLK);
        @(negedge REF_CLK);				// on negedge REF_CLK after a few REF clocks
        RST_n = 1;	        			// deasert reset on negedge
         @(negedge REF_CLK);
		  $display("Initialization done");
	end
endtask// initialize



/////////////////////////////////////////////////////////////////
////////////////////// TASK TO Send Command ////////////////////
///////////////////////////////////////////////////////////////
task SndCmd; 
	input  [15:0] cmd_to_send; 
    begin
    $display("Starting to send command: %h", cmd_to_send);
	   host_cmd = cmd_to_send;
	   @(negedge clk);
	   send_cmd = 1;
	   repeat (2) @(negedge clk);
	   send_cmd = 0;
	   repeat (2) @(negedge clk); // self added
	   $display("Command has been sent");
    end
endtask//SndCmd


/////////////////////////////////////////////////////////////////
///////////// TASK TO Check for a certain reponse //////////////
///////////////////////////////////////////////////////////////
task ChkResp;
  input [7:0] correct_response; 
  begin

    $display("Starting to check if correct response: %h was received", correct_response);
  fork
    begin: TIMEOUT4;
      repeat(2000) @(negedge clk);
    $display("ERR: timed out waiting for response");
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

  if (resp != correct_response) begin
    $display("ERR: expecting response: %h was not received", correct_response);
    $stop();
  end
    $display("GOOD: Correct response of %h was received", correct_response);
  end 
endtask//Check_response



////////////////////////////////////////////////////////////////////////////////////////////
///// TASK TO WRITE VALUE TO  CH1 trigger config reg and check if posach received /////////
//////////////////////////////////////////////////////////////////////////////////////////
task C1TrigCfg_write;

	  SndCmd({SET_CH1_TRG,8'h10}); 
    $display("Sending command to set CH1TRigCfg");
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);


    $display("Starting to check if posack received as response");
  fork
    begin: TIMEOUT1;
      repeat(2000) @(negedge clk);
    $display("ERR: timed out waiting for response");
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

  if (resp != posAck) begin
    $display("ERR: expecting POS_ACK on write to CH1TrigCfg");
    $stop();
  end
    $display("GOOD: Correct response of 8'hA5 was recieved when command to write x10 to CH1TrigCfg was sent");

endtask//C1TrigCfg_write



///////////////////////////////////////////////////////////////////////
////////////// TASK TO WRITE VALUE TO TrigCfg regsiter  ///////////////
///////////////////////////////////////////////////////////////////////
task TrigCfg_write;

  en_AFE = 1;
  SndCmd({SET_TRG_CFG,8'h13});
  $display("Sending command to set CH1TRigCfg");
	//////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    $display("Starting to check if posack received as response");

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
  if (resp != posAck) begin
    $display("ERR: expecting POS_ACK on write to TrigCfg");
    $stop;
  end
    $display("GOOD: Correct response of 8'hA5 was recieved when command to write x13 to TrigCfg was sent");
endtask //TrigCfg_write



/////////////////////////////////////////////////////////////
////// TASK TO CHECK IS CAPTURE_DONE BIT HAS BEEN SET///////
////////////////////////////////////////////////////////////
task poll_capturedone;
	capture_done_bit = 1'b0;			// capture_done not set yet
	loop_cnt = 0;
  	while (!capture_done_bit)
	  begin
	    repeat(400) @(posedge clk);		// delay a while between reads
	    loop_cnt = loop_cnt + 1;
	    if (loop_cnt>200) begin
	      $display("ERROR: capture done bit never set");
	      $stop();
	    end

        // read TRIG_CFG which has capture_done bit
        $display("Starting read of TRIG_CFG register to check if capture bit set");
        SndCmd({TRIG_CFG_RD,8'h00});

        //////////////////////////////////////
        // Now wait for command to be sent //
        ////////////////////////////////////
        @(posedge cmd_sent);
	    ////////////////////////////
	    // Now wait for response //
	    //////////////////////////
	    @(posedge resp_rdy)
	    if (resp&8'h20)				// is capture_done bits set?
	    capture_done_bit = 1'b1;
	    clr_resp_rdy = 1;
	    @(posedge clk);
	    clr_resp_rdy = 0;
	  end//while
	$display("INFO: capture_done bit is set");
endtask //check_capturedone	


/////////////////////////////////////////////////////////////
////////////// TASK TO CARRY OUT CHANNEL DUMPS /////////////
////////////////////////////////////////////////////////////
task channel_dump;

  input [7:0] dump_chnl;

  begin
    SndCmd({dump_chnl, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);

      case(dump_chnl)

        //// Now collect CH1 dump into a file ////
        8'h81 :begin
          $display("Commence Dumping Process for Channel 1");

          for (sample=0; sample<384; sample++)
            fork
              begin: timeout00
              repeat(6000) @(posedge clk);
              $display("ERR: Only received %d of 384 bytes on dump",sample);
              $stop();
              sample = 384;   // break out of loop
            end
            begin
              @(posedge resp_rdy);
              disable timeout00;
                $fdisplay(fptr1,"%h",resp);   // write to CH1dmp.txt
              clr_resp_rdy = 1;
              @(posedge clk);
              clr_resp_rdy = 0;
              if (sample%32==0) $display("At sample %d of dump",sample);
            end
            join
        end//8'h81 for ch1



        //// Now collect CH2 dump into a file ////
        8'h82:begin
          $display("Commence Dumping Process for Channel 2");

          for (sample=0; sample<384; sample++)
            fork
              begin: timeout11
              repeat(6000) @(posedge clk);
              $display("ERR: Only received %d of 384 bytes on dump",sample);
              $stop();
              sample = 384;   // break out of loop
            end
            begin
              @(posedge resp_rdy);
              disable timeout11;
                $fdisplay(fptr2,"%h",resp);   // write to CH1dmp.txt
              clr_resp_rdy = 1;
              @(posedge clk);
              clr_resp_rdy = 0;
              if (sample%32==0) $display("At sample %d of dump",sample);
            end
            join
        end


        //// Now collect CH3 dump into a file ////
        8'h83:begin
         $display("Commence Dumping Process for Channel 3");

         for (sample=0; sample<384; sample++)
            fork
              begin: timeout22
              repeat(6000) @(posedge clk);
              $display("ERR: Only received %d of 384 bytes on dump",sample);
              $stop();
              sample = 384;   // break out of loop
            end
            begin
              @(posedge resp_rdy);
              disable timeout22;
                $fdisplay(fptr3,"%h",resp);   // write to CH1dmp.txt
              clr_resp_rdy = 1;
              @(posedge clk);
              clr_resp_rdy = 0;
              if (sample%32==0) $display("At sample %d of dump",sample);
            end
            join
        end 
          


        //// Now collect CH4 dump into a file ////
        8'h84:begin
          $display("Commence Dumping Process for Channel 4");

          for (sample=0; sample<384; sample++)
            fork
              begin: timeout33
              repeat(6000) @(posedge clk);
              $display("ERR: Only received %d of 384 bytes on dump",sample);
              $stop();
              sample = 384;   // break out of loop
            end
            begin
              @(posedge resp_rdy);
              disable timeout33;
                $fdisplay(fptr4,"%h",resp);   // write to CH1dmp.txt
              clr_resp_rdy = 1;
              @(posedge clk);
              clr_resp_rdy = 0;
              if (sample%32==0) $display("At sample %d of dump",sample);
            end
            join
        end


        //// Now collect CH5 dump into a file ////
        8'h85:begin
         $display("Commence Dumping Process for Channel 5");

          for (sample=0; sample<384; sample++)
            fork
              begin: timeout44
              repeat(6000) @(posedge clk);
              $display("ERR: Only received %d of 384 bytes on dump",sample);
              $stop();
              sample = 384;   // break out of loop
            end
            begin
              @(posedge resp_rdy);
              disable timeout44;
                $fdisplay(fptr5,"%h",resp);   // write to CH1dmp.txt
              clr_resp_rdy = 1;
              @(posedge clk);
              clr_resp_rdy = 0;
              if (sample%32==0) $display("At sample %d of dump",sample);
            end
            join
        end
   endcase
end
endtask


//////////////////////////////////////////////////////////
///////// Task to opens all file ptrs for dump///////////
/////////////////////////////////////////////////////////
task dmp_file_open;
  fptr1 = $fopen("CH1dmp.txt","w");     // open file to write CH1 dumps to
  fptr2 = $fopen("CH2dmp.txt","w");     // open file to write CH2 dumps to
  fptr3 = $fopen("CH3dmp.txt","w");     // open file to write CH3 dumps to
  fptr4 = $fopen("CH4dmp.txt","w");     // open file to write CH4 dumps to
  fptr5 = $fopen("CH5dmp.txt","w");     // open file to write CH5 dumps to
endtask//dmp_file_open

/////////////////////////////////////////////////////////
///////// Task to close all file ptrs for dump///////////
////////////////////////////////////////////////////////
task dmp_file_close;
  repeat(10) @(posedge clk);
  $fclose(fptr1);
  $fclose(fptr2);
  $fclose(fptr3);
  $fclose(fptr4);
  $fclose(fptr5);  
endtask//dmp_file_close




/////////////////////////////////////////////////////////////////////////
///////////////////TASK to compare values of dump for CH1////////////////
/////////////////////////////////////////////////////////////////////////

task compare_CH1dmp;

  //// Now compare CH1dmp.txt to expected results ////
  fexp = $fopen("test1_expected.txt","r");
  fptr1 = $fopen("CH1dmp.txt","r");
  found_res = $fscanf(fptr1,"%h",res);
  found_expected = $fscanf(fexp,"%h",exp);
  $display("Starting comparison for CH1");
  sample = 1;
  mismatches = 0;
  while (found_expected==1) begin
    if (res!==exp)
    begin
      $display("At sample %d the result of %h does not match expected of %h",sample,res,exp);
    mismatches = mismatches + 1;
    if (mismatches>150) begin
      $display("ERR: Too many mismatches...stopping test1");
      $stop();
    end
        $display("mismatches are: %h", mismatches);

    end
  sample = sample + 1;
    found_res = $fscanf(fptr1,"%h",res);
    found_expected = $fscanf(fexp,"%h",exp);
  end 
endtask


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////// TASKS TO BE WRITTEN INTO THE TESTBENCH///////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////
////Task meant to check if data written to CH1dmp.txt is correct/////
/////////////////////////////////////////////////////////////////////
task CH1dump_check;

   //Open all files for dumping different channel data
   fptr1 = $fopen("CH1dmp.txt","w");     // open file to write CH1 dumps to

    en_AFE = 0;
    strt_tx = 0;                        // do not initiate protocol trigger for now

   initialization;

  ///// Set for CH1 triggering on positive edge and subsequently check for posack //////////
   C1TrigCfg_write;

  //////////////////////// Leave all other registers at their default ///////////////////////
  ///////////////////// and set RUN bit, but keep protocol triggering off////////////////////
  ///////////////////////////// but enable AFE first ///////////////////////////////////////
  /////////////Write value to TrigCfg and check of posach response received ////////////////

  TrigCfg_write;

  //////////////////////////Capture done bit polling//////////////////////////////////
  /////////// We read trig config polling for capture_done bit to be set /////////////
  poll_capturedone;

  /////////////////////////////////Dumping channel data///////////////////////////////
  channel_dump(DUMP_CH1);

  //////////////////////Close file that was written to///////////////////////////////
  repeat(10) @(posedge clk);
  $fclose(fptr1);

   /////////////////// Compare CH1dmp.txt to expected results /////////////////////////
  compare_CH1dmp;
  $display("***********************Finished Test 1: Dumped CH1 files into CH!dmp.txt and compared values obtained with reference provided***********************************");
endtask



//////////////////////////////////////////////////////////////////////////////////////////
////Task meant to check if data can be dumped into CH*dmp.txt files one after another/////
//////////////////////////////////////////////////////////////////////////////////////////
task consequtive_CHdumps;

     //Open all files for dumping different channel data
     fptr2 = $fopen("CH2dmp.txt","w");
     fptr3 = $fopen("CH3dmp.txt","w");
     fptr4 = $fopen("CH4dmp.txt","w");
     fptr5 = $fopen("CH5dmp.txt","w");

     en_AFE = 0;
     strt_tx = 0;                        // do not initiate protocol trigger for now

    initialization;
    //////// Set for CH1 triggering on positive edge and subsequently check for posack //////////
    C1TrigCfg_write;

    //////////////////////// Leave all other registers at their default ///////////////////////
    ///////////////////// and set RUN bit, but keep protocol triggering off////////////////////
    ///////////////////////////// but enable AFE first ///////////////////////////////////////
    /////////////Write value to TrigCfg and check of posAck response received ////////////////
    TrigCfg_write;

    //////////////////////////Capture done bit polling//////////////////////////////////
    /////////// We read trig config polling for capture_done bit to be set /////////////
    poll_capturedone;

    /////////////////////////////////Dumping channel data///////////////////////////////
    channel_dump(DUMP_CH2);
    channel_dump(DUMP_CH3);
    channel_dump(DUMP_CH4);

    //////////////////////Close file that was written to///////////////////////////////
    repeat(10) @(posedge clk);
    $fclose(fptr2);
    $fclose(fptr3);
    $fclose(fptr4);
    $fclose(fptr5);

    $display("*************************Finished Test2: Dumped contents to multiple channels consequtively**********************");

endtask






/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////Task meant to check if data is currectly written to and read from and if expected responses are received/////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
task ReadorWrite;
    $display("Starting ReadorWrite task");
     en_AFE = 0;
     strt_tx = 0;                        // do not initiate protocol trigger for now

    //Resetting all values to their defaults
    initialization;
    repeat(10)@(negedge clk);
    ////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////Writing to different registers///////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
     //Testing if sending an invalid command would result in a negack response//
     SndCmd({16'b1111000000000000});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    ChkResp(8'hee);

    repeat(10)@(negedge clk);

    /////////////////////Writing to VIL and VIH//////////////////
    SndCmd({SET_VIH_PWM, 8'hFA});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    ChkResp(8'hA5);

    repeat(10)@(negedge clk);

    SndCmd({SET_VIL_PWM, 8'h02});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    ChkResp(8'hA5);

    repeat(10)@(negedge clk);

    //////////////////Writing to MaskH and MaskL///////////////////
    SndCmd({SET_MASKH, 8'h10});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    ChkResp(8'hA5);

    repeat(10)@(negedge clk);

    SndCmd({SET_MASKL, 8'h10});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    ChkResp(8'hA5);

    repeat(10)@(negedge clk);

    ////////////////Writing to CH2TrigCfg and CH4TrigCfg//////////////
    SndCmd({SET_CH2_TRG, 8'h05});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'ha5);

    repeat(10)@(negedge clk);

    SndCmd({SET_CH4_TRG, 8'h05});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'ha5);

    repeat(10)@(negedge clk);

    ///////////////////Writing to the decimator register////////////////
    SndCmd({SET_DEC, 8'h02});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'ha5);

    repeat(10)@(negedge clk);

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////Reading the different registers we just wrote to and didnt write to, to ensure//////////////////////
    /////////////////////////////////////correct responses were received or values read/////////////////////////////////////
    
    //////////////Checking correct values were written into VIH and VIL////////////////////
    SndCmd({RD_VIH, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'hFA);

    repeat(10)@(negedge clk);

    SndCmd({RD_VIL, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'h02);

    repeat(10)@(negedge clk);

    /////.////////Checking correct values were written into MASKH and MASKL///////////////////
    SndCmd({RD_MASKH, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'h10);

    repeat(10)@(negedge clk);

    SndCmd({RD_MASKL, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'h10);

    repeat(10)@(negedge clk);

    //////////Checking correct values were written into CH2_TrigCfg and CH4_TrigCfg///////////////
    SndCmd({RD_CH2_TCFG, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'h05);

    repeat(10)@(negedge clk);

    SndCmd({RD_CH4_TCFG, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'h05);

    repeat(10)@(negedge clk);

    ///////////////Checking correct values were written into decimator register///////////////
    SndCmd({RD_DEC, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'h02);

    repeat(10)@(negedge clk);

    /////////////////////////Reading defaulted registers to ensure correct values stored/////////////////////
    SndCmd({RD_CH1_TCFG, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'h01);
    repeat(10)@(negedge clk);


     SndCmd({RD_CH3_TCFG, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'h01);
    repeat(10)@(negedge clk);


     SndCmd({RD_CH5_TCFG, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'h01);
    repeat(10)@(negedge clk);


     SndCmd({RD_MATCHH, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'h00);
    repeat(10)@(negedge clk);


    SndCmd({RD_MATCHL, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'h00);
    repeat(10)@(negedge clk);

     SndCmd({RD_BAUD_CNTH, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'h06);
    repeat(10)@(negedge clk);

     SndCmd({RD_BAUD_CNTL, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'hC8);

    repeat(10)@(negedge clk);
    $display("*********************************Finished Test3: Read and Write to multiple registers********************************");

endtask







////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////Task to check if changing the value of decimator changes the output wave observed, to that which would be expected     /////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

task decimator_change;

     //Open all files for dumping different channel data
     fptr6 = $fopen("CH1dmp_dec.txt","w");

     en_AFE = 0;
     strt_tx = 0;                        // do not initiate protocol trigger for now

    initialization;

    ///////////////////////////////////////////////////////////////////////////////////
    //////////Writing a different, higher value to the decimator register ////////////
    SndCmd({SET_DEC, 8'h04});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'ha5);
    repeat(10)@(negedge clk);


    //////// Set for CH1 triggering on positive edge and subsequently check for posack //////////
    C1TrigCfg_write;
    //////////////////////// Leave all other registers at their default ///////////////////////
    ///////////////////// and set RUN bit, but keep protocol triggering off////////////////////
    ///////////////////////////// but enable AFE first ///////////////////////////////////////
    /////////////Write value to TrigCfg and check of posAck response received ////////////////
    TrigCfg_write;

    //////////////////////////Capture done bit polling//////////////////////////////////
    /////////// We read trig config polling for capture_done bit to be set /////////////
    poll_capturedone;

   /////////////////////////////////Begin  channel dump/////////////////////////////
   SndCmd({DUMP_CH1, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);

  $display("Commence Dumping Process for Channel 1 with changed decimator value");
          for (sample=0; sample<384; sample++)
            fork
              begin: timeout66
              repeat(6000) @(posedge clk);
              $display("ERR: Only received %d of 384 bytes on dump",sample);
              $stop();
              sample = 384;   // break out of loop
            end
            begin
              @(posedge resp_rdy);
              disable timeout66;
                $fdisplay(fptr6,"%h",resp);   // write to CH1dmp.txt
              clr_resp_rdy = 1;
              @(posedge clk);
              clr_resp_rdy = 0;
              if (sample%32==0) $display("At sample %d of dump",sample);
            end
            join

    //////////////////////Close file that was written to///////////////////////////////
    repeat(10) @(posedge clk);
    $fclose(fptr6);
    $display("*************************Finished Test4: Dumped contents after changing dec value **********************");

endtask;







////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////Task to check if changing the values of VIH and VIL changes the output wave observed, to that which would be expected /////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

task VIHVIL_change;
   //Open all files for dumping different channel data
   fptr7 = $fopen("CH1dmp_VIH.txt","w");     // open file to write CH1 dumps to

    en_AFE = 0;
    strt_tx = 0;                        // do not initiate protocol trigger for now

   //Reset all previous values
   initialization;

   ///////////////////////////////////////////////////////////////////////////////////
  //////////Writing a different, value to the VIL and VIH registers ////////////

  SndCmd({SET_VIH_PWM, 8'hFA});
  //////////////////////////////////////
  // Now wait for command to be sent //
  ////////////////////////////////////
  @(posedge cmd_sent);
  @(posedge clk);
  ChkResp(8'hA5);
  repeat(10)@(negedge clk);
  SndCmd({SET_VIL_PWM, 8'h02});
  //////////////////////////////////////
  // Now wait for command to be sent //
  ////////////////////////////////////
  @(posedge cmd_sent);
  @(posedge clk);
  ChkResp(8'hA5);
  repeat(10)@(negedge clk);

  ///// Set for CH1 triggering on positive edge and subsequently check for posack //////////
   C1TrigCfg_write;

  //////////////////////// Leave all other registers at their default ///////////////////////
  ///////////////////// and set RUN bit, but keep protocol triggering off////////////////////
  ///////////////////////////// but enable AFE first ///////////////////////////////////////
  /////////////Write value to TrigCfg and check of posach response received ////////////////
  TrigCfg_write;

  //////////////////////////Capture done bit polling//////////////////////////////////
  /////////// We read trig config polling for capture_done bit to be set /////////////
  poll_capturedone;

  /////////////////////////////////Begin  channel dump/////////////////////////////

  SndCmd({DUMP_CH1, 8'h00});
  //////////////////////////////////////
  // Now wait for command to be sent //
  ////////////////////////////////////
  @(posedge cmd_sent);
  @(posedge clk);

  $display("Commence Dumping Process for Channel1 with changed VIH/VIL value");

          for (sample=0; sample<384; sample++)
            fork
              begin: timeout69
              repeat(6000) @(posedge clk);
              $display("ERR: Only received %d of 384 bytes on dump",sample);
              $stop();
              sample = 384;   // break out of loop
            end
            begin
              @(posedge resp_rdy);
              disable timeout69;
                $fdisplay(fptr7,"%h",resp);   // write to CH1dmp.txt
              clr_resp_rdy = 1;
              @(posedge clk);
              clr_resp_rdy = 0;
              if (sample%32==0) $display("At sample %d of dump",sample);
            end
            join

  //////////////////////Close file that was written to///////////////////////////////
  repeat(10) @(posedge clk);
  $fclose(fptr7);

  $display("*********************Finished Test5:Observed impact of changed VIH/VIL values on waveform for CH1 ********************");

endtask




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////Task to check if changing the value of trig_pos changes the output wave observed, to that which would be expected      /////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

task trigpos_change;

     //Open all files for dumping different channel data
     fptr8 = $fopen("CH1dmp_trigpos.txt","w");

     en_AFE = 0;
     strt_tx = 0;                        // do not initiate protocol trigger for now

    initialization;

    ///////////////////////////////////////////////////////////////////////////////////
    //////////Writing a different value to the trigposL/H registers //////////////////
    SndCmd({WRT_TRGPOSL, 8'h7E});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'ha5);
    repeat(10)@(negedge clk);

    SndCmd({WRT_TRGPOSH, 8'h01});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'ha5);
    repeat(10)@(negedge clk);

    
    //////// Set for CH1 triggering on positive edge and subsequently check for posack //////////
    C1TrigCfg_write;
    //////////////////////// Leave all other registers at their default ///////////////////////
    ///////////////////// and set RUN bit, but keep protocol triggering off////////////////////
    ///////////////////////////// but enable AFE first ///////////////////////////////////////
    /////////////Write value to TrigCfg and check of posAck response received ////////////////
    TrigCfg_write;

    //////////////////////////Capture done bit polling//////////////////////////////////
    /////////// We read trig config polling for capture_done bit to be set /////////////
    poll_capturedone;

   /////////////////////////////////Begin  channel dump/////////////////////////////
   SndCmd({DUMP_CH1, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);

  $display("Commence Dumping Process for Channel 1 with changed trigposL/H values");
          for (sample=0; sample<384; sample++)
            fork
              begin: timeout66
              repeat(6000) @(posedge clk);
              $display("ERR: Only received %d of 384 bytes on dump",sample);
              $stop();
              sample = 384;   // break out of loop
            end
            begin
              @(posedge resp_rdy);
              disable timeout66;
                $fdisplay(fptr8,"%h",resp);   // write to CH1dmp.txt
              clr_resp_rdy = 1;
              @(posedge clk);
              clr_resp_rdy = 0;
              if (sample%32==0) $display("At sample %d of dump",sample);
            end
            join

    //////////////////////Close file that was written to///////////////////////////////
    repeat(10) @(posedge clk);
    $fclose(fptr8);

    $display("*************************Finished Test6: Finished dumping contents of CH1 after trigpos was changed**********************");

endtask;



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////Task to check if SPI_triggering signal has been set to 1 so the correct signals can be muxed in for SPI triggering /////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
task SPItx_task;

  while(!SPI_triggering) begin

    @(negedge clk);

  end

  while(SPI_triggering)begin

    repeat(2)@(negedge clk);
    strt_tx = 1;
    repeat(2) @(negedge clk);
    strt_tx = 0;
    @(posedge done);
    //The done signal ensures that the strt_tx signal is sent a few times to trigger 

  end
endtask//start_SPI_tx




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////Task that encapsulates all other tasks required to check SPI_triggering  ///////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
task SPI_trig;
     //fptr3 = $fopen("CH3dmp.txt","w");
    fptr9 = $fopen("CH3dmp_SPI.txt","w"); 
  //1) CH*TRIG_CFG regs should all be at default
  //Reset all previous values
   initialization;

   SPI_triggering = 1;                        //initiate protocol trigger for SPI triggering
   repeat(50)@(posedge clk);
   SPI_triggering = 1;                        //initiate protocol trigger for SPI triggering
   repeat(50)@(posedge clk);

   //SPI_triggering = 1;                        //initiate protocol trigger for SPI triggering
   
   //3)Write value to TrigCfg such that SPI triggering is enabled
   //bit 5:capture = 0       bit 4:run = 0    bit 3:edg = 1(Shift on SCLK)       bit 2:len =0      bit 1:SPI_disable = 0    bit 0:UART_disable = 1 ==== 4'h1001
   $display("Setting values of reg TrigCfg as per requirements for SPI triggering");
   SndCmd({SET_TRG_CFG, 8'h09});
   /////////////////////////////////////
   // Now wait for command to be sent //
   ////////////////////////////////////
   @(posedge cmd_sent);
   @(posedge clk);

   $display("Setting values of decimator register for SPI triggering");
   //////////////////Setting values of decimator reg to 2 to better view the waveform/////////////
   SndCmd({SET_DEC, 8'h02});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
    repeat(2)@(negedge clk);
    ChkResp(8'ha5);
    repeat(10)@(negedge clk);

   //////////////////Setting values for MatchH and L to compare with tx_data////////////////////////
   $display("Setting values of high and low byte of Match register to be same as the tx_data");
   SndCmd({SET_MATCHH, 8'hAB});
   /////////////////////////////////////
   // Now wait for command to be sent //
   ////////////////////////////////////
   @(posedge cmd_sent);
   @(posedge clk);
   SndCmd({SET_MATCHL, 8'hCD});
   /////////////////////////////////////
   // Now wait for command to be sent //
   ////////////////////////////////////
   @(posedge cmd_sent);
   @(posedge clk);


    //3)Write value to TrigCfg such that SPI triggering is enabled
   //bit 5:capture = 0       bit 4:run =1    bit 3:edg = 1(Shift on SCLK)       bit 2:len =0      bit 1:SPI_disable = 0    bit 0:UART_disable = 1 ==== 4'h1001
   $display("Setting values of reg TrigCfg as per requirements, run =1");
   SndCmd({SET_TRG_CFG, 8'h19});
   /////////////////////////////////////
   // Now wait for command to be sent //
   ////////////////////////////////////
   @(posedge cmd_sent);
   @(posedge clk);

    //Polling for capture done
    poll_capturedone;

    $display("Do MOSI channel 3 dump");
   /////////////////////////////////Begin  channel dump/////////////////////////////
   SndCmd({DUMP_CH3, 8'h00});
    //////////////////////////////////////
    // Now wait for command to be sent //
    ////////////////////////////////////
    @(posedge cmd_sent);
    @(posedge clk);
  $display("Commence Dumping Process for Channel 3 with SPI triggering");
          for (sample=0; sample<384; sample++)
            fork
              begin: timeout68
              repeat(6000) @(posedge clk);
              $display("ERR: Only received %d of 384 bytes on dump",sample);
              $stop();
              sample = 384;   // break out of loop
            end
            begin
              @(posedge resp_rdy);
              disable timeout68;
                $fdisplay(fptr9,"%h",resp);   // write to CH1dmp.txt
              clr_resp_rdy = 1;
              @(posedge clk);
              clr_resp_rdy = 0;
              if (sample%32==0) $display("At sample %d of dump",sample);
            end
            join

  //////////////////////Close file that was written to///////////////////////////////
  repeat(10) @(posedge clk);
  //$fclose(fptr3);
  $fclose(fptr9);

  $display("********************* Finished Test 7: Observed and ensured SPI triggered occured correcttly ********************");
endtask