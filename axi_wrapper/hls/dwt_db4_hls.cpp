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

template <typename type>
struct vec8
{
	vec8()
	{
		for (int i = 0; i < 8; i++)
		{
			data[i] = 0;
		}
	}

	vec8(type a, type b, type c, type d, type e, type f, type g, type h)
	{
		data[0] = a;
		data[1] = b;
		data[2] = c;
		data[3] = d;
		data[4] = e;
		data[5] = f;
		data[6] = g;
		data[7] = h;
	}

	void zero()
	{
		for (int i = 0; i < 8; i++)
		{
			data[i] = 0;
		}
	}

	void shift_down(type val = 0)
	{
		for (int i = 7; i > 0; i--)
		{
			data[i] = data[i - 1];
		}
		data[0] = val;
	}

	void make_symmetric_down()
	{
		data[0] = data[7];
		data[1] = data[6];
		data[2] = data[5];
		data[3] = data[4];
	}

	void make_symmetric_up()
	{
		data[7] = data[0];
		data[6] = data[1];
		data[5] = data[2];
		data[4] = data[3];
	}

	type dot(vec8<type> a)
	{
		type res = 0;
		for (int i = 0; i < 8; i++)
		{
			res += data[i] * a.data[i];
		}
		return res;
	}

	type data[8];
};

template <typename type>
struct vec16
{
	vec16()
	{
		for (int i = 0; i < 16; i++)
		{
			data[i] = 0;
		}
	}

	vec16(type a, type b, type c, type d, type e, type f, type g, type h)
	{
		data[0] = a;
		data[1] = b;
		data[2] = c;
		data[3] = d;
		data[4] = e;
		data[5] = f;
		data[6] = g;
		data[7] = h;
	}

	void zero()
	{
		for (int i = 0; i < 16; i++)
		{
			data[i] = 0;
		}
	}

	void shift_down(type val = 0)
	{
		for (int i = 15; i > 0; i--)
		{
			data[i] = data[i - 1];
		}
		data[0] = val;
	}

	void make_symmetric_down()
	{
		data[0] = data[15];
		data[1] = data[14];
		data[2] = data[13];
		data[3] = data[12];
        data[4] = data[11];
		data[5] = data[10];
		data[6] = data[9];
		data[7] = data[8];
	}

	void make_symmetric_up()
	{
		data[15] = data[0];
		data[14] = data[1];
		data[13] = data[2];
		data[12] = data[3];
        data[11] = data[4];
		data[10] = data[5];
		data[9]  = data[6];
		data[8]  = data[7];
	}

	type dot(vec8<type> a, int start_index)
	{
		type res = 0;
		for (int i = 0; i < 8; i++)
		{
			res += data[start_index + i] * a.data[i];
		}
		return res;
	}

	type data[16];
};

int dwt_db4_hls(hls::stream<float> &s_in, hls::stream<float> coeff[DWT_LEVELS],
				int size)
{
#pragma HLS INTERFACE axis port = s_in
#pragma HLS INTERFACE axis port = coeff
// #pragma HLS INTERFACE s_axilite port = levels
#pragma HLS INTERFACE s_axilite port = return

	// from what I can read in the pywt implementation
	//  2.303778133088965008632911830440708500016152482483092977910968e-01,
	//  7.148465705529156470899219552739926037076084010993081758450110e-01,
	//  6.308807679298589078817163383006152202032229226771951174057473e-01,
	//-2.798376941685985421141374718007538541198732022449175284003358e-02,
	//-1.870348117190930840795706727890814195845441743745800912057770e-01,
	//  3.084138183556076362721936253495905017031482172003403341821219e-02,
	//  3.288301166688519973540751354924438866454194113754971259727278e-02,
	//-1.059740178506903210488320852402722918109996490637641983484974e-02

	vec8<float> hi_filter(-0.230377813, 0.714846571, -0.630880768, -0.027983769,
						  0.187034812, 0.030841382, -0.032883012, -0.010597402);
	vec8<float> lo_filter(-0.010597402, 0.032883012, 0.030841382, -0.187034812,
						  -0.027983769, 0.630880768, 0.714846571, 0.230377813);

	vec16<float> shift_reg[DWT_LEVELS];

	bool downsampler[DWT_LEVELS];
	for (int i = 0; i < DWT_LEVELS; i++)
		downsampler[i] = true;

	int dwt_levels_size[DWT_LEVELS];
	dwt_levels_size[0] = size;
	for (int i = 1; i < DWT_LEVELS; i++)
	{
		dwt_levels_size[i] = dwt_levels_size[i - 1] / 2;
	}

	int indexes[DWT_LEVELS];
	for (int i = 0; i < DWT_LEVELS; i++)
	{
		indexes[i] = 0;
	}

	bool lvl_done[DWT_LEVELS];
	for (int i = 0; i < DWT_LEVELS; i++)
	{
		lvl_done[i] = false;
	}
    lvl_done[DWT_LEVELS - 1] = true;

	bool all_done = false;
	while (!all_done)
	{
		float val = 0;
		// only read if we still have some data left to read
		if (indexes[0] < size)
		{
			val = s_in.read();
		}

		shift_reg[0].shift_down(val);
        indexes[0]++;

		for (int lvl = 0; lvl < DWT_LEVELS - 1; lvl++)
		{
			// if (!shift_reg[lvl].is_ready_for_conv())
			//	continue;

			//if (lvl_done[lvl])
			//	continue;

			bool do_conv = true;
			if (indexes[lvl] <= 7)
			{
				do_conv = false;
			}
			// to make symmetric at the beggining of stream
			if (indexes[lvl] == 8)
			{
				shift_reg[lvl].make_symmetric_up();
				do_conv = true;
			}
			// to make symmetric at the end of stream
			if (indexes[lvl] > dwt_levels_size[lvl])
			{
				int index = (indexes[lvl] - dwt_levels_size[lvl]) * 2 - 1;
				shift_reg[lvl].data[0] = shift_reg[lvl].data[index];
				do_conv = true;
			}
			if (indexes[lvl] > dwt_levels_size[lvl] + 12)
			{
				lvl_done[lvl] = true;
				do_conv = false;
			}

			if (!do_conv)
				continue;

			float hi_out = shift_reg[lvl].dot(hi_filter, 6);
			float lo_out = shift_reg[lvl].dot(lo_filter, 6);
			if (downsampler[lvl])
			{
				shift_reg[lvl + 1].shift_down(hi_out);
                indexes[lvl + 1]++;
				coeff[lvl].write(lo_out);
			}
			downsampler[lvl] = !downsampler[lvl];
		}

		bool is_all_done = true;
		for (int lvl = 0; lvl < DWT_LEVELS; lvl++)
		{
			is_all_done = is_all_done & lvl_done[lvl];
		}
		all_done = is_all_done;
	}

	return 1.0;
}
