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
		return res;
	}

	type data[8];
	int count;
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
//#pragma HLS UNROLL off
			res += data[start_index + i] * a.data[i];
		}
		return res;
	}

	type dot_v2(vec8<type> a, int start_index)
	{
		type mult[8];
	vec16_dot_v2_mult_loop:
		for (int i = 0; i < 8; i++)
		{
//#pragma HLS unroll
			mult[i] = data[start_index + i] * a.data[i];
		}

		type sum1[4];
	vec16_dot_v2_sum_loop:
		for (int i = 0; i < 4; i++)
		{
//#pragma HLS unroll
			sum1[i] = mult[i] + mult[i + 4];
		}

		type res = sum1[0] + sum1[1] + sum1[2] + sum1[3];

		return res;
	}

	type dot_v3(vec8<type> a, int start_index)
	{
//#pragma HLS INLINE
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

		type sum4 = sum0 + sum1;
		type sum5 = sum2 + sum3;

		type res = sum4 + sum5;

		return res;
	}

	type data[16];
	int count;
};

int dwt_db4_hls(hls::stream<packet> &s_in, hls::stream<packet> &coeff_lo, hls::stream<packet> &coeff_hi, int size, int &debug)
{
#pragma HLS INTERFACE axis port = s_in
#pragma HLS INTERFACE axis port = coeff_lo
#pragma HLS INTERFACE axis port = coeff_hi
#pragma HLS INTERFACE s_axilite port = size
#pragma HLS INTERFACE s_axilite port = debug
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

	vec8<data_type> hi_filter(-2.303778133088965008632911830440708500016152482483092977910968e-01,
						  7.148465705529156470899219552739926037076084010993081758450110e-01,
						  -6.308807679298589078817163383006152202032229226771951174057473e-01,
						  -2.798376941685985421141374718007538541198732022449175284003358e-02,
						  1.870348117190930840795706727890814195845441743745800912057770e-01,
						  3.084138183556076362721936253495905017031482172003403341821219e-02,
						  -3.288301166688519973540751354924438866454194113754971259727278e-02,
						  -1.059740178506903210488320852402722918109996490637641983484974e-02);
#pragma HLS ARRAY_PARTITION variable = hi_filter complete dim = 0

	vec8<data_type> lo_filter(-1.059740178506903210488320852402722918109996490637641983484974e-02,
						  3.288301166688519973540751354924438866454194113754971259727278e-02,
						  3.084138183556076362721936253495905017031482172003403341821219e-02,
						  -1.870348117190930840795706727890814195845441743745800912057770e-01,
						  -2.798376941685985421141374718007538541198732022449175284003358e-02,
						  6.308807679298589078817163383006152202032229226771951174057473e-01,
						  7.148465705529156470899219552739926037076084010993081758450110e-01,
						  2.303778133088965008632911830440708500016152482483092977910968e-01);
#pragma HLS ARRAY_PARTITION variable = lo_filter complete dim = 0

	// vec8<float> hi_filter(-0.230377813, 0.714846571, -0.630880768, -0.027983769,
	//					  0.187034812, 0.030841382, -0.032883012, -0.010597402);
	// vec8<float> lo_filter(-0.010597402, 0.032883012, 0.030841382, -0.187034812,
	//					  -0.027983769, 0.630880768, 0.714846571, 0.230377813);

	vec16<data_type> shift_reg;
#pragma HLS ARRAY_PARTITION variable = shift_reg complete dim = 0
	// #pragma HLS ARRAY_PARTITION variable = shift_reg[0].data complete dim = 0
	// #pragma HLS ARRAY_PARTITION variable = shift_reg[1].data complete dim = 0
	// #pragma HLS ARRAY_PARTITION variable = shift_reg[2].data complete dim = 0
	// #pragma HLS ARRAY_PARTITION variable = shift_reg[3].data complete dim = 0
	// #pragma HLS ARRAY_PARTITION variable = shift_reg[4].data complete dim = 0
	// #pragma HLS ARRAY_PARTITION variable = shift_reg[5].data complete dim = 0
	// #pragma HLS ARRAY_PARTITION variable = shift_reg[6].data complete dim = 0
	// #pragma HLS ARRAY_PARTITION variable=shift_reg[7].data complete dim=0

    static int debug_register = -1;
	int input_data_size = size;
	int output_data_size = (input_data_size + 8 - 1)/2;

    int out_data_counter = 0;

	packet in_packet;

	bool downsampler = true;
	bool running = true;
main_while_loop:
	while (running)
	{
//#pragma HLS PIPELINE off
#pragma HLS LOOP_TRIPCOUNT min = 512 max = 512

		//  only read if we still have some data left to read
		if (shift_reg.count < input_data_size)
		{
			s_in.read(in_packet);
		}
		
        //fpint idata;
		//idata.ival = in_packet.data;	
        //data_type ival = idata.fval;

        data_type in_data = in_packet.data;    

		shift_reg.shift_down(in_data);

		//not enough data read to do the convolution
		if (shift_reg.count <= 7)
			continue;

		// to make symmetric at the beggining of stream
		if (shift_reg.count == 8)
			shift_reg.make_symmetric_up();
		// to make symmetric at the end of stream
		if (shift_reg.count > input_data_size)
		{
			int index = (shift_reg.count - input_data_size) * 2 - 1;
			shift_reg.data[0] = shift_reg.data[index];
		}

		if (downsampler)
		{
		    data_type hi_out = shift_reg.dot_v3(hi_filter, 6);
		    data_type lo_out = shift_reg.dot_v3(lo_filter, 6);

			packet lo_packet;// = in_packet;
			packet hi_packet;// = in_packet;

            //fpint hi_data;
		    //hi_data.fval = hi_out;	
            //data_type hi_data = hi_data.ival;

            data_type hi_data = hi_out;    

            //fpint lo_data;
		    //lo_data.fval = lo_out;

            data_type lo_data = lo_out;    

			lo_packet.data = lo_data;
			hi_packet.data = hi_data;
			lo_packet.last = false;
			hi_packet.last = false;
			lo_packet.keep = -1;
			hi_packet.keep = -1;
            lo_packet.strb = -1;
            hi_packet.strb = -1;
            lo_packet.user = in_packet.user;
            hi_packet.user = in_packet.user;
            lo_packet.id   = in_packet.id;
            hi_packet.id   = in_packet.id;
            lo_packet.dest = in_packet.dest;
            hi_packet.dest = in_packet.dest;

            //all data is out
            //if (shift_reg.count > input_data_size + 12)
            if(out_data_counter == output_data_size-1)
            {
                running = false;
				lo_packet.last = true;
				hi_packet.last = true;
            }  

			coeff_lo.write(lo_packet);
			coeff_hi.write(hi_packet);

            out_data_counter++;
            debug_register = out_data_counter;
		}
		downsampler = !downsampler;
	}

    debug = debug_register;
	return 1.0;
}
