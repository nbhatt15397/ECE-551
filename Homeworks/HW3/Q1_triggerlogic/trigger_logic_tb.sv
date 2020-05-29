module trigger_logic_tb ();

 logic triggered, CH1Trig, CH2Trig, CH3Trig, CH4Trig, CH5Trig, protTrig, set_capture_done, armed, rst_n, clk;

 /////////////////////////////////////////////////
 /////////////////Instantiate DUT/////////////////
 /////////////////////////////////////////////////
 trigger_logic DUT (.triggered(triggered), .CH1Trig(CH1Trig), .CH2Trig(CH2Trig), .CH3Trig(CH3Trig), .CH4Trig(CH4Trig), .CH5Trig(CH5Trig), .protTrig(protTrig), .set_capture_done(set_capture_done), .armed(armed), .rst_n(rst_n), .clk(clk));
 

 initial begin

  //Reset all signals to start testing
  clk = 0;
  rst_n = 0; 
  armed = 0;
  set_capture_done = 0;
  rst_n = 1;
  #50;

  ///////////////////////////////////////////////////////////////////////////////////////////
  //Test Case 1, Since armed = 0, even though all channels are 1, triggered should be 0    //
  ///////////////////////////////////////////////////////////////////////////////////////////
  @(posedge clk);
  armed = 0 ;
  CH1Trig =1;
  CH2Trig =1;
  CH3Trig =1;
  CH4Trig =1;
  CH5Trig =1;
  protTrig =1;
  #100;      // You need to give enough time for these signal values to be set before testing if it changed anything

  if (triggered) begin
    $display ("Error! Triggered was supposed to be 0 because armed is 0, even though all Channels are 1, the value of triggered you got is = %b", triggered);
    $stop ();
  end


  ///////////////////////////////////////////////////////////////////////////////////////////////////
  //Test Case 2, armed is set to 1, but one of the channels is set is 0, so triggered should stay 0//
  ///////////////////////////////////////////////////////////////////////////////////////////////////
   @(posedge clk);
  CH1Trig =1;
  CH2Trig =0;
  CH3Trig =1;
  CH4Trig =1;
  CH5Trig =1;
  protTrig =1;
  armed =1;
  #100;      // You need to give enough time for these signal values to be set before testing if it changed anything

  if (triggered) begin
    $display ("Error! Triggered was supposed to be 0 because one of the trigger channels is 0, even though armed =1, the value of triggered you got is = %b", triggered);
    $stop ();
  end 


  ////////////////////////////////////////////////////////////////////////////
  //Test Case 3, armed =1 and all channels are 1, so triggered should be =1 //
  ////////////////////////////////////////////////////////////////////////////
   @(posedge clk);
   armed =1;
   CH1Trig =1;
   CH2Trig =1;
   CH3Trig =1;
   CH4Trig =1;
   CH5Trig =1;
   protTrig =1;
   #100;      // You need to give enough time for these signal values to be set before testing if it changed anything

  if (!triggered) begin
    $display ("Error! Triggered was supposed to be 1 because armed is set to 1 and the channels are all set to high, the value of triggered you got is = %b", triggered);
    $stop ();
  end


  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //Test Case 4, armed is set to 0 now, but all Channels are 1, but triggered should maintain its old value of 1//
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    @(posedge clk);
   CH1Trig =1;
   CH2Trig =1;
   CH3Trig =0;
   CH4Trig =1;
   CH5Trig =1;
   protTrig =1;
   armed = 0;
   #100;      // You need to give enough time for these signal values to be set before testing if it changed anything

   if (!triggered) begin
    $display ("Error! Triggered was supposed to be 1 because even though armed = 0 and one of the channel values = 0, it should have held its previous value, the value of triggered you got is = %b", triggered);
    $stop ();
   end 


  //////////////////////////////////////////////////////////////////////////
  //Test Case 5, since set_capture_done =1 here, we expect triggered = 0 ///
  //////////////////////////////////////////////////////////////////////////
  @(posedge clk);
   set_capture_done =1;
   #100;      // You need to give enough time for these signal values to be set before testing if it changed anything

   if (triggered) begin
    $display ("Error! Triggered was supposed to be 0 because set_capture_done =1, the value of triggered you got is = %b", triggered);
    $stop ();
   end


   $display ("WOOHOOO YOUR TEST PASSED!!!!TIME TO CELEBRATE!!!!!");
   $stop ();

  end 
  
  //Setting up the clk signal
  always
   #10 clk = ~clk;

endmodule
