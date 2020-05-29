 module adder_tb ();

 reg [4:0] A,B;     //stimulus to A and B sized to prevent loop wrap around
 reg [1:0] cin ;          //carry input stim
 reg [4:0] true_output;


//DUT outputs of drive type wire
 wire [3:0] Sum;
 wire co;

/////////////////////////////////////////
////////////Instantiate DUT /////////////
/////////////////////////////////////////
 adder iDUT (.A(A[3:0]), .B(B[3:0]), .cin(cin[0]), .Sum(Sum[3:0]), .co(co));

 //Monitors and prints signals every time they change their values
  initial $monitor ("A: %h, B: %h, C_in: %b, C_out: %b, Sum: %h", A[3:0], B[3:0], cin, co, Sum[3:0]);

//Exhaustively testing all possible A, B and cin combinations 
  initial begin
     #5;
    for (A = 0 ; A < 5'h10 ; A = A + 1) begin 
           #5; 
        for (B = 0 ; B < 5'h10  ; B = B + 1) begin 
                #5;
           for (cin = 0 ; cin < 2 ; cin = cin + 1) begin

               #5;

                true_output = A + B + cin;  // locally calculating addition result

                 //Verify if true_output matches Sum from Adder
                 if(true_output[3:0] != Sum) begin
                 $display("Error, the sum is incorrect\n");
                  $stop();
                 end

                  //Verifies that the carry out from Adder module is same as the actual
                  if(true_output[4] != co) begin
                   $display("Error, the overflow value is incorrect\n");
                   $stop();
                   end       
            end
        end
    end 

$display ("YAHOO!! You've passed the test");
$stop () ;

  end
endmodule
