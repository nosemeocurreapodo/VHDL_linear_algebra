library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.FPU_definitions_pack.all;

package Matrix_definition_pack is

	-- tipos especificos de el paquete de operaciones con matrices
	type Matrix3x3 is array (8 downto 0) of scalar;
	type Vector8 is array (7 downto 0) of scalar;
	type Vector3 is array (2 downto 0) of scalar;
	type Vector2 is array (1 downto 0) of scalar;
	
	type Matrix3x3_Array is array (integer range<>) of Matrix3x3;
	type Vector3_Array is array (integer range<>) of Vector3;
	type Vector2_Array is array (integer range<>) of Vector2;
	
end package Matrix_definition_pack;
