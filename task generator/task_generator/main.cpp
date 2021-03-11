//                ___   _   ___ _   ___ 
//               / __| /_\ | __/_\ / __|
//               \__ \/ _ \| _/ _ \\__ \
//               |___/_/ \_|_/_/ \_|___/                        
//
// Author:          Amin Norollah (a.norollah.official@gmail.com)
// Modified Date:   ‎January ‎17, ‎2021, 05:16:33 PM
// Project Name:    SAFAS (Secure and Fast Hardware Scheduler)
// Tool versions:   Visual studio 2017   
//
// Licence:         These project have been published for academic use only under GPLv3 License.
//                  Copyright  2021
//                  All Rights Reserved
//
// 010100101000000100011010000001010011 

///////////////////////////////////////////////
// task  detailed
// bit   description
//---------------------------------------------
// [1]   VALID                      [41]
//  + ADD NEW PROPERTEIS HERE
// [1]   Type                       [40]
// [8]   ID                         [39:32]
// [16]  Relative_deadline (time)   [31:16]
// [16]  Execution         (time)   [15:0]
///////////////////////////////////////////////

#include <iostream>
#include <random>
#include <string>
// for windows
#include <direct.h>
#include<conio.h>
//
#include <bitset>
using namespace std;

class task
{
public:
	bool feasible;
	int id;
	int di;
	int ei;
	float u;
	bool se;
};

int lcm(int a, int b){
	int m, n;

	m = a;
	n = b;

	while (m != n)
	{
		if (m < n) m = m + a;
		else n = n + b;
	}
	return m;
}

