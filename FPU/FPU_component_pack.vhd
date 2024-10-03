library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package FPU_component_pack is

	component FPU_Adder is
		generic(
			IN_SIZE       : integer := 32;
			IN_FRAC_SIZE  : integer := 23;
			OUT_SIZE      : integer := 32;
			OUT_FRAC_SIZE : integer := 23;
			AUX_SIZE      : integer := 32
		);
		port(
			clk       : in  std_logic;
			opa       : in  std_logic_vector(IN_SIZE - 1 downto 0);
			opb       : in  std_logic_vector(IN_SIZE - 1 downto 0);
			output    : out std_logic_vector(OUT_SIZE - 1 downto 0);
			new_op    : in  std_logic;
			aux_in    : in  std_logic_vector(AUX_SIZE - 1 downto 0);
			aux_out   : out std_logic_vector(AUX_SIZE - 1 downto 0);
			op_ready  : out std_logic
		);
	end component;

	component FPU_Substractor is
		generic(
			IN_SIZE       : integer := 32;
			IN_FRAC_SIZE  : integer := 23;
			OUT_SIZE      : integer := 32;
			OUT_FRAC_SIZE : integer := 23;
			AUX_SIZE      : integer := 32
		);
		port(
			clk       : in  std_logic;
			opa       : in  std_logic_vector(IN_SIZE - 1 downto 0);
			opb       : in  std_logic_vector(IN_SIZE - 1 downto 0);
			output    : out std_logic_vector(OUT_SIZE - 1 downto 0);
			new_op    : in  std_logic;
			aux_in    : in  std_logic_vector(AUX_SIZE - 1 downto 0);
			aux_out   : out std_logic_vector(AUX_SIZE - 1 downto 0);
			op_ready  : out std_logic
		);
	end component;

	component FPU_Multiplier is
		generic(
			IN_SIZE       : integer := 32;
			IN_FRAC_SIZE  : integer := 23;
			OUT_SIZE      : integer := 32;
			OUT_FRAC_SIZE : integer := 23;
			AUX_SIZE      : integer := 32
		);
		port(
			clk       : in  std_logic;
			opa       : in  std_logic_vector(IN_SIZE - 1 downto 0);
			opb       : in  std_logic_vector(IN_SIZE - 1 downto 0);
			output    : out std_logic_vector(OUT_SIZE - 1 downto 0);
			new_op    : in  std_logic;
			aux_in    : in  std_logic_vector(AUX_SIZE - 1 downto 0);
			aux_out   : out std_logic_vector(AUX_SIZE - 1 downto 0);
			op_ready  : out std_logic
		);
	end component;

	component FPU_Divider is
		generic(
			IN_SIZE       : integer := 32;
			IN_FRAC_SIZE  : integer := 23;
			OUT_SIZE      : integer := 32;
			OUT_FRAC_SIZE : integer := 23;
			AUX_SIZE      : integer := 32
		);
		port(
			clk       : in  std_logic;
			opa       : in  std_logic_vector(IN_SIZE - 1 downto 0);
			opb       : in  std_logic_vector(IN_SIZE - 1 downto 0);
			output    : out std_logic_vector(OUT_SIZE - 1 downto 0);
			new_op    : in  std_logic;
			aux_in    : in  std_logic_vector(AUX_SIZE - 1 downto 0);
			aux_out   : out std_logic_vector(AUX_SIZE - 1 downto 0);
			op_ready  : out std_logic
		);
	end component;
	
end package FPU_component_pack;

package body FPU_component_pack is
	
end package body FPU_component_pack;
