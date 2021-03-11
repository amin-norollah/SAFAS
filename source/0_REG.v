//                ___   _   ___ _   ___ 
//               / __| /_\ | __/_\ / __|
//               \__ \/ _ \| _/ _ \\__ \
//               |___/_/ \_|_/_/ \_|___/                        
//
// Author:          Amin Norollah (a.norollah.official@gmail.com)
// Modified Date:   ‎‎September ‎26, ‎2020, 03:58:51 PM
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
module REG #( parameter NUM = 16)(
		//INPUT
		input clk, rst,
		input [NUM-1 :0] IN,
		
		//OUTPUT
		output reg [NUM-1 :0] OUT
	);
	
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			OUT <= 0;
		end else begin
			OUT <= IN;
		end
	end

endmodule
