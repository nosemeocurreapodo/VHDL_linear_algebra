library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.request_id_pack.all;
use work.Matrix_definition_pack.all;

package Matrix_component_pack is

component Matrix3x3_VMultiplier_fast is
	port(
		clk                      : in  std_logic;
		new_operation_request    : in  std_logic;
		new_operation_request_id : in  request_id;
		new_operation_done       : out std_logic;
		new_operation_done_id    : out request_id;
		Matrix_input             : in  Matrix3x3;
		Vector_input             : in  Vector3;
		Vector_output            : out Vector3
	);
end component Matrix3x3_VMultiplier_fast;
	
component Vector8_dot_fast is
	port(
		clk                      : in  std_logic;
		new_operation_request    : in  std_logic;
		new_operation_request_id : in  request_id;
		new_operation_done       : out std_logic;
		new_operation_done_id    : out request_id;
		Vector1_input            : in  Vector8;
		Vector2_input            : in  Vector8;
		output                   : out scalar
	);
end component Vector8_dot_fast;

end package Matrix_component_pack;

package body Matrix_component_pack is
	
end package body Matrix_component_pack;
