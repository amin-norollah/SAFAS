//                ___   _   ___ _   ___ 
//               / __| /_\ | __/_\ / __|
//               \__ \/ _ \| _/ _ \\__ \
//               |___/_/ \_|_/_/ \_|___/                        
//
// Author:          Amin Norollah (a.norollah.official@gmail.com)
// Modified Date:   ‎December ‎21, ‎2020, 01:05:23 PM
// Project Name:    SAFAS (Secure and Fast Hardware Scheduler)
// Target Device:   Virtex Family FPGA
// Tool versions:   Vivado 2018.2   
//
// Licence:         These project have been published for academic use only under GPLv3 License.
//                  Copyright  2021
//                  All Rights Reserved
//
// 010100101000000100011010000001010011 

`timescale 1ns / 1ns
module Control #(parameter R_Q = 64)(
      //INPUT
      input clk,
      input rst,

      //OUTPUT
      output action,
      output repair_period,
      output reg MQ_active,
      output reg subtract
   );
   reg [15:0] delay;
   reg [2:0] state;
   reg [5:0] repair_time;
	
   localparam SCHEDULING = 16'b0000_0000_0100_0000; //64
   localparam IDLE       = 16'b0000_0001_0000_0000; //256 for test
	
   ////////////////////////////////////////////////////
   //  delay(cycles)      state       fun
   //-------------------------------------------------
   //   64                000         scheduling
   //
   //   R_Q               001         margin-time
   //
   //   1                 010         subtract
   //
   //   remain_cycles     011         idle and repair-time
   //
   //   R_Q               111         margin-time
   //
   // *   repair-time is used for detecting the missed tasks in the ready and main queues and remove them.
   // **  margin-time is used to seperate the scheduling period from IDLE interval.
	// *** remain cycles is equiled to 65536-(other state' cycles)
   ////////////////////////////////////////////////////
   
   assign action = (rst)? 1'b0 : ~|state;
   assign repair_period = (repair_time!=0);
   
   always @(posedge clk or posedge rst) begin
      if(rst) begin
         state <= 2;
         subtract <= 0;
         repair_time <= 0;
         MQ_active <= 1;
         delay <= IDLE;
      end else begin
         case(state)
            3'b000: //scheduling
                    if(delay==0)begin
                        delay <= R_Q;
                        state <= 3'b001;
                    end else begin
                        delay <= delay-1;
                    end
            3'b001: //wait for write all data to insertion cell
                    if(delay==0)begin
                        state <= 3'b010;
                        subtract <= 1;
                    end else delay <= delay-1;
            3'b010: //subtract
                    begin
                        delay <= IDLE;
                        state <= 3'b011;
                        repair_time <= R_Q/2;
                        subtract <= 0;
                        MQ_active <= 1;
                    end
            3'b011: //idle
                    if(delay==0)begin
                        delay <= R_Q;
                        state <= 3'b111;
                        MQ_active <= 0;
                    end else begin
                        delay <= delay-1;
                        if(repair_period) repair_time <= repair_time -1;
                    end
            3'b111: //wait for write all data to insertion cell
                    if(delay==0)begin
                        delay <= SCHEDULING;
                        state <= 3'b000;
                    end else   delay <= delay-1;
                        
         endcase
      end
   end
   
endmodule
