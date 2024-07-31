library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Fixed_point_definition.all;

entity Fixed_point_Substractor is
	port(
		clk       : in  std_logic;
		opa       : in  fixed_point;
		opb       : in  fixed_point;
		output    : out fixed_point;
		new_op    : in  std_logic;
		op_id_in  : in  request_id;
		op_id_out : out request_id;
				op_ready  : out std_logic
	);
end entity Fixed_point_Substractor;

architecture RTL of Fixed_point_Substractor is
	component Fixed_point_Adder is
		port(
			clk       : in  std_logic;
			opa       : in  fixed_point;
			opb       : in  fixed_point;
			output    : out fixed_point;
			new_op    : in  std_logic;
			op_id_in  : in  request_id;
			op_id_out : out request_id;
			op_ready  : out std_logic
		);
	end component Fixed_point_Adder;

	signal opb_negated : fixed_point;
begin

	opb_negated <= -opb;

	adder_int : Fixed_point_Adder port map(
		clk       => clk,
		opa       => opa,
		opb       => opb_negated,
		new_op    => new_op,
		op_id_in  => op_id_in,
		output    => output,
		op_id_out => op_id_out,
		op_ready  => op_ready);

end architecture RTL;
