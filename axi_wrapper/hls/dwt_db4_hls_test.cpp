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

int main()
{
  hls::stream<float> s_in;
  hls::stream<float> coeff_lo;
  hls::stream<float> coeff_hi[DWT_LEVELS];

  int size = 32;

  int dwt_levels_size[DWT_LEVELS];
  dwt_levels_size[0] = ((size + 8 - 1) / 2);

  for (int i = 1; i < DWT_LEVELS; i++)
  {
    dwt_levels_size[i] = ((dwt_levels_size[i - 1] + 8 - 1) / 2);
  }

  for (int i = 0; i < size; i++)
  {
    s_in.write(i);
  }

  auto ret = dwt_db4_hls(s_in, coeff_lo, coeff_hi, size);

  std::cout << "ret = " << ret << std::endl;

  std::cout << "dwt approximation coeffs " << std::endl;

  for (int j = 0; j < dwt_levels_size[DWT_LEVELS-1]; j++)
  {
    std::cout << coeff_lo.read() << std::endl;
  }

  for (unsigned i = 0; i < DWT_LEVELS; i++)
  {
    std::cout << "dwt detail coeffs level " << i << std::endl;
    for (int j = 0; j < dwt_levels_size[i]; j++)
    {
      std::cout << coeff_hi[i].read() << std::endl;
    }
  }

  return 0;
}
