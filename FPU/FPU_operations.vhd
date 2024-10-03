library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Fixed_point_component_pack.all;
use work.Floating_point_component_pack.all;

entity FPU_Adder is
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
end entity;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Fixed_point_component_pack.all;
use work.Floating_point_component_pack.all;

entity FPU_Substractor is
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
end entity;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Fixed_point_component_pack.all;
use work.Floating_point_component_pack.all;

entity FPU_Multiplier is
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
end entity;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Fixed_point_component_pack.all;
use work.Floating_point_component_pack.all;

entity FPU_Divider is
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
end entity;

--architecture RTL of FPU_Adder is
	
--begin
--	adder_inst : Fixed_point_Adder port map(
--	generic map(
--		IN_SIZE            => IN_SIZE,
--		OUT_SIZE           => OUT_SIZE,
--		AUX_SIZE           => AUX_SIZE)
--	port map(
--			clk       => clk,
--			opa       => opa,
--			opb       => opb,
--			output    => output,
--			new_op    => new_op,
--			aux_in    => aux_in,
--			aux_out   => aux_out,
--			op_ready  => op_ready);

--end architecture RTL;

--architecture RTL of FPU_Substractor is
	
--begin
--	subs_inst : Fixed_point_Substractor port map(
--	generic map(
--		IN_SIZE            => IN_SIZE,
--		OUT_SIZE           => OUT_SIZE,
--		AUX_SIZE           => AUX_SIZE)
--	port map(
--			clk       => clk,
--			opa       => opa,
--			opb       => opb,
--			output    => output,
--			new_op    => new_op,
--			aux_in    => aux_in,
--			aux_out   => aux_out,
--			op_ready  => op_ready);

--end architecture RTL;

--architecture RTL of FPU_Multiplier is
	
--begin
--	mult_inst : Fixed_point_Multiplier port map(
--	generic map(
--		IN_SIZE        => IN_SIZE,
--		IN_FRAC_SIZE   => IN_FRAC_SIZE,
--		OUT_SIZE       => OUT_SIZE,
--		OUT_FRAC_SIZE  => OUT_FRAC_SIZE,
--		AUX_SIZE       => AUX_SIZE)
--	port map(
--			clk       => clk,
--			opa       => opa,
--			opb       => opb,
--			output    => output,
--			new_op    => new_op,
--			aux_in    => aux_in,
--			aux_out   => aux_out,
--			op_ready  => op_ready);

--end architecture RTL;

--architecture RTL of FPU_Divider is
	
--begin
--	divi_inst : Fixed_point_Divider port map(
--	generic map(
--		IN_SIZE        => IN_SIZE,
--		IN_FRAC_SIZE   => IN_FRAC_SIZE,
--		OUT_SIZE       => OUT_SIZE,
--		OUT_FRAC_SIZE  => OUT_FRAC_SIZE,
--		AUX_SIZE       => AUX_SIZE)
--	port map(
--			clk       => clk,
--			opa       => opa,
--			opb       => opb,
--			output    => output,
--			new_op    => new_op,
--			aux_in    => aux_in,
--			aux_out   => aux_out,
--			op_ready  => op_ready);

--end architecture RTL;



architecture RTL of FPU_Adder is
	
begin
	adder_inst : Floating_point_Adder 
	generic map(
		IN_SIZE            => IN_SIZE,
		IN_MANTISSA_SIZE   => IN_FRAC_SIZE,
		OUT_SIZE           => OUT_SIZE,
		OUT_MANTISSA_SIZE  => OUT_FRAC_SIZE,
		AUX_SIZE           => AUX_SIZE)
	port map(
			clk       => clk,
			opa       => opa,
			opb       => opb,
			output    => output,
			new_op    => new_op,
			aux_in    => aux_in,
			aux_out   => aux_out,
			op_ready  => op_ready);

end architecture RTL;

architecture RTL of FPU_Substractor is
	
begin
	subs_inst : Floating_point_Substractor
		generic map(
			IN_SIZE            => IN_SIZE,
			IN_MANTISSA_SIZE   => IN_FRAC_SIZE,
			OUT_SIZE           => OUT_SIZE,
			OUT_MANTISSA_SIZE  => OUT_FRAC_SIZE,
			AUX_SIZE           => AUX_SIZE)
		port map(
				clk       => clk,
				opa       => opa,
				opb       => opb,
				output    => output,
				new_op    => new_op,
				aux_in    => aux_in,
				aux_out   => aux_out,
				op_ready  => op_ready);

end architecture RTL;

architecture RTL of FPU_Multiplier is
	
begin
	mult_inst : Floating_point_Multiplier
		generic map(
			IN_SIZE            => IN_SIZE,
			IN_MANTISSA_SIZE   => IN_FRAC_SIZE,
			OUT_SIZE           => OUT_SIZE,
			OUT_MANTISSA_SIZE  => OUT_FRAC_SIZE,
			AUX_SIZE           => AUX_SIZE)
		port map(
				clk       => clk,
				opa       => opa,
				opb       => opb,
				output    => output,
				new_op    => new_op,
				aux_in    => aux_in,
				aux_out   => aux_out,
				op_ready  => op_ready);

end architecture RTL;

architecture RTL of FPU_Divider is
	
begin
	divi_inst : Floating_point_Divider
		generic map(
			IN_SIZE            => IN_SIZE,
			IN_MANTISSA_SIZE   => IN_FRAC_SIZE,
			OUT_SIZE           => OUT_SIZE,
			OUT_MANTISSA_SIZE  => OUT_FRAC_SIZE,
			AUX_SIZE           => AUX_SIZE)
		port map(
				clk       => clk,
				opa       => opa,
				opb       => opb,
				output    => output,
				new_op    => new_op,
				aux_in    => aux_in,
				aux_out   => aux_out,
				op_ready  => op_ready);

end architecture RTL;


