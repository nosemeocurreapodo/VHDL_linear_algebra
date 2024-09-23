#include "reducer.h"

/*
void square_sum_mean_std(hls::stream<packet> &data_in, data_type &_square_sum, data_type &_mean, data_type &_std, data_type &_entropy)
{
//#pragma HLS INLINE
//#pragma HLS allocation operation instances=mul limit=1 
//#pragma HLS allocation operation instances=div limit=1 
//#pragma HLS allocation operation instances=add limit=1 
//#pragma HLS allocation operation instances=sub limit=1

	packet p;
	data_in.read(p);
	int n = 1;

    data_type square_sum = 0.0;
    data_type mean = p.data;
    data_type std = 0.0;
    data_type entropy = 0.0;

ssms_loop:
	while (true)
	{
#pragma HLS LOOP_TRIPCOUNT max=512 avg=512 min=512
//#pragma HLS PIPELINE off

        data_in.read(p);
		data_type data = p.data;
        n++;

        data_type diff = data - mean;
        data_type diff_mean = diff / n;
        data_type new_mean = mean + diff_mean;
        data_type new_diff = data - mean;
        data_type new_diff_std = diff * new_diff;
        data_type new_std = std + new_diff_std;

		data_type new_square = data * data;
		data_type new_square_sum = square_sum + new_square;
        data_type new_log = data_type(hls::log(float(new_square)));
		data_type new_entropy = new_square * new_log;
        data_type new_entropy_sum = entropy + new_entropy;

        mean = new_mean;
        std = new_std;

        square_sum = new_square_sum;
        entropy = new_entropy_sum;

		if (p.last)
			break;
	}

    _square_sum = square_sum;
    _mean = mean;
    _std = std / (n - 1);
	_entropy = entropy;
}
*/

int reducer(hls::stream<packet> &coeff,
			float &square_sum, float &mean,
			float &std, float &entropy, int size)
{
#pragma HLS INTERFACE axis port = coeff
#pragma HLS INTERFACE s_axilite port = square_sum
#pragma HLS INTERFACE s_axilite port = mean
#pragma HLS INTERFACE s_axilite port = std
#pragma HLS INTERFACE s_axilite port = entropy
#pragma HLS INTERFACE s_axilite port = size
#pragma HLS INTERFACE s_axilite port = return

    data_type mean_p[BUFFER_LEN];
    data_type square_sum_p[BUFFER_LEN];
    data_type entropy_p[BUFFER_LEN];
init_buffer_loop:
    for(int i = 0; i < BUFFER_LEN; i++)
    {
        mean_p[i] = 0.0;
        square_sum_p[i] = 0.0;
        entropy_p[i] = 0.0;
    }

ssms_loop:
	for(int i = 0; i < size; i++)
	{
#pragma HLS LOOP_TRIPCOUNT max=512 avg=512 min=512
//#pragma HLS PIPELINE off
	    packet p;
        coeff.read(p);
		data_type data = p.data;

        data_type new_mean = data;
		data_type new_square = data * data;
        data_type new_log = data_type(hls::log(float(new_square)));
		data_type new_entropy = new_square * new_log;

        mean_p[i % BUFFER_LEN] += new_mean;
        square_sum_p[i % BUFFER_LEN] += new_square;
        entropy_p[i % BUFFER_LEN] += new_entropy;
        //_entropy = new_entropy_sum;

		//if (p.last)
		//	break;
	}

    data_type _mean = 0.0;
    data_type _std = 0.0;
    data_type _square_sum = 0.0;
    data_type _entropy = 0.0;
buffer_loop:
    for(int i = 0; i < BUFFER_LEN; i++)
    {
        _mean += mean_p[i];
        _square_sum += square_sum_p[i];
        _entropy += entropy_p[i];
    }

    mean = _mean / size;
    std = _std / (size - 1);
    square_sum = _square_sum;
    entropy = _entropy;

	return 1;
}


