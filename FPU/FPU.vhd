library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.FPU_definitions_pack.all;
use work.My_Fixed_point_definition.all;
use work.My_Floating_point_definition.all;
use work.My_Fixed_point_component_pack.all;
use work.My_Floating_point_component_pack.all;
use work.request_id_pack.all;

entity FPU_Adder is
	port(
		clk       : in  std_logic;
		opa       : in  scalar;
		opb       : in  scalar;
		output    : out scalar;
		new_op    : in  std_logic;
		op_id_in  : in  request_id;
		op_id_out : out request_id;
		op_ready  : out std_logic
	);
end entity FPU_Adder;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.FPU_definitions_pack.all;
use work.My_Fixed_point_definition.all;
use work.My_Floating_point_definition.all;
use work.My_Fixed_point_component_pack.all;
use work.My_Floating_point_component_pack.all;
use work.request_id_pack.all;

entity FPU_Substractor is
	port(
		clk       : in  std_logic;
		opa       : in  scalar;
		opb       : in  scalar;
		output    : out scalar;
		new_op    : in  std_logic;
		op_id_in  : in  request_id;
		op_id_out : out request_id;
		op_ready  : out std_logic
	);
end entity FPU_Substractor;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.FPU_wrapper_definitions_pack.all;
use work.My_Fixed_point_definition.all;
use work.My_Floating_point_definition.all;
use work.My_Fixed_point_component_pack.all;
use work.My_Floating_point_component_pack.all;
use work.request_id_pack.all;

entity FPU_Multiplier is
	port(
		clk       : in  std_logic;
		opa       : in  scalar;
		opb       : in  scalar;
		output    : out scalar;
		new_op    : in  std_logic;
		op_id_in  : in  request_id;
		op_id_out : out request_id;
		op_ready  : out std_logic
	);
end entity FPU_Multiplier;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.FPU_wrapper_definitions_pack.all;
use work.My_Fixed_point_definition.all;
use work.My_Floating_point_definition.all;
use work.My_Fixed_point_component_pack.all;
use work.My_Floating_point_component_pack.all;
use work.request_id_pack.all;

entity FPU_Divider is
	port(
		clk       : in  std_logic;
		opa       : in  scalar;
		opb       : in  scalar;
		output    : out scalar;
		new_op    : in  std_logic;
		op_id_in  : in  request_id;
		op_id_out : out request_id;
		op_ready  : out std_logic
	);
end entity FPU_Divider;

architecture RTL of FPU_Adder is
	
begin
	adder_int : Fixed_point_Adder port map(
			clk       => clk,
			opa       => opa,
			opb       => opb,
			new_op    => new_op,
			op_id_in  => op_id_in,
			output    => output,
			op_id_out => op_id_out,
			op_ready  => op_ready);

end architecture RTL;

architecture RTL of FPU_Substractor is
	
begin
	adder_int : Fixed_point_Substractor port map(
			clk       => clk,
			opa       => opa,
			opb       => opb,
			new_op    => new_op,
			op_id_in  => op_id_in,
			output    => output,
			op_id_out => op_id_out,
			op_ready  => op_ready);

end architecture RTL;

architecture RTL of FPU_Multiplier is
	
begin
	adder_int : Fixed_point_Multiplier port map(
			clk       => clk,
			opa       => opa,
			opb       => opb,
			new_op    => new_op,
			op_id_in  => op_id_in,
			output    => output,
			op_id_out => op_id_out,
			op_ready  => op_ready);

end architecture RTL;

architecture RTL of FPU_Divider is
	
begin
	adder_int : Fixed_point_Divider port map(
			clk       => clk,
			opa       => opa,
			opb       => opb,
			new_op    => new_op,
			op_id_in  => op_id_in,
			output    => output,
			op_id_out => op_id_out,
			op_ready  => op_ready);

end architecture RTL;

--architecture RTL of FPU_Adder is
--	
--begin
--	adder_int : Floating_point_Adder port map(
--			clk       => clk,
--			opa       => opa,
--			opb       => opb,
--			new_op    => new_op,
--			op_id_in  => op_id_in,
--			output    => output,
--			op_id_out => op_id_out,
--			op_ready  => op_ready);
--
--end architecture RTL;
--
--architecture RTL of FPU_Substractor is
--	
--begin
--	adder_int : Floating_point_Substractor port map(
--			clk       => clk,
--			opa       => opa,
--			opb       => opb,
--			new_op    => new_op,
--			op_id_in  => op_id_in,
--			output    => output,
--			op_id_out => op_id_out,
--			op_ready  => op_ready);
--
--end architecture RTL;
--
--architecture RTL of FPU_Multiplier is
--	
--begin
--	adder_int : Floating_point_Multiplier port map(
--			clk       => clk,
--			opa       => opa,
--			opb       => opb,
--			new_op    => new_op,
--			op_id_in  => op_id_in,
--			output    => output,
--			op_id_out => op_id_out,
--			op_ready  => op_ready);
--
--end architecture RTL;
--
--architecture RTL of FPU_Divider is
--	
--begin
--	adder_int : Floating_point_Divider port map(
--			clk       => clk,
--			opa       => opa,
--			opb       => opb,
--			new_op    => new_op,
--			op_id_in  => op_id_in,
--			output    => output,
--			op_id_out => op_id_out,
--			op_ready  => op_ready);
--
--end architecture RTL;


