module prot_trig(clk,rst_n,CH1L,CH2L,CH3L,TrigCfg,maskH,maskL,matchH,
                 matchL,baud_cntH,baud_cntL,protTrig);
				 
  input clk,rst_n;			// system clock and active low asynch reset
  input CH1L,CH2L,CH3L;		// the raw comparator channel inputs for low
  input [3:0] TrigCfg;		// lower 4-bits of TrigCfg
  input [7:0] maskL;		// a 1 implies a don't care in comparison against match
  input [7:0] maskH;		// a 1 implies a don't care in comparison against match
  input [7:0] matchH;		// high byte of match for SPI 16-bit
  input [7:0] matchL;		// low byte of match for SPI or UART
  input [7:0] baud_cntH;	// high byte of counter for setting baud rate
  input [7:0] baud_cntL;	// low byte of counter for setting baud rate
  output protTrig;			// A protocol trigger condition exists

  wire SPItrig_cnd,UARTtrig_cnd;	// SPI and UART trigger conditions
  wire SPItrig, UARTtrig;			// SPI and UART trigger
  wire len8,edg;					// assigned from TrigCfg bits

  
  assign len8 = TrigCfg[2];
  assign edg = TrigCfg[3];
  //// Instantiate SPI_RX ////
  SPI_RX iSPIprot(.clk(clk),.rst_n(rst_n),.SCLK(CH2L),.SS_n(CH1L),.MOSI(CH3L),
                  .edg(edg),.len8(len8),.mask({maskH,maskL}),
				  .match({matchH,matchL}),.SPItrig(SPItrig_cnd));

  //// Instantiate UART_RX ////
  UART_RX_prot iUARTprot(.clk(clk),.rst_n(rst_n),.RX(CH1L),.baud_cnt({baud_cntH,baud_cntL}),
                         .mask(maskL),.match(matchL),.UARTtrig(UARTtrig_cnd));
   
  assign SPItrig = SPItrig_cnd | TrigCfg[1];
  assign UARTtrig = UARTtrig_cnd | TrigCfg[0];
  
  assign protTrig = SPItrig & UARTtrig;
  
endmodule