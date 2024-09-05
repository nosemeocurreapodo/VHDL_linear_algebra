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
		reset();
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

		count = 0;
	}

	void reset()
	{
        vec8_reset_loop:
		for (int i = 0; i < 8; i++)
		{
#pragma HLS unroll
			data[i] = 0;
		}
		count = 0;
		newdata = false;
	}

	void shift_down(type val = 0)
	{
        vec8_shift_down_loop:
		for (int i = 7; i > 0; i--)
		{
            #pragma HLS unroll
			data[i] = data[i - 1];
		}
		data[0] = val;
		count++;
		newdata = true;
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
        vec8_dot_loop:
		for (int i = 0; i < 8; i++)
		{
			res += data[i] * a.data[i];
		}
		newdata = false;
		return res;
	}

	type data[8];
	int count;
	bool newdata;
};

template <typename type>
struct vec16
{
	vec16()
	{
		reset();
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

		count = 0;
	}

	void reset()
	{
        vec16_reset_loop:
		for (int i = 0; i < 16; i++)
		{
#pragma HLS unroll
			data[i] = 0;
		}
		count = 0;
		newdata = false;
	}

	void shift_down(type val = 0)
	{
        vec16_shift_down_loop:
		for (int i = 15; i > 0; i--)
		{
#pragma HLS unroll
			data[i] = data[i - 1];
		}
		data[0] = val;
		count++;
		newdata = true;
	}

	void shift_up(type val = 0)
	{
        vec16_shift_up_loop:
		for (int i = 0; i < 15 - 1; ++i)
		{
#pragma HLS unroll
			data[i] = data[i + 1];
		}
		data[15] = val;
		count++;
		newdata = true;
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
		data[9] = data[6];
		data[8] = data[7];
	}

	type dot(vec8<type> a, int start_index)
	{
		type res = 0;
        vec16_dot_loop:
		for (int i = 0; i < 8; i++)
		{
			res += data[start_index + i] * a.data[i];
		}
		newdata = false;
		return res;
	}

	type dot_v2(vec8<type> a, int start_index)
	{
		type mult[8];
        vec16_dot_v2_mult_loop:
		for (int i = 0; i < 8; i++)
		{
#pragma HLS unroll
			mult[i] = data[start_index + i] * a.data[i];
		}

		type sum1[4];
        vec16_dot_v2_sum_loop:
		for (int i = 0; i < 4; i++)
		{
#pragma HLS unroll
			sum1[i] = mult[i] + mult[i + 4];
		}

		type res = sum1[0] + sum1[1] + sum1[2] + sum1[3];

		newdata = false;
		return res;
	}

	type dot_v3(vec8<type> a, int start_index)
	{
#pragma HLS INLINE
		type mul0 = data[start_index + 0] * a.data[0];
		type mul1 = data[start_index + 1] * a.data[1];
		type mul2 = data[start_index + 2] * a.data[2];
		type mul3 = data[start_index + 3] * a.data[3];
		type mul4 = data[start_index + 4] * a.data[4];
		type mul5 = data[start_index + 5] * a.data[5];
		type mul6 = data[start_index + 6] * a.data[6];
		type mul7 = data[start_index + 7] * a.data[7];

		type sum0 = mul0 + mul4;
		type sum1 = mul1 + mul5;
		type sum2 = mul2 + mul6;
		type sum3 = mul3 + mul7;		

		type res = sum0 + sum1 + sum2 + sum3;

		newdata = false;
		return res;
	}

	type data[16];
	int count;
	bool newdata;
};

