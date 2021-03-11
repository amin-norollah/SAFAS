//                ___   _   ___ _   ___ 
//               / __| /_\ | __/_\ / __|
//               \__ \/ _ \| _/ _ \\__ \
//               |___/_/ \_|_/_/ \_|___/                        
//
// Author:          Amin Norollah (a.norollah.official@gmail.com)
// Modified Date:   ‎‎January ‎2, ‎2021, 08:10:55 PM
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

module TB_scheduler_partial#(parameter W = 59);

	// Inputs
	reg clk;
	reg rst;
	reg wr;
	reg [W-2:0] task_in;
	reg [8*W-1:0] running_tasks_in;
	reg action, subtract_en;

	// Outputs
	wire [8*W-1:0] running_tasks;
	wire v_exch, busy_ready, v_active;
	wire [W-2:0] task_exch;

	// Instantiate the Unit Under Test (UUT)
	Scheduler_partial #(W) SP (
		.clk(clk), 
		.rst(rst), 
		.wr(wr),
		.subtract_en(subtract_en),
		.action(action),
		.task_in(task_in), 
		.running_tasks_in((rst)? 0 : running_tasks_in), 
		
		.v_exch(v_exch),
		.v_active(v_active),
		.busy_ready(busy_ready),
		.task_exch(task_exch), 
		.running_tasks_out(running_tasks)
	);
	
	initial begin
		clk = 1;
		forever #1 clk = ~clk;
	end
	
	initial forever #2 running_tasks_in <= (rst)? 0 : running_tasks;

	initial begin
		// Initialize Inputs
		action <= 1;
		subtract_en <= 0;
		wr <= 0;
		rst <= 1;
		#2
		rst <= 0;
		
		////// first task
		wr <= 1;
		task_in <= {W{$random}};
		
		////// remaining tasks
		forever begin
			#2 wr <= 0;
			@(negedge busy_ready)
			wr <= 1'b1;
			task_in <= (v_active)? task_in: {W{$random}};
		end
	end
	
endmodule

