//                ___   _   ___ _   ___ 
//               / __| /_\ | __/_\ / __|
//               \__ \/ _ \| _/ _ \\__ \
//               |___/_/ \_|_/_/ \_|___/                        
//
// Author:          Amin Norollah (a.norollah.official@gmail.com)
// Modified Date:   ‎January ‎30, ‎2021, 10:11:10 AM
// Project Name:    SAFAS (Secure and Fast Hardware Scheduler)
// Target Device:   Virtex Family FPGA
// Tool versions:   Vivado 2018.2
// Description:     a Security-aware real-time hardware scheduler architecture (Sec-Scheduler) 
//                  that schedule the tasks in the safe mode, considering real-time system constraints.
//                  This scheduler suitable for scheduling the high-security, safety critical and their
//                  replicas tasks to meet their deadline and can be safe from schedule-base attacks.
//
// Licence:         These project have been published for academic use only under GPLv3 License.
//                  Copyright  2021
//                  All Rights Reserved
//
// 010100101000000100011010000001010011 

`timescale 1ns / 1ns
module Scheduler_main #(parameter W = 42, R_Q = 64, CORE = 16)(
      //INPUT
      input clk, rst,
      input wr ,
      input[W-2:0] task_in,
      
      //OUTPUT
      output CTRL_RP,
      output CTRL_subtract,
      output CTRL_MQ_active, //output for testbench
      output v_exch    ,
      output[W-2:0] task_exch
    );
wire[(W*CORE)-1:0] RT_out, RT_cores;
wire CTRL_action;

   /*********** Cores ************/
   //this module is used just for simulations and it is not for synthesizing.
   Cores #(.W(W), .N(CORE)) Cores(
      .clk              (clk),
      .rst              (rst),
      .subtract_en      (CTRL_subtract),
      .RT_in            (RT_out),
   
      .RT_out           (RT_cores)
   );

   /********* Scheduler **********/
   Scheduler #(W, R_Q, CORE) Scheduler(
      .clk              (clk),
      .rst              (rst),
      .CTRL_subtract    (CTRL_subtract),
      .wr               (wr),
      .CTRL_action      (CTRL_action),
      .task_in          (task_in), 
      .running_tasks_in ((rst)? 0 : RT_cores), 
      .CTRL_RP          (CTRL_RP),

      .v_exch           (v_exch),
      .task_exch        (task_exch), 
      .running_tasks_out(RT_out)
   );
      
   /************ CTRL ************/
   Control #(R_Q) CTRL(
      .clk              (clk),
      .rst              (rst),

      .repair_period    (CTRL_RP),
      .action           (CTRL_action),
      .MQ_active        (CTRL_MQ_active),
      .subtract         (CTRL_subtract)
   );

endmodule
