//                ___   _   ___ _   ___ 
//               / __| /_\ | __/_\ / __|
//               \__ \/ _ \| _/ _ \\__ \
//               |___/_/ \_|_/_/ \_|___/                        
//
// Author:          Amin Norollah (a.norollah.official@gmail.com)
// Modified Date:   ‎December ‎14, ‎2020, 11:48:52 AM
// Project Name:    SAFAS (Secure and Fast Hardware Scheduler)
// Target Device:   Virtex Family FPGA
// Tool versions:   Vivado 2018.2   
//
// Licence:         These project have been published for academic use only under GPLv3 License.
//                  Copyright  2021
//                  All Rights Reserved
//
// 010100101000000100011010000001010011 

///////////////////////////////////////////////
// task detailed
// bit   description
//---------------------------------------------
// [1]   VALID                      [40]
//  + ADD NEW PROPERTEIS HERE
// [8]   ID                         [39:32]
// [16]  Relative_deadline (time)   [31:16]
// [16]  Execution         (time)   [15:0]
///////////////////////////////////////////////
`timescale 1ns / 1ns
module Scheduler #(parameter W = 42, R_Q = 64, CORE = 16)(
   input clk, rst,
   input CTRL_action,
   input CTRL_subtract,
   input CTRL_RP,
   input wr,
   input [W-2:0] task_in,
   input [(W*CORE)-1:0] running_tasks_in, //the Wth bit indicates that task is running[1'b1] or has finished[1'b0] and it's not Valid bit!!!
   
   output v_exch,
   output[W-2:0] task_exch,
   output[(W*CORE)-1:0] running_tasks_out
  );  

  wire check_s1, check_s2;
  wire[CORE-1:0] s1_req;
  wire[3:0]      s1_index;
  wire           s1_valid;
  reg [3:0]      s2_index;

  reg [(W*CORE)-1:0] RT_reg;
  wire[W-2:0]task_out;
  wire empty;
  wire rd_task_Q = (check_s1|check_s2)& ~check_critical;
  wire rd_critical_Q = (check_s1|check_s2)& check_critical;
  
  wire check_critical;
  wire empty_critical;
  wire [W-2:0]task_critical_out;

  reg wr_preempt;
  reg [W-2:0] task_preempt;

/*********** Convert signals ************/ 
  wire[W-1:0] RT_before_S [CORE-1:0]; // Running tasks befor scheduling
  wire[W-1:0] RT_after_S  [CORE-1:0]; // Running tasks after scheduling
   
  genvar o;
  generate 
   for (o=0; o<CORE; o=o+1) begin : convert_signals
      assign RT_before_S[o][W-1:0]   = RT_reg[W*o+(W-1):W*o];          //unpacked
      assign running_tasks_out[W*o+(W-1):W*o] = RT_after_S[o][W-1:0];  //packed
   end
  endgenerate

/************* Ready Queue **************/ 
Insertion_block #(.W(W), .N(R_Q)) Ready_Q(
   //INPUT
   .clk       (clk), //PI
   .rst       (rst), //PI
   .subtract  (CTRL_subtract), //PI
   .wr        ((wr_preempt & ~task_preempt[40])|(wr & ~rd_task_Q & ~task_in[40])),
   .rd        (rd_task_Q),
   .data_in   ((wr_preempt)? task_preempt:task_in),
   .repair_period(CTRL_RP), //PI

   //OUTPUT
   .data_out  (task_out),
   .empty     (empty),
   
   .data_fail (task_exch), //PO
   .fail      (v_exch)     //PO
    );

/************ Critical queue *************/ 
Insertion_block #(.W(W), .N(64)) Critical_Q(
   //INPUT
   .clk       (clk), //PI
   .rst       (rst), //PI
   .subtract  (CTRL_subtract), //PI
   .wr        ((wr_preempt & task_preempt[40])|(wr & ~rd_critical_Q & task_in[40])),
   .rd        (rd_critical_Q),
   .data_in   ((wr_preempt)? task_preempt:task_in),
   .repair_period(CTRL_RP), //PI

   //OUTPUT
   .data_out  (task_critical_out),
   .empty     (empty_critical),
   
   .data_fail (), //PO
   .fail      ()  //PO
    );
	
/************ Running Queue *************/ 
   always @(posedge clk or posedge rst)
        if(rst)
            RT_reg <= 0;
        else begin if(CTRL_subtract)
            RT_reg <= running_tasks_in;
        else RT_reg <= running_tasks_out;
   end

/************* Situation 1 **************/ 
// there is a request for a new task from the processors.
// relative deadline of each tasks is zero, means that processor is ready to get a new task and has request!
   assign    check_s1 = s1_valid & (~empty | ~empty_critical) & CTRL_action;

   genvar t;
   generate 
        for (t=0; t<CORE; t=t+1) begin : req_generate
            assign s1_req[t] = ~RT_before_S[t][W-1];
        end
   endgenerate

   Arbiter_tree Arbiter_S1(
       .clk      (clk),//PI
       .rst      (rst),//PI
       .req      (s1_req),
                  
       .grant_index (s1_index),
       .valid       (s1_valid) //if the first situation happens, then there is no need to check the second situation.
   );

/************* Situation 2 **************/ 
   assign check_critical =(~empty_critical)?((~empty)? (task_critical_out[31:16]-task_critical_out[15:0])<=task_out[31:16] : 1'b1) : 1'b0;
   wire [15:0] tmp_s2    =(check_critical)? (task_critical_out[31:16]-task_critical_out[15:0]) : task_out[31:16];
   wire find_s2          =((RT_before_S[s2_index][40])?
                             tmp_s2 <(RT_before_S[s2_index][31:16]-RT_before_S[s2_index][15:0])
                            :tmp_s2 < RT_before_S[s2_index][31:16]) & (~empty | ~empty_critical) & CTRL_action;
   assign check_s2       = find_s2 & ~s1_valid & ~wr_preempt;  //RELATIVE_DEADLINE
	
   always @(posedge clk or posedge rst)
       if(rst) begin
            s2_index     <= 0;
            task_preempt <= 0;
            wr_preempt   <= 0;
   end else begin
        // increase the index value to check the next processor in the next cycle
        if(~find_s2)
            s2_index <= s2_index+1;

        // write the preempted task to Ready task Q
        if(check_s2) begin
            task_preempt <= RT_before_S[s2_index][W-2:0];
            wr_preempt   <= 1;
        end else wr_preempt   <= 0;

        // check for fault
        if(rd_task_Q & wr_preempt)
            $finish;
   end
   
/************** Scheduling ***************/ 
   genvar a;
   generate 
        for (a=0; a<CORE; a=a+1) begin : scheduling	
		    assign RT_after_S[a] = (((s2_index == a & check_s2) || (s1_index == a & check_s1)))?
                                     ((check_critical)? {1'b1, task_critical_out}:{1'b1, task_out})
									 :
									 RT_before_S[a]; //CPU with index 'a' 
		end
   endgenerate

/********** statistical data ************/ 
   integer RP_RECEIVED  = 0;
   integer RP_Exchanged = 0;
   integer RP_preempted = 0;
   integer RP_Run       = 0;

   always @(posedge clk) begin
        if(wr & ~rd_task_Q) RP_RECEIVED = RP_RECEIVED+1;
        if(v_exch) RP_Exchanged= RP_Exchanged+1;
        if(check_s2 & CTRL_action & (~empty|~empty_critical)) RP_preempted = RP_preempted+1;
        if(check_s1 & CTRL_action & (~empty|~empty_critical)) RP_Run = RP_Run+1;
   end

endmodule