/*
int reducer(hls::stream<packet> &approx_coeff,
			hls::stream<packet> &detail_1_coeff,
			hls::stream<packet> &detail_2_coeff,
			hls::stream<packet> &detail_3_coeff,
			hls::stream<packet> &detail_4_coeff,
			hls::stream<packet> &detail_5_coeff,
			float &cD_Energy, float &cA_Energy,
			float &D_Entropy, float &A_Entropy,
			float &D_mean, float &A_mean,
			float &D_std, float &A_std)
{
#pragma HLS INTERFACE axis port = approx_coeff
#pragma HLS INTERFACE axis port = detail_1_coeff
#pragma HLS INTERFACE axis port = detail_2_coeff
#pragma HLS INTERFACE axis port = detail_3_coeff
#pragma HLS INTERFACE axis port = detail_4_coeff
#pragma HLS INTERFACE axis port = detail_5_coeff
#pragma HLS INTERFACE s_axilite port = cD_Energy
#pragma HLS INTERFACE s_axilite port = cA_Energy
#pragma HLS INTERFACE s_axilite port = D_Entropy
#pragma HLS INTERFACE s_axilite port = A_Entropy
#pragma HLS INTERFACE s_axilite port = D_mean
#pragma HLS INTERFACE s_axilite port = A_mean
#pragma HLS INTERFACE s_axilite port = D_std
#pragma HLS INTERFACE s_axilite port = A_std
#pragma HLS INTERFACE s_axilite port = return

#pragma HLS allocation operation instances=mul limit=1 
#pragma HLS allocation operation instances=div limit=1 
#pragma HLS allocation operation instances=add limit=1 
#pragma HLS allocation operation instances=sub limit=1

#pragma HLS allocation function instances=square_sum_mean_std limit=1

	data_type approx_square_sum = 0.0;
	data_type approx_mean = 0.0;
	data_type approx_std = 0.0;
	data_type approx_ent = 0.0;
	square_sum_mean_std(approx_coeff, approx_square_sum, approx_mean, approx_std, approx_ent);

	data_type detail_1_square_sum = 0.0;
	data_type detail_1_mean = 0.0;
	data_type detail_1_std = 0.0;
	data_type detail_1_ent = 0.0;
	square_sum_mean_std(detail_1_coeff, detail_1_square_sum, detail_1_mean, detail_1_std, detail_1_ent);

	data_type detail_2_square_sum = 0.0;
	data_type detail_2_mean = 0.0;
	data_type detail_2_std = 0.0;
	data_type detail_2_ent = 0.0;
	square_sum_mean_std(detail_2_coeff, detail_2_square_sum, detail_2_mean, detail_2_std, detail_2_ent);

	data_type detail_3_square_sum = 0.0;
	data_type detail_3_mean = 0.0;
	data_type detail_3_std = 0.0;
	data_type detail_3_ent = 0.0;
	square_sum_mean_std(detail_3_coeff, detail_3_square_sum, detail_3_mean, detail_3_std, detail_3_ent);

	data_type detail_4_square_sum = 0.0;
	data_type detail_4_mean = 0.0;
	data_type detail_4_std = 0.0;
	data_type detail_4_ent = 0.0;
	square_sum_mean_std(detail_4_coeff, detail_4_square_sum, detail_4_mean, detail_4_std, detail_4_ent);

	data_type detail_5_square_sum = 0.0;
	data_type detail_5_mean = 0.0;
	data_type detail_5_std = 0.0;
	data_type detail_5_ent = 0.0;
	square_sum_mean_std(detail_5_coeff, detail_5_square_sum, detail_5_mean, detail_5_std, detail_5_ent);

	data_type num_elements = 5.0;

	cD_Energy = (detail_1_square_sum + detail_2_square_sum + detail_3_square_sum + detail_4_square_sum + detail_5_square_sum) / num_elements;
	cA_Energy = approx_square_sum;
	D_Entropy = (detail_1_ent + detail_2_ent + detail_3_ent + detail_4_ent + detail_5_ent) / num_elements;
	A_Entropy = approx_ent;
	D_mean = (detail_1_mean + detail_2_mean + detail_3_mean + detail_4_mean + detail_5_mean) / num_elements;
	A_mean = approx_mean;
	D_std = (detail_1_std + detail_2_std + detail_3_std + detail_4_std + detail_5_std) / num_elements;
	A_std = approx_std;

	return 1;
}
*/