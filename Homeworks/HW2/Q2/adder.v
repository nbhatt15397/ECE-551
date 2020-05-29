module adder (A, B, cin, Sum, co);

//Defining inputs and ouputs
input [3:0] A;
input [3:0] B;
input cin;
output [3:0] Sum;
output co;

 /*Adding two 4 bit numbers with cin will result
 in a 5 bit result, So we concatenate co and Sum to
form a 5 bit destination for the addition, and 
we will capture the higher order bit as co */

assign {co, Sum} = A + B + cin ;

endmodule