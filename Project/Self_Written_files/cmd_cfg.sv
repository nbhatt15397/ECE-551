module cmd_cfg(clk,rst_n,resp,send_resp,resp_sent,cmd,cmd_rdy,clr_cmd_rdy,
               set_capture_done,raddr,rdataCH1,rdataCH2,rdataCH3,rdataCH4,
         rdataCH5,waddr,trig_pos,decimator,maskL,maskH,matchL,matchH,
         baud_cntL,baud_cntH,TrigCfg,CH1TrigCfg,CH2TrigCfg,CH3TrigCfg,
         CH4TrigCfg,CH5TrigCfg,VIH,VIL);
         
  parameter ENTRIES = 384,  // defaults to 384 for simulation, use 12288 for DE-0
            LOG2 = 9;   // Log base 2 of number of entries

  localparam pos_ack = 8'hA5;
  localparam neg_ack = 8'hEE;   

  input clk,rst_n;
  ///Inputs from UART
  input [15:0] cmd;        // 16-bit command from UART (host) to be executed
  input cmd_rdy;          // indicates command is valid
  input resp_sent;        // indicates transmission of resp[7:0] to host is complete
  input set_capture_done; // from the capture module (sets capture done bit in TrigCfg)
  //Input from capture control   
  input [LOG2-1:0] waddr;   // on a dump raddr is initialized to waddr
  input [7:0] rdataCH1;    // read data from RAMqueues
  input [7:0] rdataCH2,rdataCH3;
  input [7:0] rdataCH4,rdataCH5;  

  //Outputs to the UART unit 
  output reg [7:0] resp;       // data to send to host as resp (formed in SM)
  output reg send_resp;       // used to initiate transmission to host (via UART)
  output reg clr_cmd_rdy;     // when finished processing command use this to knock down cmd_rdy
  //Config Registers 
  output reg [LOG2-1:0] raddr;    // read address to RAMqueues (same address to all queues)
  output reg [LOG2-1:0] trig_pos; // how many sample after trigger to capture
  reg [LOG2-2 : 0] trig_posH;     //7:0 i.e 8 bits
  reg [LOG2-2 : 0] trig_posL;
  output reg [3:0] decimator; 		  // goes to clk_rst_smpl block
  output reg [7:0] maskL,maskH;       // to trigger logic for protocol triggering
  output reg [7:0] matchL,matchH;     // to trigger logic for protocol triggering
  output reg [7:0] baud_cntL,baud_cntH;   // to trigger logic for UART triggering
  output reg [5:0] TrigCfg;               // some bits to trigger logic, others to capture unit
  output reg [4:0] CH1TrigCfg,CH2TrigCfg; // to Channelnel trigger logic
  output reg [4:0] CH3TrigCfg,CH4TrigCfg; // to channel trigger logic
  output reg [4:0] CH5TrigCfg;           // to channel trigger logic
  output reg [7:0] VIH,VIL;             // to dual_PWM to set thresholds
  
  ////////Internally defined signals////////////
  logic [5:0] register_addr;       //Address of the register to be read from
  logic [7:0] data_to_write;  //Data to be written to the register
  logic [2:0] dump_chan_numb; //Channel number data is read from during dump
  logic [1:0] opcode;        //opcode determines operation performed
  logic write_reg; //FSM generated output that is asserted when a register needs to be written to
  logic [LOG2-1:0] first_RAM_addr; //Signal that stores the first value of the RAM address read when dump starts
  logic ld; 
  logic inc;
  logic RAM_read_done; //Signal that is asserted when the raddr pointer is the same as the first addr that was read from the RAM

  assign trig_pos = {trig_posH[LOG2-8:0], trig_posL};
  assign register_addr = cmd[13:8]; 
  assign data_to_write = cmd[7:0];
  assign dump_chan_numb = cmd[10:8];
  assign opcode = cmd[15:14];
  
  //FF that stores value of first address read from the RAM queue when dump starts
  always_ff @(posedge clk or negedge rst_n) begin 
    if(~rst_n)      first_RAM_addr <= 0;
    else if (ld)    first_RAM_addr <= waddr ;
  end

  //FF that increments RAM Addresses so the whole ram queue can be read using wrap around
  always_ff @(posedge clk or negedge rst_n) begin 
    if(~rst_n)        raddr <= 0 ;
    else if (ld)      raddr <= (waddr == ENTRIES -1) ? 0 : waddr + 1 ;
    else if (inc)     raddr <= (raddr == ENTRIES -1) ? 0 : raddr + 1 ;
  end

   ///////////////////////////////////////
  /////////////////FSM///////////////////
  ///////////////////////////////////////
  typedef enum reg[4:0] {IDLE, FIRST_DUMP, DUMPING, LAST_DUMP} state_t;
  state_t state, next_state;

  /////////////////FSM state ff//////////////////
  always_ff @ (posedge clk, negedge rst_n) begin
    if(!rst_n)
      state <= IDLE;
    else
      state <= next_state;
  end

