//                ___   _   ___ _   ___ 
//               / __| /_\ | __/_\ / __|
//               \__ \/ _ \| _/ _ \\__ \
//               |___/_/ \_|_/_/ \_|___/                        
//
// Author:          Amin Norollah (a.norollah.official@gmail.com)
// Modified Date:   ‎November ‎2, ‎2020, 11:45:25 PM
// Project Name:    SAFAS (Secure and Fast Hardware Scheduler)
// Target Device:   Virtex Family FPGA
// Tool versions:   Vivado 2018.2   
//
// Licence:         These project have been published for academic use only under GPLv3 License.
//                  Copyright  2021
//                  All Rights Reserved
//
// 010100101000000100011010000001010011 

//////////////////////////////
// arbiter_tree
//////////////////////////////
`timescale 1ns / 1ns
module Arbiter_tree (
input clk,
input rst,
input[15:0] req,

output[3:0] grant_index,
output valid
);
wire[7:0] grant_level_1, request_level_1;

wire[7:0] grant_level_2;
wire[3:0] request_level_2;

wire[5:0] grant_level_3;
wire[1:0] request_level_3;

   genvar i;
   generate
   for(i=0; i<8; i=i+1)
      begin: arbiter_LEVEL_1
      Arbiter_cell_1 AB1(
      .clk (clk),
      .rst (rst),
      .req (req[(2*i)+1:2*i]),
    
      .req_out   (request_level_1[i]),
      .grant_out (grant_level_1[i])
      );
      end
   endgenerate
   generate
   for(i=0; i<4; i=i+1)
      begin: arbiter_LEVEL_2
      Arbiter_cell #(2) AB2(
      .clk (clk),
      .rst (rst),
      .req (request_level_1[(2*i)+1:2*i]),
      .grant (grant_level_1[(2*i)+1:2*i]),
    
      .req_out   (request_level_2[i]),
      .grant_out (grant_level_2[(2*i)+1:2*i])
      );
      end
   endgenerate
   
   generate
   for(i=0; i<2; i=i+1)
      begin: arbiter_LEVEL_3
       Arbiter_cell #(3) AB3(
       .clk (clk),
       .rst (rst),
       .req (request_level_2[(2*i)+1:2*i]),
       .grant (grant_level_2[(4*i)+3:4*i]),
            
       .req_out   (request_level_3[i]),
       .grant_out (grant_level_3[(3*i)+2:3*i])
       );
      end
   endgenerate

   Arbiter_cell #(4) AB4(
   .clk (clk),
   .rst (rst),
   .req (request_level_3),
   .grant (grant_level_3),
               
   .req_out   (valid),
   .grant_out (grant_index)
   );
endmodule


/////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////
module Arbiter_cell #(parameter W = 4) (
  input clk,
  input rst,
  input[1:0]req,
  input[2*(W-1)-1:0] grant,

  output req_out,
  output[W-1:0] grant_out
);
wire [1:0]op1, op2;
reg priority_;

assign op1[0] = ~priority_| ~req[1];
assign op1[1] = priority_ | ~req[0];

assign op2[0] = req[0] & op1[0];
assign op2[1] = req[1] & op1[1];
assign req_out = op2[0] | op2[1];

assign grant_out[W-1] = op2[1];
assign grant_out[W-2:0] =(op2[1])? grant[2*(W-1)-1:W-1] : grant[W-2:0];

always @(posedge clk, posedge rst) begin
    if(rst)
      priority_ <= 0;
    else
      priority_ <=(req[0]|req[1])? !priority_ : priority_;
end
endmodule
/////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////
module Arbiter_cell_1 (
  input clk,
  input rst,
  input[1:0]req,

  output req_out,
  output grant_out
);
wire [1:0]op1, op2;
reg priority_;

assign op1[0] = ~priority_| ~req[1];
assign op1[1] = priority_ | ~req[0];

assign op2[0] = req[0] & op1[0];
assign op2[1] = req[1] & op1[1];
assign req_out = op2[0] | op2[1];

assign grant_out = op2[1];

always @(posedge clk, posedge rst) begin
    if(rst)
      priority_ <= 0;
    else
      priority_ <=(req[0]|req[1])? !priority_ : priority_;
end
endmodule
