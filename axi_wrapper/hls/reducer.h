#include "hls_math.h"
#include "data_types.h"

#define BUFFER_LEN 10

extern void square_sum_mean_std(hls::stream<packet> &data_in, data_type &square_sum, data_type &mean, data_type &std, data_type &entropy);

extern int reducer(hls::stream<packet> &coeff,
			float &square_sum, float &mean,
			float &std, float &entropy, int size);

/*
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
                   */