//                ___   _   ___ _   ___ 
//               / __| /_\ | __/_\ / __|
//               \__ \/ _ \| _/ _ \\__ \
//               |___/_/ \_|_/_/ \_|___/                        
//
// Author:          Amin Norollah (a.norollah.official@gmail.com)
// Modified Date:   January ‎01, ‎2021, 09:32:57 AM
// Project Name:    SAFAS (Secure and Fast Hardware Scheduler)
// Target Device:   Virtex Family FPGA
// Tool versions:   Vivado 2018.2   
//
// Licence:         These project have been published for academic use only under GPLv3 License.
//                  Copyright  2021
//                  All Rights Reserved
//
// 010100101000000100011010000001010011 

`timescale 1ns / 1ps

module TB_Insertion_block #(parameter W = 42);

	// Inputs
	reg clk;
	reg rst;
	reg wr, rd;
	reg [(W-1)-1:0] data_in;
	reg sub;
	reg repair_period;

	// Outputs
	wire [(W-1)-1:0] data_out;
	wire data_valid;
	wire [(W-1)-1:0] data_fail;
	wire fail;

	// Instantiate the Unit Under Test (UUT)
	Insertion_block #(.W((W)), .N(4)) Insertion_block (
		.clk(clk), 
		.rst(rst), 
		.subtract  (sub),
		.wr(wr),
		.rd(rd),
		.data_in(data_in),
		.repair_period(repair_period),
		
		.data_out(data_out),
		.empty(data_valid),
		
		.data_fail(data_fail), 
		.fail(fail)
	);
	
	initial begin
		clk = 1;
		forever #1 clk = ~clk;
	end

	initial begin
		// Initialize Inputs
		wr = 0;
		data_in = 0;
		rd = 0;
		sub = 0;
		repair_period =0;
		rst = 1;
		@(posedge clk)
		rst = 0;

		////// tasks
		forever begin
			wr = 1;
            data_in = {8'h01, 16'h0006, 16'h0004, 1'b0};
		    @(posedge clk)
            data_in = {8'h02, 16'h0007, 16'h0004, 1'b0}; 
            @(posedge clk)
            data_in = {8'h03, 16'h0008, 16'h0004, 1'b0};
            @(posedge clk)
            data_in = {8'h04, 16'h0009, 16'h0004, 1'b0};
            @(posedge clk)
            data_in = {8'h05, 16'h0006, 16'h0004, 1'b0};
            @(posedge clk)
            data_in = {8'h06, 16'h0005, 16'h0004, 1'b0};
            @(posedge clk)
            data_in = {8'h07, 16'h0004, 16'h0004, 1'b0}; 
            @(posedge clk)
            data_in = {8'h08, 16'h0004, 16'h0004, 1'b0}; 
            @(posedge clk)
            wr = 0;
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            sub = 1;
		    @(posedge clk)
            sub = 0;
            repair_period = 1;
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            repair_period = 0;
            rd = 1;
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            rd=0;
		end
	end
/*	initial begin
	   	forever begin
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            @(posedge clk)
            rd = ~wr;
            @(posedge clk)
            rd = 0;
        end
	end*/
      
endmodule

