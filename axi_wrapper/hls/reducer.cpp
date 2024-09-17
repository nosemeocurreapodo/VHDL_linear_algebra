/*
 * Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
 * Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "reducer.h"

void square_sum_mean_std(hls::stream<packet> &data_in, data_type &square_sum, data_type &mean, data_type &std, data_type &entropy)
{
//#pragma HLS INLINE off
	data_type old_mean = 0.0;
	data_type old_std = 0.0;
	int n = 0;
	packet p;

ssms_loop:
	while (true)
	{
#pragma HLS LOOP_TRIPCOUNT max=512 avg=512 min=512
//#pragma HLS PIPELINE off

		data_in.read(p);
		data_type data = p.data;
		n++;
		if (n == 1)
		{
			mean = data;
			old_mean = data;
			std = 0.0;
			old_std = 0.0;
		}
		else
		{
			mean = old_mean + (data - old_mean) / n;
			std = old_std + (data - old_mean) * (data - mean);

			old_mean = mean;
			old_std = old_mean;
		}
		data_type square = data * data;
		square_sum += square;
		entropy += square * data_type(log(float(square)));

		if (p.last)
			break;
	}

	std /= (n - 1);
}

int reducer(hls::stream<packet> &approx_coeff,
			hls::stream<packet> &detail_1_coeff,
			hls::stream<packet> &detail_2_coeff,
			hls::stream<packet> &detail_3_coeff,
			hls::stream<packet> &detail_4_coeff,
			hls::stream<packet> &detail_5_coeff,
			float &cD_Energy, float &cA_Energy,
			float &D_Entropy, float &A_Entropy,
			float &D_mean, float &A_mean,
			float &D_std, float &A_std)
{
#pragma HLS INTERFACE axis port = approx_coeff
#pragma HLS INTERFACE axis port = detail_1_coeff
#pragma HLS INTERFACE axis port = detail_2_coeff
#pragma HLS INTERFACE axis port = detail_3_coeff
#pragma HLS INTERFACE axis port = detail_4_coeff
#pragma HLS INTERFACE axis port = detail_5_coeff
#pragma HLS INTERFACE s_axilite port = cD_Energy
#pragma HLS INTERFACE s_axilite port = cA_Energy
#pragma HLS INTERFACE s_axilite port = D_Entropy
#pragma HLS INTERFACE s_axilite port = A_Entropy
#pragma HLS INTERFACE s_axilite port = D_mean
#pragma HLS INTERFACE s_axilite port = A_mean
#pragma HLS INTERFACE s_axilite port = D_std
#pragma HLS INTERFACE s_axilite port = A_std
#pragma HLS INTERFACE s_axilite port = return

#pragma HLS ALLOCATION function instances=square_sum_mean_std limit=1

	data_type approx_square_sum = 0.0;
	data_type approx_mean = 0.0;
	data_type approx_std = 0.0;
	data_type approx_ent = 0.0;
	square_sum_mean_std(approx_coeff, approx_square_sum, approx_mean, approx_std, approx_ent);

	data_type detail_1_square_sum = 0.0;
	data_type detail_1_mean = 0.0;
	data_type detail_1_std = 0.0;
	data_type detail_1_ent = 0.0;
	square_sum_mean_std(detail_1_coeff, detail_1_square_sum, detail_1_mean, detail_1_std, detail_1_ent);

	data_type detail_2_square_sum = 0.0;
	data_type detail_2_mean = 0.0;
	data_type detail_2_std = 0.0;
	data_type detail_2_ent = 0.0;
	square_sum_mean_std(detail_2_coeff, detail_2_square_sum, detail_2_mean, detail_2_std, detail_2_ent);

	data_type detail_3_square_sum = 0.0;
	data_type detail_3_mean = 0.0;
	data_type detail_3_std = 0.0;
	data_type detail_3_ent = 0.0;
	square_sum_mean_std(detail_3_coeff, detail_3_square_sum, detail_3_mean, detail_3_std, detail_3_ent);

	data_type detail_4_square_sum = 0.0;
	data_type detail_4_mean = 0.0;
	data_type detail_4_std = 0.0;
	data_type detail_4_ent = 0.0;
	square_sum_mean_std(detail_4_coeff, detail_4_square_sum, detail_4_mean, detail_4_std, detail_4_ent);

	data_type detail_5_square_sum = 0.0;
	data_type detail_5_mean = 0.0;
	data_type detail_5_std = 0.0;
	data_type detail_5_ent = 0.0;
	square_sum_mean_std(detail_5_coeff, detail_5_square_sum, detail_5_mean, detail_5_std, detail_5_ent);

	data_type num_elements = 5.0;

	cD_Energy = (detail_1_square_sum + detail_2_square_sum + detail_3_square_sum + detail_4_square_sum + detail_5_square_sum) / num_elements;
	cA_Energy = approx_square_sum;
	D_Entropy = (detail_1_ent + detail_2_ent + detail_3_ent + detail_4_ent + detail_4_ent) / num_elements;
	A_Entropy = approx_ent;
	D_mean = (detail_1_mean + detail_2_mean + detail_3_mean + detail_4_mean + detail_5_mean) / num_elements;
	A_mean = approx_mean;
	D_std = (detail_1_std + detail_2_std + detail_3_std + detail_4_std + detail_5_std) / num_elements;
	A_std = approx_std;

	return 1;
}
