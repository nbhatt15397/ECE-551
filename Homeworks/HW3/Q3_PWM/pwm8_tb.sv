module pwm8_tb ();

 logic rst_n, clk;  //Asynch Low Reset and clock signal
 logic [7:0]  duty; //Duty cycle value
 logic [7:0] PWM_sig; //PWM_sig outputted


 ////////////////////////////////////////////////////////////
 ////////////////////////Instantiate DUT/////////////////////
 ////////////////////////////////////////////////////////////
 pwm8 iDUT (.rst_n(rst_n), .clk(clk), .duty(duty), .PWM_sig(PWM_sig));

initial begin

 //Start off by resetting and then de-asserting reset so cnt can function properly
 clk = 0;
 rst_n = 0;
 #30;
 rst_n = 1;
 #30;
  //By setting the duty cycle values we will observe the PWM_sig waveform to see if we got the expected values
  @(posedge clk) begin
    duty = 8'h7f;
    #50;
    $display("The value of PWM_sig is =",PWM_sig);
   end 

  #30000;

  @(posedge clk) begin
    duty = 8'h3f;
    #500;
   end 
end

//Clock signal 
always 
    #5 clk = ~clk;

endmodule
