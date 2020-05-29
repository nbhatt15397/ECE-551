
module capture(clk,rst_n,wrt_smpl,run,capture_done,triggered,trig_pos,
               we,waddr,set_capture_done,armed);

  parameter ENTRIES = 384,    // defaults to 384 for simulation, use 12288 for DE-0
            LOG2 = 9;     // Log base 2 of number of entries
  
  input clk;          // system clock.
  input rst_n;          // active low asynch reset
  input wrt_smpl;       // from clk_rst_smpl.  Lets us know valid sample ready
  input run;          // signal from cmd_cfg that indicates we are in run mode
  input capture_done;     // signal from cmd_cfg register.
  input triggered;        // from trigger unit...we are triggered
  input [LOG2-1:0] trig_pos;  // How many samples after trigger do we capture
  
  output logic we;          // write enable to RAMs
  output reg [LOG2-1:0] waddr;  // write addr to RAMs
  output reg set_capture_done;    // asserted to set bit in cmd_cfg, added ttype reg because defined in SM
  output reg armed;       // we have enough samples to accept a trigger

  logic set_armed;
  logic clr_armed;
  logic [LOG2-1:0] smpl_cnt;
  logic clr_smpl_cnt, inc_smpl_cnt, clr_trig_cnt, inc_trigcnt, clr_waddr, inc_waddr;
  logic [LOG2-1:0] trig_cnt;

  ////////////////armed ff//////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      armed <= 1'b0;
    else if (set_armed)
      armed <= 1'b1;
    else if (clr_armed)
      armed <= 1'b0;
    
   assign we = wrt_smpl & run & (~capture_done);

    //////////trig_cnt flip flop/////////////
   always_ff @(posedge clk or negedge rst_n) begin 
      if(~rst_n)
        trig_cnt <= 0;
       else if (clr_trig_cnt)
         trig_cnt <= 0;
      else if (inc_trigcnt)
         trig_cnt <= trig_cnt + 1 ;
   end//always_ff

  ///////////////// waddr flip flop //////////////////
   always_ff @(posedge clk or negedge rst_n) begin 
    if(~rst_n) 
       waddr <= 0;
    else if (clr_waddr)
        waddr <= 0;
    else if (inc_waddr) 
      waddr <=  (waddr == ENTRIES -1) ? 0 : waddr + 1;//Wrap around logic
    end

  //main FSM     
  typedef enum reg [2:0] {IDLE, RUN, LAST} state_t; 
  state_t state, nxt_state; 
   
  always_ff @ (posedge clk, negedge rst_n) begin 
    if(!rst_n) 
      state <= IDLE; 
    else 
      state <= nxt_state; 
  end 
  
  always_comb begin
  set_capture_done = 1'b0;
  clr_waddr = 0;
  //clr_smpl_cnt = 0;
  clr_armed = 0;
  set_armed = 0;
  inc_trigcnt = 0;
  inc_waddr =0;
  clr_trig_cnt = 0;
  nxt_state = state;


  case(state)
    IDLE:   if (run) begin
          //Clearing all flip flop values before we ook for wrt_smpl
          clr_smpl_cnt = 1;
          clr_trig_cnt = 1; 
          clr_waddr = 1;  
          nxt_state = RUN;
        end 

    RUN:   if (wrt_smpl) begin
              inc_waddr = 1;
          if ((waddr + trig_pos) == (ENTRIES - 1))
            set_armed = 1;
              if (triggered) begin
                  inc_trigcnt = 1;
                    if (trig_cnt == trig_pos) begin
                       nxt_state = LAST;
                       set_capture_done = 1;
                       clr_armed = 1;
                    end//trigcnt==trigpos

                else 
                  nxt_state = RUN;
              end//triggered
           end//wrt_smpl

    LAST: 
        if (!capture_done)
          nxt_state = IDLE;
  
  endcase//endcase state
  end 
endmodule