library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Floating_point_Substractor is
	generic(
		IN_SIZE           : integer := 32;
		IN_MANTISSA_SIZE  : integer := 23;
		OUT_SIZE          : integer := 32;
		OUT_MANTISSA_SIZE : integer := 23;
		AUX_SIZE          : integer := 32
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
end entity Floating_point_Substractor;

architecture RTL of Floating_point_Substractor is

	component Floating_point_Adder is
		generic(
			IN_SIZE           : integer := 32;
			IN_MANTISSA_SIZE  : integer := 23;
			OUT_SIZE          : integer := 32;
			OUT_MANTISSA_SIZE : integer := 23;
			AUX_SIZE          : integer := 32
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
	end component Floating_point_Adder;

	signal opb_negated : std_logic_vector(IN_SIZE - 1 downto 0);

begin

	opb_negated(IN_SIZE - 1)          <= not opb(IN_SIZE - 1);
	opb_negated(IN_SIZE - 2 downto 0) <= opb(IN_SIZE - 2 downto 0);

	adder_int : Floating_point_Adder 
	generic map (
		IN_SIZE	          => IN_SIZE,
		IN_MANTISSA_SIZE  => IN_MANTISSA_SIZE,
		OUT_SIZE	      => OUT_SIZE,
		OUT_MANTISSA_SIZE => OUT_MANTISSA_SIZE
	)
	port map(
		clk      => clk,
		opa      => opa,
		opb      => opb_negated,
		output   => output,
		new_op   => new_op,
		aux_in   => aux_in,
		aux_out  => aux_out,
		op_ready => op_ready);

end architecture RTL;