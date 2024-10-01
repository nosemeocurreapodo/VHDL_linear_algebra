#pragma once

#include "ap_axi_sdata.h"
//#include "ap_int.h"
#include "ap_fixed.h"
#include "hls_half.h"
#include "hls_stream.h"


//typedef ap_fixed<24, 12, AP_RND> data_type;
//typedef float data_type;
typedef half data_type;
//typedef int data_type;

//typedef ap_axis<32, 2, 5, 6> packet;
//typedef hls::axis<float, 0, 0, 0> packet;
//typedef hls::axis_data<float, AXIS_ENABLE_KEEP|AXIS_ENABLE_LAST> packet;

typedef  hls::axis<float, 0, 0, 0, (AXIS_ENABLE_KEEP | AXIS_ENABLE_LAST | AXIS_ENABLE_STRB), false> packet;

// use a union to "convert" between integer and floating-point
//union fpint
//{
//    int ival;   // integer alias
//    data_type fval; // floating-point alias
//};
