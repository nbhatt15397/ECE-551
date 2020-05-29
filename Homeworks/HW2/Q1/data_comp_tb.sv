module data_comp_tb ();

  //Defining input stim for the DUT
  logic [7:0] match, mask, serial_data;
  logic serial_vld; 
  logic prot_trig; //Defining output for the DUT

  ////////////////////////////////////////
  ////////////Instantiate DUT/////////////
  ////////////////////////////////////////
  data_comp iDUT (.prot_trig(prot_trig), .match(match[7:0]), .mask(mask[7:0]), .serial_vld(serial_vld) ,.serial_data(serial_data[7:0]) );

   
 initial begin 

   //Test Case 1
   serial_vld = 0;
   match = 8'hAB;
   serial_data = 8'hAB;
   mask = 8'h10;
   #10;
      if (prot_trig != 0) begin 
      $display ("Error, the expected answer was prot_trig = 0, but you got prot_trig = %b", prot_trig);
      $stop ();
      end 
   #10;

   //Test Case 2
   serial_vld = 1'b1;
   match = 8'hAB;
   serial_data = 8'hA0 ;
   mask = 8'h0B;
   #10;
     if (prot_trig != 1) begin 
      $display ("Error, the expected answer was prot_trig = 1, but you got prot_trig = %b", prot_trig);
      $stop ();
     end 
   #10;

   //Test Case 3
   serial_vld = 1'b0;
   match = 8'hAB;
   serial_data = 8'hAB ;
   mask = 8'h10;
   #10;
     if (prot_trig != 0) begin 
      $display ("Error, the expected answer was prot_trig = 0, but you got prot_trig = %b", prot_trig);
      $stop ();
     end 
   #10;

   //Test Case 4
   serial_vld = 1'b1;
   match = 8'hBB;
   serial_data = 8'h83 ;
   mask = 8'h3C;
   #10;
     if (prot_trig != 1) begin 
      $display ("Error, the expected answer was prot_trig = 1, but you got prot_trig = %b", prot_trig);
      $stop ();
     end 
   #10;
    
   //Test Case 5
   serial_vld = 1'b0;
   match = 8'hBB;
   serial_data = 8'h83 ;
   mask = 8'h3C;
   #10;
     if (prot_trig != 0) begin 
      $display ("Error, the expected answer was prot_trig = 0, but you got prot_trig = %b", prot_trig);
      $stop ();
     end 
   #10;

   //Test Case 6
   serial_vld = 1'b1;
   match = 8'h01;
   serial_data = 8'h11 ;
   mask = 8'h00;
   #10;
     if (prot_trig != 0) begin 
      $display ("Error, the expected answer was prot_trig = 0, but you got prot_trig = %b", prot_trig);
      $stop ();
     end 
   #10;
  
   $display ("YAHOOO!!!! YOU've passed the test!!!!");
   $stop();
 end
endmodule
