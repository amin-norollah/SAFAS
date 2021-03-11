//                ___   _   ___ _   ___ 
//               / __| /_\ | __/_\ / __|
//               \__ \/ _ \| _/ _ \\__ \
//               |___/_/ \_|_/_/ \_|___/                        
//
// Author:          Amin Norollah (a.norollah.official@gmail.com)
// Modified Date:   ‎January ‎1, ‎2021, 06:12:05 PM
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
// [1]   VALID                      [41]
//  + ADD NEW PROPERTEIS HERE
// [1]   Type                       [40]
// [8]   ID                         [39:32]
// [16]  Relative_deadline (time)   [31:16]
// [16]  Execution         (time)   [15:0]
///////////////////////////////////////////////
`timescale 1ns / 1ns
module TB_scheduler_main #(parameter W = 42, R_Q = 32, M_Q = 512);
   reg clk;
   reg rst;
   reg wr_MQ;  //write signal in Main Queue
   reg [W-1:0] MQ_task_in; //the task enter from the external test file to main queue
   
   wire [W-2:0] MQ_task_out; //the task that read from main queue and enter to main scheduler
   wire v_exch; //valid bit for authorizing the "task_exch" signal
   wire [W-2:0] task_exch; //when the ready queue in the scheduler is full, the task with bigger relative deadline have to send out and store to main queue
   wire CTRL_repair_period, CTRL_MQ_active, CTRL_subtract; //control signals from the control unit
   wire MQ_empty, MQ_fail; //empty and fail signal from the main queue. if fail is enabled, means the main queue is full and one task is thrown out;
   wire rd_after_wr;  //we can not read and write simultaneously, so this signal help us to avoid rd and wr signals active with together

   localparam Size = 3275;  //*********************//it depends on the number of the lines in the external test file
   reg[W-1:0] buffer [0:Size-1];  //buffering the tasks from the external test file.  total = W*Size (bits)
   
   integer RP_All_tasks=0; //the number of tasks, received from the external test file and stored in main queue
   integer RP_Iteration=0;
   integer RP_MISS_total=0;
   integer pointer=0;

   wire rd = (~(v_exch|wr_MQ|CTRL_repair_period|CTRL_subtract|MQ_empty) & CTRL_MQ_active & rd_after_wr);
   wire wr = wr_MQ | v_exch;
    
   /******* Main Scheduler Instance ********/
   Scheduler_main #(W, R_Q) Main_Scheduler (
      //INPUT
      .clk           (clk),
      .rst           (rst), 
      .wr            (rd), 
      .task_in       (MQ_task_out), 

      //OUTPUT
      .CTRL_RP       (CTRL_repair_period),
      .CTRL_subtract (CTRL_subtract),
      .CTRL_MQ_active(CTRL_MQ_active),
      .v_exch        (v_exch),
      .task_exch     (task_exch)
   );
   
   /********* Main Queue Instance **********/
   Insertion_block #(.W(W), .N(M_Q)) Main_Q(
      //INPUT
      .clk           (clk),
      .rst           (rst), 
      .subtract      (CTRL_subtract),
      .wr            (wr),
      .rd            (rd),
      .data_in       ((v_exch)? task_exch : MQ_task_in[W-2:0]),
      .repair_period (CTRL_repair_period),

      //OUTPUT
      .data_out      (MQ_task_out),
      .empty         (MQ_empty),
      .fail          (MQ_fail),
      .data_fail     ()
   );

   REG #(1) Rd_after_wr(
      //INPUT
      .clk           (clk),
      .rst           (rst), 
      .IN            (~rd),
        
      //OUTPUT
      .OUT           (rd_after_wr)
   );
////////////////////////////////////////
/////////                     //////////
///////// JUST FOR SIMULATION //////////
/////////                     //////////
////////////////////////////////////////
 initial begin
    $readmemb("C:/SAFAS/Experimental/TaskSet.txt", buffer); //absolute address of binary file
    clk = 1;
    forever #1 clk = ~clk;
 end   

 initial begin
    // Initialize Inputs
    //pointer = 0;
    //RP_All_tasks  = 0;
    MQ_task_in <= 0;
    rst <= 1;
    wr_MQ <=0;
    @(posedge clk)
    rst <= 0;
       
    // Read the external test file
    forever begin
        wr_MQ <=0;
        if(pointer <= Size) begin
                while (buffer[pointer]!=0) begin
                    if(!v_exch) begin
                        wr_MQ <=1'b1;
                        MQ_task_in <= buffer[pointer];
                        pointer = pointer+1;
                        RP_All_tasks = RP_All_tasks+1;
                    end
                    @(posedge clk)
                    wr_MQ <=0;
                end
        end else 
                if(Main_Scheduler.Cores.RP_current_tasks == 0)begin
                    //we let the system working until all new tasks that released in last interval, is done and system
                    //is going to IDLE mode, then the scheduling will be done and simulation will be finished.
                    $display("\nFinal data analysis:\nSYSTEM:\n   All tasks:%d,\n   Finished tasks:%d,\n   Missed tasks:%d",
                                RP_All_tasks, Main_Scheduler.Cores.RP_PASS,
                                Main_Scheduler.Cores.RP_MISS + RP_MISS_total);
                    $display("\nSCHEDULER:\n   Received tasks:%d,\n   Exchanged tasks:%d,\n   Preempted tasks:%d,\n   Running tasks:%d",
                              Main_Scheduler.Scheduler.RP_RECEIVED, Main_Scheduler.Scheduler.RP_Exchanged,
                              Main_Scheduler.Scheduler.RP_preempted, Main_Scheduler.Scheduler.RP_Run);
                    $display("\nTIMING:\n   Iterations:%d,\n   Clock cycles:%d,\n   Time: %f (ms)\n\n",
                              RP_Iteration, RP_Iteration*(2*R_Q+64+1+65536),
                              (RP_Iteration*65536*4.72)/1000000); //4.72 is clock period in ns and 65536 is total intervals of system
                    $finish;
				end
        pointer = pointer+1;
        wr_MQ <=0;
        @(negedge CTRL_repair_period) RP_Iteration = RP_Iteration+1;
    end
 end
   
////////////////////////////////////////
/////////                     //////////
/////////     Monitoring      //////////
/////////                     //////////
////////////////////////////////////////
   integer index;
   wire [6:0] report_miss_tmp1 [R_Q-1:0]; //Maximum number of miss tasks that can be reported from ready queue is 128 (icrease it for more)
   wire [6:0] report_miss_tmp2 [M_Q-1:0]; //Maximum number of miss tasks that can be reported from main queue is 128 (icrease it for more)
   wire [6:0] report_miss_tmp3 [16-1:0];
	
    genvar u;
    generate
        for (u=0; u<R_Q; u=u+1) begin :RP_MISS_R_Q
            assign report_miss_tmp1[u] = Main_Scheduler.Scheduler.Ready_Q.IB[u].Ins_cell.subtractor.RP_MISS;
        end
        for (u=0; u<M_Q; u=u+1) begin :RP_MISS_M_Q
            assign report_miss_tmp2[u] = Main_Q.IB[u].Ins_cell.subtractor.RP_MISS;
        end
		  for (u=0; u<16; u=u+1) begin :RP_MISS_C_Q
            assign report_miss_tmp3[u] = Main_Scheduler.Scheduler.Critical_Q.IB[u].Ins_cell.subtractor.RP_MISS;
        end
    endgenerate    
    
    always @(posedge CTRL_repair_period) begin
        RP_MISS_total = 0;
        for (index=0; index<R_Q; index=index+1)
            RP_MISS_total = RP_MISS_total + report_miss_tmp1[index];
        for (index=0; index<M_Q; index=index+1)
            RP_MISS_total = RP_MISS_total + report_miss_tmp2[index];
		  for (index=0; index<16; index=index+1)
            RP_MISS_total = RP_MISS_total + report_miss_tmp3[index];
    end
    
    initial begin
     $monitor("All tasks:%d, Finished tasks:%d, Missed tasks:%d",
                RP_All_tasks,
                Main_Scheduler.Cores.RP_PASS,
                Main_Scheduler.Cores.RP_MISS
                +RP_MISS_total);
    end
   
endmodule
