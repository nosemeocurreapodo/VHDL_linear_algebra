library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Matrix_definitions_pack is

	-- tipos especificos de el paquete de operaciones con matrices
	--type Matrix3x3 is array (8 downto 0) of scalar;
	--type Vector is array (integer range<>) of scalar;
	
	type Vector is array (integer range<>) of std_logic_vector;

	--type Matrix3x3_Array is array (integer range<>) of Matrix3x3;
	--type Vector3_Array is array (integer range<>) of Vector3;
	--type Vector2_Array is array (integer range<>) of Vector2;
	
end package Matrix_definitions_pack;
