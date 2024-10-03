library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Matrix_component_pack is
	
component Vector8_dot_fast is
	generic(
		IN_SIZE       : integer := 32;
		IN_FRAC_SIZE  : integer := 23;
		OUT_SIZE      : integer := 32;
		OUT_FRAC_SIZE : integer := 23;
		AUX_SIZE      : integer := 32
	);
	port(
		clk           : in  std_logic;
		new_op_in     : in  std_logic;
		aux_in        : in  std_logic_vector(AUX_SIZE - 1 downto 0);
		new_op_out    : out std_logic;
		aux_out       : out std_logic_vector(AUX_SIZE - 1 downto 0);
		Vector1_input : in  std_logic_vector(IN_SIZE*8 - 1 downto 0);
		Vector2_input : in  std_logic_vector(IN_SIZE*8 -1 downto 0);
		output        : out std_logic_vector(OUT_SIZE - 1 downto 0);
	);
end component;

component Vector8_convolution_fast is
	port(
		clk                      : in  std_logic;
		new_operation_request    : in  std_logic;
		new_operation_done       : out std_logic;
		input                    : in  scalar;
		output                   : out scalar
	);
end component;

end package Matrix_component_pack;

package body Matrix_component_pack is
	
end package body Matrix_component_pack;
