module UART_tx1 (TX, tx_done, tx_data, trmt, clk, rst_n);

 input clk, rst_n, trmt;     //Transmitter has a clock signal, Asynch reset, and a signal trmt=1 when we need to begin transmitting
 input [7:0] tx_data;       //Data to transmit 
 output logic tx_done;      //tx_done is asserted back to the master SM
 output logic TX;          //TX is the serial data we are producing  

 logic load, transmitting, set_done, shift, clr_done; //Defining internal variables within the UART_tx
 logic [11:0] baud_cnt;    //Used to track baud rate 
 logic [9:0] tx_shft_reg;  //10 bit data value that holds data and start, stop bits
 logic [3:0] bit_cnt;     //4 bit vector that keeps track of how many bits have been transmitted
 localparam BAUD = 34;   //Local parameter that defines how many baud cycles we need to count up to 
 
 
 //Defining enumerated state names for SM use
 typedef enum reg[1:0] {LOAD_IDLE, TRANSMIT} state_t;
 state_t state, nxt_state;


 ///////////Always block for block that manages the data and shifts bits out using a 10 bit data_in reg signal////////////////////
 always @(posedge clk, negedge rst_n) begin
   if (!rst_n)
        tx_shft_reg <= 10'b1111111111;            //Resetting TX_Done to all 1s
   else if ({load, shift} == 2'b00) 
        tx_shft_reg <= tx_shft_reg;              //Retains value of tx_shift_reg while waiting for a shift to be asserted
   else if ({load, shift} == 2'b01)       
        tx_shft_reg <= {1'b0, tx_shft_reg[9:1]}; //Shift the data_in right one bit, one every baud clocks
   else if(load) 
        tx_shft_reg <= {1'b1, tx_data, 1'b0};   //Start pushing data from LSB, so we append Start Bit (0) to the LSB and Stop bit(1) to the MSBransmit 
   else tx_shft_reg <= 0;                      //This is not necessary but if the machine reaches a weird state, it always helps
 end

 assign TX = tx_shft_reg[0];               //TX, the data going out, is the least sig bit of the data pushed out 


 /////////////Always block for Baud Counter////////////
 always @(posedge clk, negedge rst_n) begin
   if (!rst_n)
     baud_cnt <= 6'b0;
   else if(load | shift) 
     baud_cnt <= 6'b0;               //Clear the counter if load/shft signals are asserted
   else if (transmitting) 
     baud_cnt <= baud_cnt + 1;       //While we are transmitting, we keep counting and incrementing till we reach 1 baud cycle
  else if({load | shift, transmitting} == 2'b00)
     baud_cnt <= baud_cnt ;          //Retain baud_cnt value when neither transmitting nor loading/shifting
  else 
     baud_cnt <= 0 ;                 //This is not necessary but if the machine reaches a weird state, it always helps 
 end

 assign shift = (baud_cnt == BAUD); //When the baud counter has counted up to 34 i.e 1 baud cycle, shift is asserted


 //4 bit counter that counts till 10, to push out 10 bits of data 
 always @(posedge clk) begin
  if (load) 
    bit_cnt <= 4'h0;        //Clear the counter when load asserted
  else if ({load, shift} == 2'b01)
    bit_cnt <= bit_cnt + 1 ; //Everytime we shift one bit, we increment the bit_cnt
  else if ({load, shift} == 2'b00)
    bit_cnt <= bit_cnt;     //Retain value of bit_cnt while waiting for load, shft
  else
    bit_cnt <= 1'b0;        //This is not necessary but if the machine reaches a weird state, it always helps 
 end

  //////////////////////////////////////////////////////////////////////////////
 ///////Insert State diagram block here, TWO states LOAD_IDLE and Transmit//////
 //////////////////////////////////////////////////////////////////////////////

 ////////Infer State Flops/////////
 always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n)    state <= LOAD_IDLE;  //FSM resets to this state
   else          state <= nxt_state; //Else FSM transits to next state 
 end

  ////////////////////////////FSM conbinational logic//////////////////////////

 always_comb begin
 //default outputs set to prevent latching 
   load = 0;
   set_done = 0;
   clr_done = 0;
   nxt_state = TRANSMIT;
   transmitting = 0;
    case (state)
      LOAD_IDLE:begin
                  set_done = 1'b0;           //For all transitions in this stage, set_done is 0
                  if (trmt) begin
                        load = 1'b1;
                        clr_done = 1'b1;
                        nxt_state = TRANSMIT;
                  end
                  else nxt_state = LOAD_IDLE ; 
                end

      TRANSMIT: begin
                   load = 1'b0;
                  if (bit_cnt == 4'd10) begin
                        set_done = 1'b1;     //Once all bits have been transferred, set_done =1
                        nxt_state = LOAD_IDLE; 
                        clr_done = 1'b0;    
                  end
                  else begin
                         nxt_state = TRANSMIT; 
                         transmitting = 1'b1;
                  end 
                end 
                  
       default:   nxt_state = LOAD_IDLE;   //Incase our FSM glitches, it will always go back to the IDLE state
    endcase
 end 

 //Flopping the tx_done ouput
 always @ (posedge clk) begin
  if (!rst_n)
    tx_done <= 1'b0;     //Reset the value stored in flop if rst_n is asserted
  else if (clr_done)
    tx_done <= 1'b0;     //clr_done also knocks out the value stored in tx_done
  else if (set_done)
    tx_done <= set_done; //Once set_done is asserted, tx_done is also asserted
  else
    tx_done <= tx_done; //For all other conditions, tx_done retains it's value
 end

endmodule