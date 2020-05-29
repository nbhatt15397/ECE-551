/* 
3) a) 
A D-LAtch is an asynchronouse level sensitive device that is transparent when the enable signal is asserted.
A D-Latch acts like a wire when it is enabled, but preserves the current value when it is disabled.  
The code does not correctly infer a latch because a latch is only transparent when the enable signal is asserted,
and is not transparent otherwise, but this behaviour has not been inferred by the code. The code infers that the latch is
edge sensitive instead of level sensitive.Also, the always block has the clk signal in the sensitivity list which implies that every 
change in the clk signal, results in the always block being executed, which is not the behaviour we expect of a D-Latch.
*/

//3) b) A D-ff with Active High synch Reset and an Enable 

module d_ff_asyn_Rst (D, clk, rst, enable, Q);

 // Defining input ports
  input D;
  input clk;
  input rst;
  input enable;

  //Defining output port
  output reg Q;

  always_ff @(posedge clk) begin  

    if (rst) begin
     Q <= 1'b0;                // If synch rst is high, Q is assigned to 0
    end

    else if (enable) begin
     Q <= D;
    end
     
    else begin
     Q <= Q;
    end 

  end
endmodule


//3) c) D-FF with Asynch Active Low Reset and Active High Enable 

module d_ff_asyn_Rst_n (D, clk, rst_n, h_enable, Q);

  input D;
  input clk;
  input rst_n;
  input h_enable;
  output reg Q;

  always_ff @(posedge clk, negedge rst_n) begin  

    if (!rst_n) begin
     Q <= 1'b0;          // If Synch Low Reset asserted, Q is assigned to 0 
    end

    else if (h_enable) begin
     Q <= D;
    end
     
    else begin
     Q <= Q;
    end 

  end
endmodule

//3) d) J-K ff with active high synch reset

module JK_ff (J, K, clk, rst, Q);
  input J;
  input K;
  input clk;
  input rst;
  output reg Q;
  
  always_ff @(posedge clk) begin;

   if (rst) begin                   //Active high synch reset has highest priority
    Q = 1'b0;
   end
   
     else if ((J ==1'b0) && (K==0'b0)) begin
     Q <= Q;				       //Results in Same Q
     end

       else if ((J ==1'b0) && (K==1'b1)) begin
       Q <= 0;                                  //Results in Reset
       end

         else if ((J ==1'b1) && (K==1'b0)) begin
         Q <= 1;                                //Results in Set
         end
    
           else if ((J ==1'b1) && (K==1'b1)) begin
           Q <= ~Q;                            //Results in Toggle of previous Q
           end

         else 
          Q <= Q;                       //Results in No change 
   end

endmodule

/* 3) e) The usage of always_ff block in System Verilog does not ensure that
a ff will be inferred. However it is different from the always block 
used in Verilog because always_ff warns the user if the statements in the block did not infer a flip-flop
 whereas a simple always block does not do that.
*/