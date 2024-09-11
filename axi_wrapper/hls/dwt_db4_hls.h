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
#ifndef __ARRAY_OF_STREAMS_EXAMPLE__
#define __ARRAY_OF_STREAMS_EXAMPLE__

#include "ap_axi_sdata.h"
#include "ap_int.h"
#include "hls_stream.h"
#include <iostream>

typedef ap_axis<32, 2, 5, 6> packet;

// use a union to "convert" between integer and floating-point
union fpint
{
    int ival;   // integer alias
    float fval; // floating-point alias
};

extern int dwt_db4_hls(hls::stream<packet> &s_in, hls::stream<packet> &coeff_lo, hls::stream<packet> &coeff_hi, int size);

#endif