int main()
{
	///////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////
	//  task generate
	///////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////
	bool security_en = 1;
	bool verbose = 0;

	const int Num_cores = 16;
	float utilization = Num_cores-1.5;//64;
	//rand(); rand();
	int Num_sec_tasks = 15;  //max:20
	float U_max = 0.3;  //0.3, 0.6, 0.9
	float margin = 0.025; //// 0.3 = 0.025 //// 0.6 = 0.04 //// 0.9 = 0.06

	int Num_replicas = ceil(3 * (1 - U_max)) + 1;
	float U_critical = Num_cores*(1 - U_max) + U_max;
	float U_tmp = 0;

	float wait_delay = 0.5; //(ms)
	int num[] = {
			    0, 0, 0, 6, 5, 6, 6, 4, 0, 5,
				4, 2, 0, 2, 1, 2, 0, 2,	1, 2,
				0, 0, 4, 2, 0, 1, 0, 1,	0, 0,
				0, 1, 1, 0, 3, 0, 1, 3,	0, 1,
				1, 0, 1, 0, 1, 2, 2, 3, 1, 2};
	int o = 0;
	float temp_util = 0;

	const int NUM_TASK = 79;
	task tasks[NUM_TASK];
	float tmp_u;

	float divide_u = utilization / 2;
	for (int i = 0; i < 10; i++) {
		while (num[i] > 0) {
			tasks[o].id = o;
			tasks[o].di = (int)(i / wait_delay); //original

			temp_util = (static_cast <float> (rand()) / static_cast <float> (RAND_MAX));
			if (temp_util > 0.5) temp_util = temp_util* U_max;

			tmp_u = (float)((int)ceil((temp_util*i) / wait_delay)) / (float)(tasks[o].di);

			if (divide_u - tmp_u - ((NUM_TASK - o)*margin) >= 0)
				tasks[o].ei = (int)ceil((temp_util*i) / wait_delay);
			else
				tasks[o].ei = (int)ceil((margin*i) / wait_delay);

			tasks[o].u = (float)(tasks[o].ei) / (float)(tasks[o].di);
			divide_u = divide_u - tasks[o].u;

			if (Num_sec_tasks > 0 & (rand() % 4 == 1)) {
				tasks[o].se = true;
				Num_sec_tasks--;
			}
			else	tasks[o].se = false;

			tasks[o].feasible = false;

			num[i]--;
			o++;
		}
	}
	divide_u = (utilization)/2 + divide_u;
	for (int i = 50; i >= 10; i--) {
		while (num[i] > 0) {
			tasks[o].id = o;
			tasks[o].di = (int)(i / wait_delay); //original

			temp_util = (static_cast <float> (rand()) / static_cast <float> (RAND_MAX));
			if (temp_util > 0.5) temp_util = temp_util* U_max;

			tmp_u = (float)((int)ceil((temp_util*i) / wait_delay)) / (float)(tasks[o].di);

			if (divide_u - tmp_u - ((NUM_TASK - o)*margin) >= 0)
				tasks[o].ei = (int)ceil((temp_util*i) / wait_delay);
			else
				tasks[o].ei = (int)ceil((0.02*i) / wait_delay);

			tasks[o].u = (float)(tasks[o].ei) / (float)(tasks[o].di);
			divide_u = divide_u - tasks[o].u;

			if (Num_sec_tasks > 0 & (rand() % 4 == 1)) {
				tasks[o].se = true;
				Num_sec_tasks--;
			}
			else	tasks[o].se = false;

			tasks[o].feasible = false;

			num[i]--;
			o++;
		}
	}

	///////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////
	//  scheduling analysis
	///////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////
	int non_feasible_critical = 0;
	int non_feasible_normal = 0;

	//EDF_feasible
	//critical
	for (int i = 0; i < NUM_TASK; i++) {
		if (tasks[i].se) {
			if (U_critical >= (Num_replicas * tasks[i].u)) { //4 replicas of each critical tasks
				U_critical -= (Num_replicas * tasks[i].u);
				tasks[i].feasible = true;
				U_tmp += Num_replicas * tasks[i].u;
			}
			else non_feasible_critical++;
		}
	}
	//non critical
	for (int i = 0; i < NUM_TASK; i++) {
		if (tasks[i].se==false) {
			if (Num_cores - U_tmp >= tasks[i].u) {
				U_tmp += tasks[i].u;
				tasks[i].feasible = true;
			}
			else non_feasible_normal++;
		}
		if (verbose)
			cout << "i:" << i << " feasible:" << tasks[i].feasible << " Se:" << tasks[i].se << "\t id:" << tasks[i].id << " di:" << tasks[i].di << " ei:" << tasks[i].ei << "\t U:" << tasks[i].u << endl << endl;
	}
	if (verbose) {
		cout << "U_total:" << U_tmp << endl;
		cout << "non_feasiblity in critical tasks: " << non_feasible_critical << endl << "non_feasiblity in non critical tasks: " << non_feasible_normal << endl;
		cout << "\nPress any key to continue ..." << endl << endl;
		_getch();
	}

	///////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////
	//  task processing - output produce for verilog code
	///////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////
	int time = 1000;
	int end_time = 1400;
	long x = 0;
	string security = "";

	while (time <= end_time) {
		for (int i = 0; i < NUM_TASK; i++) {
			if (time % tasks[i].di == 0 & tasks[i].feasible) {
				//binary
				if (security_en) {
					if (tasks[i].se)
						security = "1";
					else security = "0";
				} else security = "";

				if (tasks[i].se) {
					for (int u = 0; u < Num_replicas; u++) {
						cout << "1"
							<< security
							<< bitset<8>(tasks[i].id).to_string()
							<< bitset<16>(tasks[i].di).to_string()
							<< bitset<16>(tasks[i].ei).to_string() << endl;
						x++;
					}
				}
				else {
					cout << "1"
						<< security
						<< bitset<8>(tasks[i].id).to_string()
						<< bitset<16>(tasks[i].di).to_string()
						<< bitset<16>(tasks[i].ei).to_string() << endl;
					x++;
				}
			}
		}
		time++;
		cout << "0" << endl;//<< bitset<41>(0).to_string() << endl; //divider between each two iteration
	}
	cout << "Total tasks released: " << x << endl;
	cout << "non_feasiblity in critical tasks: " << non_feasible_critical << endl << "non_feasiblity in non critical tasks: " << non_feasible_normal << endl;


	cout << "Total Utilization: " << U_tmp << endl;
	cout << "====================================" << endl;
	cout << "Press any key ..." << endl;
	_getch();
	return 0;
}