always_comb begin
    ld = 0;   
    next_state = state;
    resp = 8'h00; 
    write_reg = 0; 
    send_resp = 0;    
    clr_cmd_rdy = 0;  
    inc = 0;   
    case(state)
      IDLE : begin
        ld=1;
        if(cmd_rdy) begin
          case(opcode)

          ///////////Write register cmd////////////
           2'b01: begin 
              write_reg = 1;
              resp = 8'ha5; 
              send_resp = 1;
              clr_cmd_rdy =1;
            end 

            //////////Read register cmd////////
            2'b00: begin  
              case(register_addr)  
                6'h00: resp = {2'b00, TrigCfg};             
                6'h01: resp = {3'b000, CH1TrigCfg};
                6'h02: resp = {3'b000, CH2TrigCfg};
                6'h03: resp = {3'b000, CH3TrigCfg};
                6'h04: resp = {3'b000, CH4TrigCfg};
                6'h05: resp = {3'b000, CH5TrigCfg};   
                6'h06: resp = {4'b000, decimator};
                6'h07: resp = VIH;
                6'h08: resp = VIL;
                6'h09: resp = matchH;
                6'h0A: resp = matchL;
                6'h0B: resp = maskH;  
                6'h0C: resp = maskL;
                6'h0D: resp = baud_cntH;
                6'h0E: resp = baud_cntL;
                6'h0F: resp = trig_posH; 
                6'h10: resp = trig_posL;
                default: resp = 8'hEE;
              endcase
              send_resp = 1;
              clr_cmd_rdy = 1;
              
            end
            
            ////////////Dump Opcode////////////
            2'b10: begin 
              next_state = FIRST_DUMP;
              clr_cmd_rdy = 1;
            end
            default: begin 
              resp = 8'hee;
              send_resp = 1;
              clr_cmd_rdy = 1;
            end
          endcase 
        end 
      end 


      DUMPING: begin 
        if (!resp_sent) 
          next_state = DUMPING;
        else 
          next_state = FIRST_DUMP;
      end

      
      FIRST_DUMP: begin 
        case(dump_chan_numb) 
          3'b001: resp = rdataCH1;
          3'b010: resp = rdataCH2;
          3'b011: resp = rdataCH3;
          3'b100: resp = rdataCH4;
          3'b101: resp = rdataCH5; 
        endcase
        inc = 1;
        send_resp = 1;

        if(raddr == first_RAM_addr && resp_sent)  
            next_state = LAST_DUMP;
         
        else 
            next_state = DUMPING;        
      end

      LAST_DUMP: begin
        if(resp_sent) begin
          clr_cmd_rdy = 1;
          next_state = IDLE;
        end
      end 
      default: begin 
      	send_resp = 1;
        next_state = IDLE;
        resp = 8'hEE;
        clr_cmd_rdy = 1; 
      end
    endcase
  end

  ///////////////////////////////////////////////////////
  /////////////////TrigCfg register flop/////////////////
  ///////////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) 
       TrigCfg <= 6'h03;

    else if (write_reg && register_addr == 6'h00) 
       TrigCfg <= data_to_write[5:0];

    else if (set_capture_done)
       TrigCfg[5] <= 1'b1 ;  
  end

  ///////////////////////////////////////////////////////
  ////////////////CH1TrigCfg register flop///////////////
  ///////////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
       CH1TrigCfg <= 5'h01;
    end 

    else if (write_reg && register_addr == 6'h01) begin
      CH1TrigCfg <= data_to_write[4:0];
    end
    
  end

  ///////////////////////////////////////////////////////
  /////////////////CH2TrigCfg register flop//////////////
  ///////////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
       CH2TrigCfg <=5'h01;
    end 

    else if (write_reg && register_addr == 6'h02) begin
      CH2TrigCfg <= data_to_write[4:0] ;
    end
    
  end

  ///////////////////////////////////////////////////////
  /////////////////CH3TrigCfg register flop//////////////
  ///////////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
      CH3TrigCfg <= 5'h01;
    end 

    else if (write_reg && register_addr == 6'h03) begin
      CH3TrigCfg <= data_to_write[4:0];
    end
    
  end


  ///////////////////////////////////////////////////////
  /////////////////CH4TrigCfg register flop/////////////
  //////////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
       CH4TrigCfg <= 5'h01;
    end 

    else if (write_reg && register_addr == 6'h04) begin
      CH4TrigCfg <= data_to_write[4:0];
    end
    
  end

  //////////////////////////////////////////////////////
  ///////////////CH5TrigCfg register flop///////////////
  /////////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) 
       CH5TrigCfg <= 5'h01;
     

    else if (write_reg && register_addr == 6'h05) 
      CH5TrigCfg <= data_to_write[4:0] ;
  end
    
    
  
  ///////////////////////////////////////////////////////
  /////////////////decimator register flop///////////////
  ///////////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) 
       decimator <= 4'h0;

    else if (write_reg && register_addr == 6'h06) 
      decimator <= data_to_write[3:0];

    end
    

  ///////////////////////////////////////////////////
  /////////////////VIH register flop/////////////////
  ///////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
       VIH <= 8'hAA;
    end 

    else if (write_reg && register_addr == 6'h07) begin
       VIH <= data_to_write[7:0] ;
    end
    
  end


  ///////////////////////////////////////////////////
  /////////////////VIL register flop/////////////////
  //////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
      VIL <= 8'h55;
    end 

    else if (write_reg && register_addr == 6'h08) begin
      VIL <= data_to_write[7:0];
    end
    
  end


  ///////////////////////////////////////////////////
  ////////////////matchH register flop//////////////
  //////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
       matchH <= 8'h00;
    end 

    else if (write_reg && register_addr == 6'h09) begin
      matchH <= data_to_write[7:0];
    end
    
  end


  ///////////////////////////////////////////////////
  ////////////////matchL register flop//////////////
  //////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
       matchL <= 8'h00;
    end 

    else if (write_reg && register_addr == 6'h0A) begin
      matchL <= data_to_write[7:0];
    end
    
  end

  ////////////////////////////////////////////////
  ///////////////maskH register flop//////////////
  ////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
       maskH <= 8'h00;
    end 

    else if (write_reg && register_addr == 6'h0B) begin
      maskH <= data_to_write[7:0];
    end
    
  end

  /////////////////////////////////////////////////
  ///////////////maskL register flop//////////////
  ////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
       maskL <= 8'h00;
    end 

    else if (write_reg && register_addr == 6'h0C) begin
      maskL <= data_to_write[7:0];
    end
    
  end

  /////////////////////////////////////////////////
  //////////////baud_cntH register flop////////////
  ////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
       baud_cntH <= 8'h06;
    end 

    else if (write_reg && register_addr == 6'h0D) begin
      baud_cntH <= data_to_write[7:0];
    end
    
  end

  /////////////////////////////////////////////////
  //////////////baud_cntL register flop////////////
  ////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
       baud_cntL <= 8'hC8;
    end 

    else if (write_reg && register_addr == 6'h0E) begin
       baud_cntL <= data_to_write[7:0];
    end
    
  end

  /////////////////////////////////////////////////
  //////////////trig_posH register flop////////////
  ////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
       trig_posH <= 8'h00;
    end 

    else if (write_reg && register_addr == 6'h0F) begin
       trig_posH <= data_to_write[7:0];
    end
    
  end


  ////////////////////////////////////////////////
  //////////////trig_posL register flop////////////
  ////////////////////////////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
       trig_posL <= 8'h01;
    end 

    else if (write_reg && register_addr == 6'h10) begin
       trig_posL <= data_to_write[7:0];
    end
  end 

endmodule