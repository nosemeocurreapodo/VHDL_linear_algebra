library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Floating_point_definition.all;
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

end package Floating_point_component_pack;

package body Floating_point_component_pack is
end package body Floating_point_component_pack;
