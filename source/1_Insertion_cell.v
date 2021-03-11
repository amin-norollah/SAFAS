//                ___   _   ___ _   ___ 
//               / __| /_\ | __/_\ / __|
//               \__ \/ _ \| _/ _ \\__ \
//               |___/_/ \_|_/_/ \_|___/                        
//
// Author:          Amin Norollah (a.norollah.official@gmail.com)
// Modified Date:   ‎‎October ‎16, ‎2020, 10:30:12 PM
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
module Insertion_cell #(parameter W=41)(
   input clk, rst,
   input subtract,
   input wr,
   input rd,
   input[W-2:0] data_in,
   input[W-1:0] data_in_pre, // data from previous cell

   output reg[W-1:0] data_reg,
   output reg[W-2:0] data_out, // replacement with oldest data_reg or send data_in.
   output reg wr_pre
    );
wire[W-1:0] data_reg_sub;
wire comp = (data_reg[31:16] <= data_in[31:16]);
                             
///////////////////////////////////////////////
// SUBTRACTOR
///////////////////////////////////////////////
sub_task #(.W(W)) subtractor(
    .clk  (clk),
    .rst  (rst),
    .subtract_en(subtract),
    .RT_in (data_reg),
   
    .RT_out(data_reg_sub)
);
   
///////////////////////////////////////////////
// Cell
///////////////////////////////////////////////
always @(posedge clk or posedge rst) begin
   if(rst) begin
      data_reg    <= {1'b0, {W-1{1'b1}}};
      data_out    <= {W-1{1'b1}};
      wr_pre      <= 1'b0;
   end else begin
      if (subtract)begin
           data_reg <= data_reg_sub; // subtract
      end else begin
   ///////////////////////////////////////////
   // write and read data from insertion sort          
          case ({wr, rd})
            //normal
            2'b00 : data_reg   <= data_reg;
            //read
            2'b01 : data_reg   <= data_in_pre;
            //write
            2'b10 : data_reg   <=(comp & data_reg[W-1]) ? data_reg : {1'b1, data_in};
            //read_write
            2'b11 : data_reg   <= data_in_pre;
            endcase 
        end
        // outputs
        wr_pre     <= (~rd)? (wr & data_reg[W-1]) : wr_pre;
        data_out   <= (~rd & wr)? ((comp & data_reg[W-1])? data_in : data_reg[W-2:0])
                                  : data_out;
   ///////////////////////////////////////////
   end
end
endmodule
