module pwm8 (rst_n, clk, duty, PWM_sig);

 input rst_n, clk; //Clock and asynch low reset 
 input [7:0] duty; //8-bit duty input to compare value of cnt against
 output reg PWM_sig;//output generated from the flopped input after combination logic check
 reg [7:0] cnt;    //Keeps cnt of the value cnted up to
 logic in_PWM; //input to flip flop after combinational logic has been checked 


  //Combinational block that sets in_PWM, the input to the final flop
  always_comb begin

    //As long as cnt is less than or equal to duty we set in_PWM = 1, else in_PWM = 0
    if (cnt <= duty)
       in_PWM =1'b1;
    else 
       in_PWM =1'b0;

  end 


  //Always block that models the 8-bit cnter 
  always_ff@(posedge clk, negedge rst_n) begin
    if(~rst_n)    
       cnt <= 8'h00;   //Reset value in cnter if rst_n = 0 (asserted)
    else 
       cnt <= cnt + 1; //Increment otherwise
 end


  //Models the ff through which the PWM_sig outputs, PWM has to come directly out of a ff b/c
   //we cannot affird for it to glitch
  always_ff@(posedge clk, negedge rst_n) begin
   
   if(~rst_n) 
     PWM_sig <= 1'b0; //We Reset the value in PWM_sig if rst_n = 0 (asserted)
   else
     PWM_sig <= in_PWM; //Otherwise, PWM_sig is the value of in_PWM calculated using combinational logic 

  end

endmodule
