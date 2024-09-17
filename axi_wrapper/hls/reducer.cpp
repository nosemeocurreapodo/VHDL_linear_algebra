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

#include "dwt_db4_hls.h"


void square_sum_mean_std(hls::stream<packet> &data_in, data_type &square_sum, data_type &mean, data_type &std)
{
	data_type old_mean;
	data_type old_std;
	int n = 0;

	while(true)
	{
		packet p;
		data_in.read(p);
		n ++;
		if(count == 1)
		{
			mean = p.data;
			old_mean = p.data;
			std = 0.0;
			old_std = 0.0;
		}
		else
		{
			mean = old_mean + (p.data - old_mean)/n;
			std = old_std + (p.data - old_mean) * (p.data - mean);

			old_mean = mean;
			old_std = old_mean;
		}
		square_sum += p.data*p.data;

		if(p.last)
			break;
	}

	std /= (n-1);
}

    cD_Energy_pynq[i,j] = np.mean([np.sum(np.square(coeffs[5])),np.sum(np.square(coeffs[4])),
                         np.sum(np.square(coeffs[3])),np.sum(np.square(coeffs[2])),
                         np.sum(np.square(coeffs[1]))])
    cA_Energy_pynq[i,j] = np.sum(np.square(coeffs[0]))
    D_Entropy_pynq[i,j] = np.mean([np.sum(np.square(coeffs[5]) * np.log(np.square(coeffs[5]))),
                         np.sum(np.square(coeffs[4]) * np.log(np.square(coeffs[4]))),
                         np.sum(np.square(coeffs[3]) * np.log(np.square(coeffs[3]))),
                         np.sum(np.square(coeffs[2]) * np.log(np.square(coeffs[2]))),
                         np.sum(np.square(coeffs[1]) * np.log(np.square(coeffs[1])))])
    A_Entropy_pynq[i,j] = np.sum(np.square(coeffs[0]) * np.log(np.square(coeffs[0])))
    D_mean_pynq[i,j] = np.mean([np.mean(coeffs[5]),np.mean(coeffs[4]),np.mean(coeffs[3]),np.mean(coeffs[2]),np.mean(coeffs[1])])
    A_mean_pynq[i,j] = np.mean(coeffs[0])
    D_std_pynq[i,j] = np.mean([np.std(coeffs[5]),np.std(coeffs[4]),np.std(coeffs[3]),np.std(coeffs[2]),np.std(coeffs[1])])
    A_std_pynq[i,j] = np.std(coeffs[0])

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

data_type approx_square_sum = 0.0;
data_type approx_mean = 0.0;
data_type approx_std = 0.0
square_sum_mean_std(approx_coeff, approx_square_sum, approx_mean, approx_std);




}
