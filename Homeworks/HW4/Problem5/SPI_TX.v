//////////////////////////////////////////////////////////////////////////
// SPI master module that transmits 8-bit or 16-bit packets (tx_data) //
// The edge that MOSI shifts on is determined by pos_edge.  The width //
// of the packet 8 or 16-bits is determined by width8 (1 ==> 8-bit)  //                                    //
// SCLK is currently set for 1:16 of clk                            //
/////////////////////////////////////////////////////////////////////

module SPI_TX(clk,rst_n,SS_n,SCLK,wrt,done,tx_data,MOSI,pos_edge,width8);

  input clk,rst_n,wrt;
  input [15:0] tx_data;						// command/data to transmit
  input pos_edge;							// if high then MOSI shifted on + edge SCLK
  input width8;								// if high then only an 8-bit packet is transmitted
  output SS_n,SCLK,done,MOSI;

  reg [1:0] state,nstate;
  reg [4:0] dec_cntr;
  reg [4:0] bit_cntr;
  reg [15:0] shft_reg;			// stores the output to be serialized on MOSI
  reg done;
  reg SS_n;

  reg rst_cnt,en_cnt,shft;

  localparam IDLE = 2'b00;
  localparam BITS = 2'b01;
  localparam TRAIL = 2'b10;
  localparam WAIT_DONE = 2'b11;

  ///////////////////////////////
  // Implement state register //
  /////////////////////////////
  always @(posedge clk, negedge rst_n)
    if (!rst_n)
      state <= IDLE;
    else
      state <= nstate;

 /////////////////////////////////////////
  // Implement parallel to serial shift //
  // register whos MSB forms MOSI      //
  //////////////////////////////////////
  always @(posedge clk, negedge rst_n)
    if (!rst_n)
	  shft_reg <= 16'h0000;
	else if (wrt)
      shft_reg <= tx_data;
    else if (shft)
      shft_reg <= {shft_reg[14:0],1'b0};

  ////////////////////////////
  // Implement bit counter //
  //////////////////////////
  always @(posedge clk)
    if (rst_cnt)
      bit_cntr <= 5'b00000;
    else if (en_cnt)
      bit_cntr <= bit_cntr + 1;

  //////////////////////////////
  // Implement pause counter //
  ////////////////////////////
  always @(posedge clk)
    if (rst_cnt)
      dec_cntr <= 5'b01011;
    else
      dec_cntr <= dec_cntr + 1;

  assign SCLK = dec_cntr[4];

  ////////////////////////////////////////
  // Implement SM that controls output //
  //////////////////////////////////////
  always @(state, wrt, dec_cntr, bit_cntr)
    begin
      //////////////////////
      // Default outputs //
      ////////////////////
      rst_cnt = 0; 
      SS_n = 1;
      en_cnt = 0;
      shft = 0;
      done = 1;
	  nstate = IDLE;

      case (state)
        IDLE : begin
          rst_cnt = 1;
          if (wrt) 
            nstate = BITS;
          else
 		    nstate = IDLE;
        end
        BITS : begin
          ////////////////////////////////////
          // For the 16 bits of the packet //
          //////////////////////////////////
		  done = 0;
          SS_n = 0;
          en_cnt = (pos_edge) ? (~dec_cntr[4] & &dec_cntr[3:0]) : &dec_cntr;
          shft = (pos_edge) ? (|bit_cntr)&en_cnt : en_cnt;
          if ((~width8 && (bit_cntr==5'h10)) || (width8 & (bit_cntr==5'h08))) 
            nstate = TRAIL;
          else
            nstate = BITS;         
        end
        TRAIL : begin
          /////////////////////////////////////////////////////////
          // This state keeps SS_n low for a while (back porch) //
          ///////////////////////////////////////////////////////
		  done = 0;
          SS_n = 0;
          if (((&dec_cntr[3:1])&~pos_edge) || ((dec_cntr==5'h03)&pos_edge)) begin
		    rst_cnt = 1;
            nstate = WAIT_DONE;
		  end else
		    nstate = TRAIL;
        end
		WAIT_DONE : begin
		  //////////////////////////////////////////////////////
		  // If we assert done too soon higher level SM will //   
		  // initiate next transaction too soon, so delay   //
		  ///////////////////////////////////////////////////
		  done = 0;
		  if (&dec_cntr[3:1])
		    nstate = IDLE;
		  else
		    nstate = WAIT_DONE;
		end
      endcase
    end
  
  assign MOSI = shft_reg[15];

endmodule 
