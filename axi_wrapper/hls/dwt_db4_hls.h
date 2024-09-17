
#pragma once

#include "ap_axi_sdata.h"
//#include "ap_int.h"
#include "ap_fixed.h"
#include "hls_stream.h"
#include "data_types.h"

extern int dwt_db4_hls(hls::stream<packet> &s_in, hls::stream<packet> &coeff_lo, hls::stream<packet> &coeff_hi, int size, int &debug);
