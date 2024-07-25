library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.FPU_definitions_pack.all;
use work.request_id_pack.all;

package FPU_component_pack is
	component FPU_Adder is
	port(
		clk       : in  std_logic;
		opa       : in  scalar;
		opb       : in  scalar;
		output    : out scalar;
		new_op    : in  std_logic;
		op_id_in  : in  request_id;
		op_id_out : out request_id;
		op_ready  : out std_logic
	);
end component FPU_Adder;
component FPU_Substractor is
	port(
		clk       : in  std_logic;
		opa       : in  scalar;
		opb       : in  scalar;
		output    : out scalar;
		new_op    : in  std_logic;
		op_id_in  : in  request_id;
		op_id_out : out request_id;
		op_ready  : out std_logic
	);
end component FPU_Substractor;
component FPU_Multiplier is
	port(
		clk       : in  std_logic;
		opa       : in  scalar;
		opb       : in  scalar;
		output    : out scalar;
		new_op    : in  std_logic;
		op_id_in  : in  request_id;
		op_id_out : out request_id;
		op_ready  : out std_logic
	);
end component FPU_Multiplier;
component FPU_Divider is
	port(
		clk       : in  std_logic;
		opa       : in  scalar;
		opb       : in  scalar;
		output    : out scalar;
		new_op    : in  std_logic;
		op_id_in  : in  request_id;
		op_id_out : out request_id;
		op_ready  : out std_logic
	);
end component FPU_Divider;
end package FPU_component_pack;

package body FPU_component_pack is
	
end package body FPU_component_pack;
