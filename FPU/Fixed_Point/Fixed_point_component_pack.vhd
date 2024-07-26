library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Fixed_point_definition.all;
use work.request_id_pack.all;

package Fixed_point_component_pack is
	component Fixed_point_Adder is
		port(
			clk       : in  std_logic;
			opa       : in  fixed_point;
			opb       : in  fixed_point;
			output    : out fixed_point;
			new_op    : in  std_logic;
			op_id_in  : in  request_id;
			op_id_out : out request_id;
			op_ready  : out std_logic
		);
	end component Fixed_point_Adder;

	component Fixed_point_Substractor is
		port(
			clk       : in  std_logic;
			opa       : in  fixed_point;
			opb       : in  fixed_point;
			output    : out fixed_point;
			new_op    : in  std_logic;
			op_id_in  : in  request_id;
			op_id_out : out request_id;
			op_ready  : out std_logic
		);
	end component Fixed_point_Substractor;

	component Fixed_point_Multiplier is
		port(
			clk       : in  std_logic;
			opa       : in  fixed_point;
			opb       : in  fixed_point;
			output    : out fixed_point;
			new_op    : in  std_logic;
			op_id_in  : in  request_id;
			op_id_out : out request_id;
			op_ready  : out std_logic
		);
	end component Fixed_point_Multiplier;

	component Fixed_point_Divider is
		port(
			clk       : in  std_logic;
			opa       : in  fixed_point;
			opb       : in  fixed_point;
			output    : out fixed_point;
			new_op    : in  std_logic;
			op_id_in  : in  request_id;
			op_id_out : out request_id;
			op_ready  : out std_logic
		);
	end component Fixed_point_Divider;

end package Fixed_point_component_pack;

package body Fixed_point_component_pack is
end package body Fixed_point_component_pack;
