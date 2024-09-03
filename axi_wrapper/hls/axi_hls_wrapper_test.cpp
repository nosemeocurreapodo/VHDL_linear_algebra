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

int main() {
  hls::stream<int> s_in, s_out;
  for (unsigned i = 0; i < 10; i++) {
    s_in.write(i);
  }

  auto ret = axi_hls_wrapper(s_in, s_out);

  std::cout << "ret = " << ret << std::endl;

  for (unsigned i = 0; i < 10; i++) {
    if (s_out.read() != i)
      return 1;
  }

  return 0;
}
