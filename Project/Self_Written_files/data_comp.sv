module data_comp(prot_trig, match, mask, serial_vld, serial_data);

  input logic [7:0] serial_data;  //Incoming data received from serial protocol
  input logic serial_vld;         //Incoming signal which reveals weather serial_data is valid or not
  input logic [7:0] mask;         //A set bit indicates the corresponding bit of match is to be treated as a don?t care
  input logic [7:0] match;        // Ultimate data the unit is trying to match the incoming data to to generate a trigger
  output logic prot_trig;         // Asserted when there is a data match

 	 // Using assign statements to model circuit behaviour
      assign prot_trig = (~serial_vld) ? 0             // If serial_vld is not valid, prot_trig = 0, else we check for data match and if true prot_trig =1, else 0 
                         : (( (serial_data | mask) == (match | mask) ) ? 1 : 0);  // if the two signals match, i.e. protocol data match, prot_trig = 1 (asserted)
  

endmodule

