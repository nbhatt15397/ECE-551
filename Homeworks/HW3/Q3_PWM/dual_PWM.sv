module dual_PWM (VIL_PWM, VIH_PWM, VIH, VIL, rst_n, clk);

 input [7:0] VIH; //8 bit vector specifying the duty cycle higher threshold i.e VIH 
 input [7:0] VIL; //8 bit vector specifying the duty cycle lower threshold i.e VIL
 input rst_n, clk;//Asynch low reset and clock signal
 output VIL_PWM;  //PWM output that will be passed to create the VIH threshold
 output VIH_PWM;  //PWM output that will be passed to create the VIL threshold

 /*We instantiate two copies of pwm8 unit, one for the VIL_PWM to be outputted from and 
   another for the VIH_PWM  to be outputted from */

 pwm8 I0 (.rst_n(rst_n), .clk(clk), .duty(VIL), .PWM_sig(VIL_PWM));

 pwm8 I1 (.rst_n(rst_n), .clk(clk), .duty(VIH), .PWM_sig(VIH_PWM));

endmodule
