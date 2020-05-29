module UART (clk, rst_n, trmt, tx_data, clr_rdy, tx_done, rdy, rx_data);

  input logic clk, rst_n;     //Clock and synch low reset signal
  input logic trmt;           //Input to transmitter unit
  input logic clr_rdy;        //Input to UART receiver unit
  input logic [7:0] tx_data;  //8 bit input coming into the transmitter unit
  output logic tx_done;       //Output from the trasnmitter unit
  output logic rdy;           //Output from UART receiver unit
  output logic [7:0] rx_data; //Output from the UART receiver unit 
  logic a;                   //Wire that connects the Transmitter output to the receiver input

   ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   ///////Instantiating an instance of the receiver and the transmitter and connect them together to make a UART unit////////
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   
   UART_tx1 iDUT (.TX(a), .tx_done(tx_done), .tx_data(tx_data), .trmt(trmt), .clk(clk), .rst_n(rst_n));

   UART_rx iDUTrx (.clk(clk), .rst_n(rst_n), .RX(a), .clr_rdy(clr_rdy), .rx_data(rx_data), .rdy(rdy));


endmodule
