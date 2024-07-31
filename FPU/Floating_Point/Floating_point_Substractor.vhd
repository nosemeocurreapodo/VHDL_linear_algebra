library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Floating_point_definition.all;
use work.FPU_utility_functions.all;

entity Floating_point_Substractor is
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
end entity Floating_point_Substractor;

architecture RTL of Floating_point_Substractor is

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

	signal opb_negated : floating_point;

begin

	opb_negated.sign <= not opb.sign;
	opb_negated.exponent <= opb.exponent;
	opb_negated.mantissa <= opb.mantissa;

	adder_int : Floating_point_Adder port map(
		clk       => clk,
		opa       => opa,
		opb       => opb_negated,
		new_op    => new_op,
		op_id_in  => op_id_in,
		output    => output,
		op_id_out => op_id_out,
		op_ready  => op_ready);

end architecture RTL;