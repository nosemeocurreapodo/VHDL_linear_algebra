library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Matrix_definitions_pack.all;

package Matrix_component_pack is
	
component Vector8_dot_fast is
	generic(
		IN_SIZE         : integer := 32;
		IN_FRAC_SIZE    : integer := 23;
		ADD_1_SIZE      : integer := 32;
		ADD_1_FRAC_SIZE : integer := 23;
		ADD_2_SIZE      : integer := 32;
		ADD_2_FRAC_SIZE : integer := 23;
		ADD_3_SIZE      : integer := 32;
		ADD_3_FRAC_SIZE : integer := 23;
		OUT_SIZE        : integer := 32;
		OUT_FRAC_SIZE   : integer := 23;
		AUX_SIZE        : integer := 32
	);
	port(
		clk           : in  std_logic;
		new_op        : in  std_logic;
		op_done       : out std_logic;
		aux_in        : in  std_logic_vector(AUX_SIZE - 1 downto 0);
		aux_out       : out std_logic_vector(AUX_SIZE - 1 downto 0);
		Vector1_input : in  Vector(7 downto 0)(IN_SIZE - 1 downto 0);
		Vector2_input : in  Vector(7 downto 0)(IN_SIZE -1 downto 0);
		output        : out std_logic_vector(OUT_SIZE - 1 downto 0)
	);
end component;

end package Matrix_component_pack;

package body Matrix_component_pack is
	
end package body Matrix_component_pack;
