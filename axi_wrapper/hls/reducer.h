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

#include "hls_math.h"
#include "data_types.h"

extern void square_sum_mean_std(hls::stream<packet> &data_in, data_type &square_sum, data_type &mean, data_type &std, data_type &entropy);

extern int reducer(hls::stream<packet> &approx_coeff,
				   hls::stream<packet> &detail_1_coeff,
				   hls::stream<packet> &detail_2_coeff,
				   hls::stream<packet> &detail_3_coeff,
				   hls::stream<packet> &detail_4_coeff,
				   hls::stream<packet> &detail_5_coeff,
				   float &cD_Energy, float &cA_Energy,
				   float &D_Entropy, float &A_Entropy,
				   float &D_mean, float &A_mean,
				   float &D_std, float &A_std);