module UART_RX_prot(clk,rst_n,RX,baud_cnt,mask,match,UARTtrig);

//////////////////////////////////////
// UART RX for protocol triggering //
////////////////////////////////////

input clk,rst_n;			// clock and active low reset
input RX;					// RX is the asynch serial input (need to double flop)
input [15:0] baud_cnt;		// determine baud rate of protocol.
input [7:0] mask;			// a set bit indicates a don't care in comparison against match
input [7:0] match;			// byte we are trying to match
output UARTtrig;			// signifies to core a byte has been received

reg state,nxt_state;	 	// I can name that tune in 2 states
reg [8:0] shift_reg;		// shift register MSB will contain stop bit when finished
reg [3:0] bit_cnt;			// bit counter (need extra bit for start bit)
reg [15:0] baudCntr;		// baud rate counter set to baud_cnt and decremented
reg rx_ff1, rx_ff2;			// back to back flops for meta-stability

reg start, complete, receiving;		// set in state machine

wire shift;
wire [7:0] rx_msk,match_msk;

parameter IDLE  = 1'b0;
parameter RCV    = 1'b1;

////////////////////////////
// Infer state flop next //
//////////////////////////
always @(posedge clk or negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;

/////////////////////////
// Infer bit_cnt next //
///////////////////////
always @(posedge clk or negedge rst_n)
  if (!rst_n)
    bit_cnt <= 4'b0000;
  else if (start)
    bit_cnt <= 4'b0000;
  else if (shift)
    bit_cnt <= bit_cnt+1;

//////////////////////////
// Infer baudCntr next //
////////////////////////
always @(posedge clk or negedge rst_n)
  if (!rst_n)
    baudCntr <= 16'hffff;						// start such that shift will not be asserted
  else if (start)
    baudCntr <= {1'b0,baud_cnt[15:1]};			// load at half a bit time for sampling in middle of bits
  else if (shift)
    baudCntr <= baud_cnt;			// reset when baud count is full value for 921600 baud with 40MHz clk
  else if (receiving)
    baudCntr <= baudCntr-1;		// only burn power decrementing if transmitting

////////////////////////////////
// Infer shift register next //
//////////////////////////////
always @(posedge clk)
  if (shift)
    shift_reg <= {RX,shift_reg[8:1]};   // LSB comes in first

////////////////////////////////////////////////
// RX is asynch, so need to double flop      //
// prior to use for meta-stability purposes //
/////////////////////////////////////////////
always @(posedge clk or negedge rst_n)
  if (!rst_n)
    begin
      rx_ff1 <= 1'b1;			// reset to idle state
      rx_ff2 <= 1'b1;
    end
  else
    begin
      rx_ff1 <= RX;
      rx_ff2 <= rx_ff1;
    end

//////////////////////////////////////////////
// Now for hard part...State machine logic //
////////////////////////////////////////////
always @(state,rx_ff2,bit_cnt)
  begin
    //////////////////////////////////////
    // Default assign all output of SM //
    ////////////////////////////////////
    start         = 0;
    complete      = 0;
    receiving     = 0;
    nxt_state     = IDLE;	// always a good idea to default to IDLE state
    
    case (state)
      IDLE : begin
        if (!rx_ff2)		// did fall of start bit occur?
          begin
            nxt_state = RCV;
            start = 1;
          end
        else nxt_state = IDLE;
      end
      default : begin		// this is RCV state
        if (bit_cnt==4'b1010)
          begin
            complete = 1;
            nxt_state = IDLE;
          end
        else
          nxt_state = RCV;
        receiving = 1;
      end
    endcase
  end

////////////////////////////////////
// Continuous assignement follow //
//////////////////////////////////
assign shift = ~|baudCntr; 						// shift when baudCntr is zero
/// assert UARTtrig if a match when reception complete ///
assign rx_msk = shift_reg[7:0] | mask;
assign match_msk = match | mask;
assign UARTtrig = (rx_msk==match_msk) ? complete : 1'b0;

endmodule
