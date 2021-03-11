//                ___   _   ___ _   ___ 
//               / __| /_\ | __/_\ / __|
//               \__ \/ _ \| _/ _ \\__ \
//               |___/_/ \_|_/_/ \_|___/                        
//
// Author:          Amin Norollah (a.norollah.official@gmail.com)
// Modified Date:   ‎January ‎15, ‎2021, 09:32:31 PM
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
module Cores #(parameter W=42, N=64)(
     input clk, rst,
     input subtract_en,
     input [(W*N)-1:0] RT_in,
  
     output [(W*N)-1:0] RT_out
   );   
   
// convert_signals
wire [W-1:0] In [N-1:0];
reg  [W-1:0] Out [N-1:0];
reg  [N-1:0] check_miss;
integer RP_MISS;
integer RP_PASS;
integer RP_current_tasks;
integer o;

genvar i;
generate 
    for (i=0; i<N; i=i+1) begin
      //convert
      assign In[i][W-1:0]          = RT_in[W*i+(W-1):W*i]; //unpacked
      assign RT_out[W*i+(W-1):W*i] = Out[i][W-1:0];        //packed
        end
endgenerate
  
always @(posedge subtract_en, posedge rst) begin
    if(rst) begin
        RP_MISS = 0;
        RP_PASS = 0;
    end else begin
	  RP_current_tasks = 0;
     for(o=0; o<N; o=o+1) begin 
       //subtract
       if(In[o][W-1]) begin
            Out[o][15:0]  = In[o][15:0] - 1;  //subtracting execution time
            Out[o][31:16] = In[o][31:16] - 1; //subtracting relative deadline
            Out[o][39:32] = In[o][39:32];     //the ID of task
            check_miss[o] = Out[o][31:16] < Out[o][15:0]; //relative deadline < execution time
            Out[o][40]    =(check_miss[o] | Out[o][15:0] ==0)? 1'b0:In[o][40];
            Out[o][W-1]   =(check_miss[o] | Out[o][15:0] ==0)? 1'b0:1'b1; //valid bit

            RP_MISS = (check_miss[o])?    RP_MISS+1:RP_MISS;
            RP_PASS = (Out[o][15:0] ==0)? RP_PASS+1:RP_PASS;
            RP_current_tasks = RP_current_tasks +1;
         end else Out[o] = In[o];
     end
    end
end

endmodule

module sub_task #(parameter W=42)(
    input clk, rst,
    input subtract_en,
    input [(W)-1:0] RT_in,
  
    output reg[(W)-1:0] RT_out
   );
integer RP_MISS;
wire check_miss = (RT_in[31:16] < RT_in[15:0]); //relative deadline < execution time
   
always @(posedge subtract_en, posedge rst) begin
  if(rst) begin
    RP_MISS =0;
  end else if(RT_in[W-1]) begin
    RT_out[15:0]  = RT_in[15:0];
    RT_out[31:16] = (RT_in[31:16]!=0)? RT_in[31:16] - 1 : RT_in[31:16]; //deadline
    RP_MISS = (check_miss)? RP_MISS+1:RP_MISS;

    RT_out[40:32] = RT_in[40:32];       //other
    RT_out[W-1]   =(check_miss | RT_out[31:16]==0)? 1'b0:1'b1; 
  end else RT_out = RT_in;
end

endmodule
