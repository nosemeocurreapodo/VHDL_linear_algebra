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
	hls::stream<packet> s_in;
	hls::stream<packet> coeff_lo1;
	hls::stream<packet> coeff_lo2;
	hls::stream<packet> coeff_lo3;
	hls::stream<packet> coeff_lo4;
	hls::stream<packet> coeff_lo5;
	hls::stream<packet> coeff_hi1;
	hls::stream<packet> coeff_hi2;
	hls::stream<packet> coeff_hi3;
	hls::stream<packet> coeff_hi4;
	hls::stream<packet> coeff_hi5;

	int size = 32;
    int debug = 0;

	int dwt_data_size1 = ((size + 8 - 1) / 2);
	int dwt_data_size2 = ((dwt_data_size1 + 8 - 1) / 2);
	int dwt_data_size3 = ((dwt_data_size2 + 8 - 1) / 2);
	int dwt_data_size4 = ((dwt_data_size3 + 8 - 1) / 2);
	int dwt_data_size5 = ((dwt_data_size4 + 8 - 1) / 2);

	// output of:
	// import pywt
	// import numpy as np
	// a = [i for i in range(32)]
	// a = np.array(a, np.float32)
	// pywt.wavedec(a, "db4", level=1)

    /*
	float approx_coeff_gt[] = {5.6503181e+00, 2.8165226e+00, -6.0641766e-04, 1.4218407e+00,
							   4.2502680e+00, 7.0786948e+00, 9.9071217e+00, 1.2735549e+01,
							   1.5563976e+01, 1.8392403e+01, 2.1220829e+01, 2.4049257e+01,
							   2.6877686e+01, 2.9706112e+01, 3.2534538e+01, 3.5362968e+01,
							   3.8190300e+01, 4.1024101e+01, 4.3841228e+01};
	float detail_coeff_gt[] = {2.3713142e-02, 4.0962040e-02, -6.4675264e-02, -3.1664968e-07,
							   1.1175871e-08, -8.1956387e-08, -2.9802322e-07, -3.7252903e-07,
							   -8.0466270e-07, 4.1723251e-07, 6.4074993e-07, 2.9802322e-08,
							   -9.0897083e-07, -1.3709068e-06, -4.1723251e-07, 1.1920929e-07,
							   -2.3712426e-02, -4.0962070e-02, 6.4675987e-02};
    */

    //pywt.wavedec(a, "db4", level=2)
    /*
    float approx_coeff_gt[] = {5.3695197,  0.9608713,  8.282546 ,  2.8890991,  2.356266 ,
       10.032358 , 18.03236  , 26.032356 , 34.032276 , 42.062515 ,
       49.816418 , 58.87885  , 61.333702};
    float detail_coeff2_gt[] = {-4.2428684e-01, -1.1343775e+00,  9.9592429e-01, -3.2324696e-01,
       -1.4899485e-02, -1.5199184e-06,  9.6857548e-07, -1.7136335e-06,
       -1.7699748e-03,  6.4553487e-01, -1.0145376e+00,  3.4057111e-01,
        3.0205071e-02};
    float detail_coeff1_gt[] = {2.3713142e-02,  4.0962040e-02, -6.4675264e-02, -3.1664968e-07,
        1.1175871e-08, -8.1956387e-08, -2.9802322e-07, -3.7252903e-07,
       -8.0466270e-07,  4.1723251e-07,  6.4074993e-07,  2.9802322e-08,
       -9.0897083e-07, -1.3709068e-06, -4.1723251e-07,  1.1920929e-07,
       -2.3712426e-02, -4.0962070e-02,  6.4675987e-02};
    */

	// pywt.wavedec(a, "db4", level=3)
    /*
    data_type approx_coeff_gt[] = {5.738772 ,  6.3093557,  5.9315276,  7.2541356,  3.282682 ,
       14.308411 , 36.921993 , 59.51736  , 82.09035  , 87.57296};
    data_type detail_coeff3_gt[] = {1.6570338 ,  5.22966   , -2.5227473 ,  1.2052422 , -0.52404594,
       -0.37183353, -0.9556874 ,  1.0071528 ,  0.05120391,  0.27400422};
    data_type detail_coeff2_gt[] = {-4.2428684e-01, -1.1343775e+00,  9.9592429e-01, -3.2324696e-01,
       -1.4899485e-02, -1.5199184e-06,  9.6857548e-07, -1.7136335e-06,
       -1.7699748e-03,  6.4553487e-01, -1.0145376e+00,  3.4057111e-01,
        3.0205071e-02};
	data_type detail_coeff1_gt[] = {2.3713142e-02,  4.0962040e-02, -6.4675264e-02, -3.1664968e-07,
        1.1175871e-08, -8.1956387e-08, -2.9802322e-07, -3.7252903e-07,
       -8.0466270e-07,  4.1723251e-07,  6.4074993e-07,  2.9802322e-08,
       -9.0897083e-07, -1.3709068e-06, -4.1723251e-07,  1.1920929e-07,
       -2.3712426e-02, -4.0962070e-02,  6.4675987e-02};
       */

	// pywt.wavedec(a, "db4", level=5)
    float approx_coeff_gt[] = {13.338167 ,  12.148256 ,  12.880251 ,  14.67364  ,   1.8900021,
        48.95557  , 182.20184};
        
    float detail_coeff5_gt[] = {-0.13108708,  -0.77735364,  -6.374552  ,  21.89712   ,
        -8.42237   , -19.206541  ,  16.702948};
        
    float detail_coeff4_gt[] = {-0.07468142, -0.5760854 , -4.590718  ,  4.834744  ,  2.4015787 ,
       -2.090611  , -3.6374884 , -1.181816};
       
    float detail_coeff3_gt[] = {1.6570338 ,  5.22966   , -2.5227473 ,  1.2052422 , -0.52404594,
       -0.37183353, -0.9556874 ,  1.0071528 ,  0.05120391,  0.27400422};
       
    float detail_coeff2_gt[] = {-4.2428684e-01, -1.1343775e+00,  9.9592429e-01, -3.2324696e-01,
       -1.4899485e-02, -1.5199184e-06,  9.6857548e-07, -1.7136335e-06,
       -1.7699748e-03,  6.4553487e-01, -1.0145376e+00,  3.4057111e-01,
        3.0205071e-02};
        
    float detail_coeff1_gt[] = {2.3713142e-02,  4.0962040e-02, -6.4675264e-02, -3.1664968e-07,
        1.1175871e-08, -8.1956387e-08, -2.9802322e-07, -3.7252903e-07,
       -8.0466270e-07,  4.1723251e-07,  6.4074993e-07,  2.9802322e-08,
       -9.0897083e-07, -1.3709068e-06, -4.1723251e-07,  1.1920929e-07,
       -2.3712426e-02, -4.0962070e-02,  6.4675987e-02};


	for (int i = 0; i < size; i++)
	{
		packet in_packet;

        //fpint in_data;
		//in_data.fval = float(i);	
        //in_packet.data = in_data.ival;

        in_packet.data = float(i);
		in_packet.last = false;
        in_packet.keep = -1;
		if (i == size - 1)
			in_packet.last = true;
		s_in.write(in_packet);
	}

	auto ret1 = dwt_db4_hls(s_in, coeff_lo1, coeff_hi1, size, debug);
    std::cout << "debug " << debug << std::endl;
    auto ret2 = dwt_db4_hls(coeff_lo1, coeff_lo2, coeff_hi2, dwt_data_size1, debug);
    std::cout << "debug " << debug << std::endl;
    auto ret3 = dwt_db4_hls(coeff_lo2, coeff_lo3, coeff_hi3, dwt_data_size2, debug);
    std::cout << "debug " << debug << std::endl;
    auto ret4 = dwt_db4_hls(coeff_lo3, coeff_lo4, coeff_hi4, dwt_data_size3, debug);
    std::cout << "debug " << debug << std::endl;
    auto ret5 = dwt_db4_hls(coeff_lo4, coeff_lo5, coeff_hi5, dwt_data_size4, debug);
    std::cout << "debug " << debug << std::endl;

	std::cout << "dwt approximation coeffs " << std::endl;

	float approx_coeff_mse = 0.0;
	for (int j = 0; j < dwt_data_size5; j++)
	{
		packet lo_packet;
		coeff_lo5.read(lo_packet);

        //fpint lo_data;
		//lo_data.ival = lo_packet.data;	
        //data_type lo_val = lo_data.fval;

        float lo_val = lo_packet.data;

        std::cout << "gt " << approx_coeff_gt[j] << " est " << lo_val << std::endl;

		approx_coeff_mse += std::pow(approx_coeff_gt[j] - lo_val, 2.0);
	}
	approx_coeff_mse /= dwt_data_size3;

	std::cout << "approx coeff mse: " << approx_coeff_mse << std::endl;

	std::cout << "dwt detail coeffs 1" << std::endl;
	float detail_coeff1_mse = 0.0;
	for (int j = 0; j < dwt_data_size1; j++)
	{
		packet hi_packet;
		coeff_hi1.read(hi_packet);

        //fpint hi_data;
		//hi_data.ival = hi_packet.data;	
        //data_type hi_val = hi_data.fval;

        float hi_val = hi_packet.data;
        
        std::cout << "gt " << detail_coeff1_gt[j] << " est " << hi_val << std::endl;

		detail_coeff1_mse += std::pow(detail_coeff1_gt[j] - hi_val, 2.0);
		// std::cout << hi_data.fval << std::endl;
	}

	detail_coeff1_mse /= dwt_data_size1;
	std::cout << "detail coeff 1 mse: " << detail_coeff1_mse << std::endl;

	std::cout << "dwt detail coeffs 2" << std::endl;
	float detail_coeff2_mse = 0.0;
	for (int j = 0; j < dwt_data_size2; j++)
	{
		packet hi_packet;
		coeff_hi2.read(hi_packet);

        //fpint hi_data;
		//hi_data.ival = hi_packet.data;	
        //data_type hi_val = hi_data.fval;

        float hi_val = hi_packet.data;

        std::cout << "gt " << detail_coeff2_gt[j] << " est " << hi_val << std::endl;

		detail_coeff2_mse += std::pow(detail_coeff2_gt[j] - hi_val, 2.0);
		// std::cout << hi_data.fval << std::endl;
	}

	detail_coeff2_mse /= dwt_data_size2;
	std::cout << "detail coeff 2 mse: " << detail_coeff2_mse << std::endl;	

	std::cout << "dwt detail coeffs 3" << std::endl;
	float detail_coeff3_mse = 0.0;
	for (int j = 0; j < dwt_data_size3; j++)
	{
		packet hi_packet;
		coeff_hi3.read(hi_packet);

        //fpint hi_data;
		//hi_data.ival = hi_packet.data;	
        //data_type hi_val = hi_data.fval;

        float hi_val = hi_packet.data;

        std::cout << "gt " << detail_coeff3_gt[j] << " est " << hi_val << std::endl;

		detail_coeff2_mse += std::pow(detail_coeff3_gt[j] - hi_val, 2.0);
		// std::cout << hi_data.fval << std::endl;
	}

	detail_coeff3_mse /= dwt_data_size3;
	std::cout << "detail coeff 3 mse: " << detail_coeff3_mse << std::endl;	


	std::cout << "dwt detail coeffs 4" << std::endl;
	float detail_coeff4_mse = 0.0;
	for (int j = 0; j < dwt_data_size4; j++)
	{
		packet hi_packet;
		coeff_hi4.read(hi_packet);

        //fpint hi_data;
		//hi_data.ival = hi_packet.data;	
        //data_type hi_val = hi_data.fval;

        float hi_val = hi_packet.data;

        std::cout << "gt " << detail_coeff4_gt[j] << " est " << hi_val << std::endl;

		detail_coeff4_mse += std::pow(detail_coeff4_gt[j] - hi_val, 2.0);
		// std::cout << hi_data.fval << std::endl;
	}

	detail_coeff4_mse /= dwt_data_size4;
	std::cout << "detail coeff 4 mse: " << detail_coeff4_mse << std::endl;	


	std::cout << "dwt detail coeffs 5" << std::endl;
	float detail_coeff5_mse = 0.0;
	for (int j = 0; j < dwt_data_size5; j++)
	{
		packet hi_packet;
		coeff_hi5.read(hi_packet);

        //fpint hi_data;
		//hi_data.ival = hi_packet.data;	
        //data_type hi_val = hi_data.fval;

        float hi_val = hi_packet.data;

        std::cout << "gt " << detail_coeff5_gt[j] << " est " << hi_val << std::endl;

		detail_coeff5_mse += std::pow(detail_coeff5_gt[j] - hi_val, 2.0);
		// std::cout << hi_data.fval << std::endl;
	}

	detail_coeff5_mse /= dwt_data_size5;
	std::cout << "detail coeff 5 mse: " << detail_coeff5_mse << std::endl;	

	return 0;
}