int dwt_db4_hls(hls::stream<float> &s_in, hls::stream<float> &coeff_lo, hls::stream<float> coeff_hi[DWT_LEVELS], int size)
{
#pragma HLS INTERFACE axis port = s_in
#pragma HLS INTERFACE axis port = coeff_lo
#pragma HLS INTERFACE axis port = coeff_hi
#pragma HLS INTERFACE s_axilite port = size
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

	vec8<float> hi_filter(-2.303778133088965008632911830440708500016152482483092977910968e-01,
						  7.148465705529156470899219552739926037076084010993081758450110e-01,
						  -6.308807679298589078817163383006152202032229226771951174057473e-01,
						  -2.798376941685985421141374718007538541198732022449175284003358e-02,
						  1.870348117190930840795706727890814195845441743745800912057770e-01,
						  3.084138183556076362721936253495905017031482172003403341821219e-02,
						  -3.288301166688519973540751354924438866454194113754971259727278e-02,
						  -1.059740178506903210488320852402722918109996490637641983484974e-02);

	vec8<float> hi_filter_array[DWT_LEVELS];
#pragma HLS ARRAY_PARTITION variable = hi_filter_array complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = hi_filter_array[0].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = hi_filter_array[1].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = hi_filter_array[2].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = hi_filter_array[3].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = hi_filter_array[4].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = hi_filter_array[5].data complete dim = 0
	for (int lvl = 0; lvl < DWT_LEVELS; lvl++)
		hi_filter_array[lvl] = hi_filter;

	vec8<float> lo_filter(-1.059740178506903210488320852402722918109996490637641983484974e-02,
						  3.288301166688519973540751354924438866454194113754971259727278e-02,
						  3.084138183556076362721936253495905017031482172003403341821219e-02,
						  -1.870348117190930840795706727890814195845441743745800912057770e-01,
						  -2.798376941685985421141374718007538541198732022449175284003358e-02,
						  6.308807679298589078817163383006152202032229226771951174057473e-01,
						  7.148465705529156470899219552739926037076084010993081758450110e-01,
						  2.303778133088965008632911830440708500016152482483092977910968e-01);

	vec8<float> lo_filter_array[DWT_LEVELS];
#pragma HLS ARRAY_PARTITION variable = lo_filter_array complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = lo_filter_array[0].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = lo_filter_array[1].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = lo_filter_array[2].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = lo_filter_array[3].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = lo_filter_array[4].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = lo_filter_array[5].data complete dim = 0
	for (int lvl = 0; lvl < DWT_LEVELS; lvl++)
		lo_filter_array[lvl] = lo_filter;

	// vec8<float> hi_filter(-0.230377813, 0.714846571, -0.630880768, -0.027983769,
	//					  0.187034812, 0.030841382, -0.032883012, -0.010597402);
	// vec8<float> lo_filter(-0.010597402, 0.032883012, 0.030841382, -0.187034812,
	//					  -0.027983769, 0.630880768, 0.714846571, 0.230377813);

	vec16<float> shift_reg[DWT_LEVELS + 1];
#pragma HLS ARRAY_PARTITION variable = shift_reg complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = shift_reg[0].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = shift_reg[1].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = shift_reg[2].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = shift_reg[3].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = shift_reg[4].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = shift_reg[5].data complete dim = 0
//#pragma HLS ARRAY_PARTITION variable = shift_reg[6].data complete dim = 0
	// #pragma HLS ARRAY_PARTITION variable=shift_reg[7].data complete dim=0

	bool downsampler[DWT_LEVELS];
	// #pragma HLS ARRAY_PARTITION variable=downsampler complete dim=0
    reset_downsampler_loop:
	for (int i = 0; i < DWT_LEVELS; i++)
		downsampler[i] = true;

	int dwt_levels_size[DWT_LEVELS];
	// #pragma HLS ARRAY_PARTITION variable=dwt_levels_size complete dim=0
	dwt_levels_size[0] = size;
    set_dwt_levels_size_loop:
	for (int i = 1; i < DWT_LEVELS; i++)
	{
		// dwt_levels_size[i] = dwt_levels_size[i - 1] / 2;
		dwt_levels_size[i] = ((dwt_levels_size[i - 1] + 8 - 1) / 2);
	}

	bool lvls_done[DWT_LEVELS];
#pragma HLS ARRAY_PARTITION variable = lvls_done complete dim = 0
    reset_lvls_done_loop:
	for (int i = 0; i < DWT_LEVELS; i++)
	{
		lvls_done[i] = false;
	}
	// lvl_done[DWT_LEVELS - 1] = true;

	bool all_done = false;
main_while_loop:
	while (!all_done)
	{
#pragma HLS LOOP_TRIPCOUNT min = 512 max = 512

		float val = 0;
		// only read if we still have some data left to read
		if (shift_reg[0].count < size)
		{
			val = s_in.read();
		}

		shift_reg[0].shift_down(val);
		// to make symmetric at the beggining of stream
		if (shift_reg[0].count == 8)
			shift_reg[0].make_symmetric_up();
		// to make symmetric at the end of stream
		if (shift_reg[0].count > dwt_levels_size[0])
		{
			int index = (shift_reg[0].count - dwt_levels_size[0]) * 2 - 1;
			shift_reg[0].data[0] = shift_reg[0].data[index];
		}

	for_lvl:
		for (int lvl = 0; lvl < DWT_LEVELS; lvl++)
		{
#pragma HLS unroll

			// if (lvl_done[lvl])
			//	continue;

			bool lvl_done = false;

			if (!shift_reg[lvl].newdata || shift_reg[lvl].count <= 7)
				continue;

			if (shift_reg[lvl].count > dwt_levels_size[lvl] + 12 + lvl)
			{
				lvl_done = true;
				// do_conv = false;
			}

			float hi_out = shift_reg[lvl].dot_v3(hi_filter_array[lvl], 6);
			float lo_out = shift_reg[lvl].dot_v3(lo_filter_array[lvl], 6);

			if (downsampler[lvl])
			{
				// #pragma HLS inline recursive
				shift_reg[lvl + 1].shift_down(lo_out);

				// to make symmetric at the beggining of stream
				if (shift_reg[lvl + 1].count == 8)
					shift_reg[lvl + 1].make_symmetric_up();
				else
					// to make symmetric at the end of stream
					if (shift_reg[lvl + 1].count > dwt_levels_size[lvl + 1])
					{
						int index = (shift_reg[lvl + 1].count - dwt_levels_size[lvl + 1]) * 2 - 1;
						shift_reg[lvl + 1].data[0] = shift_reg[lvl + 1].data[index];
					}

				if (!lvl_done)
				{
					if (lvl == DWT_LEVELS - 1)
						coeff_lo.write(lo_out);
					coeff_hi[lvl].write(hi_out);
				}
			}
			downsampler[lvl] = !downsampler[lvl];
			lvls_done[lvl] = lvl_done;
		}

		bool is_all_done = true;
        is_all_done_loop:
		for (int lvl = 0; lvl < DWT_LEVELS; lvl++)
		{
			is_all_done = is_all_done & lvls_done[lvl];
		}
		all_done = is_all_done;
	}

	return 1.0;
}
