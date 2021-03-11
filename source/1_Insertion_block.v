//                ___   _   ___ _   ___ 
//               / __| /_\ | __/_\ / __|
//               \__ \/ _ \| _/ _ \\__ \
//               |___/_/ \_|_/_/ \_|___/                        
//
// Author:          Amin Norollah (a.norollah.official@gmail.com)
// Modified Date:   ‎‎October ‎4, ‎2020, 07:19:27 PM
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
module Insertion_block #(parameter W=41, N=64)(
	input clk, rst,
	input subtract,
	input rd,
	input wr,
	input[W-2:0] data_in,
	input repair_period,
	
	output [W-2:0] data_out,
	output empty,
	
	output [W-2:0] data_fail,
	output fail
    );
	 
integer RP_rd =0;

wire[N:0] wr_;
wire rd_;

wire[W-1:0] data_reg [N:0];
wire[W-2:0] data_in_IB [N:0];

assign data_in_IB[0] = data_in;
assign data_reg[N]   = {1'b0, {W-1{1'b1}}};

assign wr_[0]        = wr;
assign rd_           = rd | (repair_period & ~data_reg[0][W-1]);

assign fail          = wr_[N];
assign data_fail     = data_in_IB[N];

assign data_out      = data_reg[0][W-2:0];
assign empty         = ~data_reg[0][W-1];

genvar o, i;
generate 
	for (o=0; o<N; o=o+1) begin : IB
		Insertion_cell #(.W(W)) Ins_cell(
		//inputs
			.clk          (clk), 
			.rst          (rst),
			.subtract     (subtract),
			.wr           (wr_[o]),
			.data_in      (data_in_IB[o]),
			.rd           (rd_),
			.data_in_pre  (data_reg[o+1]),

		//outputs
			.data_reg     (data_reg[o]),
			.data_out     (data_in_IB[o+1]),
			.wr_pre       (wr_[o+1])
		);
	end
endgenerate

endmodule
