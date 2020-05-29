module UART_rx (clk, rst_n, RX, clr_rdy, rx_data, rdy);

  input clk, rst_n;         //Clock signal and active low rese
  input  RX;                //Asynch serial data input
  input  clr_rdy;           //Knocks down rdy when asserted
  output reg[7:0] rx_data;  //Byte long information received
  output reg rdy;          //Asserted when byte long data received and stays high, until start bit of next byte comees in, or clr_rdy asserted

  //Internal local variables and signals used in the 
  reg [3:0] bit_cnt;               //Counts till 10 so all bits are received starting from start bit to data to stop bit
  reg [5:0] baud_cnt;              //Keeps track of the baud_cycle value, for us baud rate = 34 bauds 
  reg [8:0] rx_shft_reg;           //Shift register with received data  
  reg start, receiving, set_rdy;  //FSM Outputs
  reg shift;  
  reg RX_new1, RX_new2;           //RX value flopped for avoiding metastability 
  assign shift = (baud_cnt == 0); //Shift is asserted when baud_cnt = 0 
  assign rx_data = rx_shft_reg [7:0] ; //Since we don't want the stop bit in the MSB

  //Using enum to define states in order for easy debugging
  typedef enum reg [1:0] {IDLE, RECEIVE} state_t;
  state_t state, nxt_state;
 
  //Double flopping RX Signal since it is an asynchronous input that can cause metastability issues
  always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        RX_new1 <= 1'b1;    //When rst_n asserted, presets to 1
        RX_new2 <= 1'b1;
    end
    else begin
        RX_new1 <= RX; 
        RX_new2 <= RX_new1; //Double flopping
    end
  end
   
  //////////////Always block for the Receiver's Shifter block///////////////
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
       rx_shft_reg <= 8'h00;                        //Resets to 0
    else if(shift)  
       rx_shft_reg <= {RX_new2, rx_shft_reg[8:1]}; //Since the LSB of the data is received first
    else 
       rx_shft_reg <= rx_shft_reg ;               //Make it retain its original value 
   end

  //////////////Always block to infer baud_counter///////////////////////
  always_ff @(posedge clk or negedge rst_n) begin                                                                                                                                                           
    if (!rst_n)
      baud_cnt <= 17;               //Reset to a value in time half way through a baud period                                                                                                                      
    else if (start)
      baud_cnt <= 17;               //Start half way through a baud period                                                                                                                                  
    else if (shift)
      baud_cnt <= 34;               //Full baud period value                                                                                                       
    else if ({shift, receiving} == 2'b01)
      baud_cnt <= baud_cnt - 1 ;       //baud_cnt is decremented when receiving is 1                  
    else 
       baud_cnt <= baud_cnt ;          //If shift and receiving are deasserted, baud_cnt retains value                                                                                         
  end


  /////////Always block to infer the bit_cnt block, no different from in a transmitter/////////
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n)                           
        bit_cnt <= 4'h0;
    else if(start)
        bit_cnt <= 4'h0; 
    else if ({start, shift} == 2'b01)     
        bit_cnt <= bit_cnt + 1;  //When shift is asserted, bit_cnt is incremented
    else if ({start, shift} == 2'b00)      
        bit_cnt <= bit_cnt;      //When neither shift nor start is asserted, bit count retains its value
    else
        bit_cnt <= bit_cnt;     //Else Make it retain its original value
  end

 /////////////////////////////////////////////
///////////DEFINING STATE MACHINE////////////
////////////////////////////////////////////

  //Inferring a ff for the states
  always@(posedge clk, negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;
  end

  //Inferring the combinational logic for state trasitions
  always_comb begin
   //Default all outputs to prevent latches
   receiving = 0;
   start = 0;
   set_rdy = 0;
   nxt_state = IDLE; 
  
   case(state) 
      IDLE:  begin
                if (RX_new2 == 0) begin
                     start = 1 ;
                     nxt_state = RECEIVE;
                end
                else nxt_state = IDLE; 
             end

      RECEIVE:begin
                if (bit_cnt == 10) begin
                   start = 0; 
                   set_rdy = 1;
                   nxt_state = IDLE; 
                end
                else begin
                  receiving = 1; 
                  nxt_state = RECEIVE;  
                end
              end
       default : nxt_state = IDLE;    //If FSM glitches, take it back to reset state
   endcase 
  end

  ////////////Flopping the rdy signal////////////////// 
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      rdy <= 1'b0 ;
    else if ((clr_rdy || start) == 1)
      rdy <= 1'b0 ;   //rdy is reset when start bit of next byte comees in, or clr_rdy asserted                                                                                                                                
    else if (set_rdy)
      rdy <= 1'b1 ;   //Once all bits are ready, set rdy is asserted and rdy is asserted
    else 
      rdy <= rdy;    //Else retains it's original value 
  end

endmodule