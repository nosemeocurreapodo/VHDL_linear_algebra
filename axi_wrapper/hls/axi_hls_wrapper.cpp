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

#include "axi_hls_wrapper.h"

struct vec8
{
	void shift_down()
	{
		for(int i = 0; i < 7; i++)
		{
			conv8_in_1[i] = conv8_in_1[i+1];
		}
	}

	int dot(vec8 &a)
	{
		int res = 0;
		for(int i = 0; i < 8; i++)
		{
			res += data[i]*a.data[i];
		}
		return res;
	}

	data[8];
}

int axi_hsl_wrapper(hls::stream<int> &s_in, hls::stream<int> &s_out)
{
#pragma HLS INTERFACE axis port = s_in
#pragma HLS INTERFACE axis port = s_out
#pragma HLS INTERFACE s_axilite port = return

	vec8 val_in_1;
	vec8 val_in_2;

	while (true)
	{
		int val = s_in.read();

		val_in_1.shift_down();
		val_in_1.data[7] = val;

		int conv_out = val_in_1.dot(val_in_2);

		s_out.write(conv_out);
	}

	return 1.0;
}
