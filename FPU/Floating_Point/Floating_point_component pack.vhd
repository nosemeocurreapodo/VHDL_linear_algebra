library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Floating_point_definition.all;
use work.FPU_commmon_pack.all;
use work.request_id_pack.all;

package Floating_point_component_pack is
	component Floating_point_Adder is
		port(
			clk       : in  std_logic;
			opa       : in  floating_point;
			opb       : in  floating_point;
			output    : out floating_point;
			new_op    : in  std_logic;
			op_id_in  : in  request_id;
			op_id_out : out request_id;
			op_ready  : out std_logic
		);
	end component Floating_point_Adder;
	component Floating_point_Substractor is
		port(
			clk       : in  std_logic;
			opa       : in  floating_point;
			opb       : in  floating_point;
			output    : out floating_point;
			new_op    : in  std_logic;
			op_id_in  : in  request_id;
			op_id_out : out request_id;
			op_ready  : out std_logic
		);
	end component Floating_point_Substractor;
	component Floating_Point_Multiplier is
		port(clk       : in  std_logic;
			 opa       : in  floating_point;
			 opb       : in  floating_point;
			 output    : out floating_point;
			 new_op    : in  std_logic;
			 op_id_in  : in  request_id;
			 op_id_out : out request_id;
			 op_ready  : out std_logic);
	end component Floating_Point_Multiplier;
	component Floating_Point_Divider is
		port(clk       : in  std_logic;
			 opa       : in  floating_point;
			 opb       : in  floating_point;
			 output    : out floating_point;
			 new_op    : in  std_logic;
			 op_id_in  : in  request_id;
			 op_id_out : out request_id;
			 op_ready  : out std_logic);
	end component Floating_Point_Divider;
	component Floating_point_unit is
		port(
			clk              : in  std_logic;
			opa              : in  floating_point;
			opb              : in  floating_point;
			operation        : in  FPU_operation;
			output           : out floating_point;
			exceptions       : out FPU_exception;
			-- communicacion
			new_request      : in  std_logic;
			new_request_id   : in  request_id;
			request_ready    : out std_logic;
			request_ready_id : out request_id
		);
	end component Floating_point_unit;
end package Floating_point_component_pack;

package body Floating_point_component_pack is
end package body Floating_point_component_pack;
