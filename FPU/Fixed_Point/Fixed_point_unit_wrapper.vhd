library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.request_id_pack.all;
use work.Fixed_point_definition.all;
use work.Fixed_point_component_pack.all;
use work.Fixed_point_unit_interface_pack.all;
use work.FPU_unit_common_pack.all;

entity Fixed_point_unit_wrapper is
	port(
		clk            : in std_logic;
		opa            : in std_logic_vector(31 downto 0);
		opb            : in std_logic_vector(31 downto 0);
		operation      : in std_logic_vector(2 downto 0);
		new_request    : in std_logic;
		request_ready  : out std_logic;
		output         : out std_logic_vector(31 downto 0);
	);
end entity;

architecture RTL2 of Fixed_point_unit_wrapper is

	component Fixed_point_unit is
		port(
			clk     : in  std_logic;
			BUS_in  : in  BUS_to_fixed_point_unit;
			BUS_out : out BUS_from_fixed_point_unit
		);
	end component;

	signal BUS_in : BUS_to_fixed_point_unit;
	signal BUS_out : BUS_from_fixed_point_unit;
begin

	FPU_slow_tb_INSTANTIATION : Fixed_point_unit port map(
			clk     => clk,
			BUS_in  => BUS_in,
			BUS_out => BUS_out);

	BUS_in.opa <= opa;
	BUS_in.opb <= opb;
	BUS_in.operation <= operation;
	BUS_in.rmode <= nearest_even;
	BUS_in.new_request <= new_request;
	BUS_in.new_request_id <= request_id_zero;

	request_ready <= BUS_out.request_ready;
	output <= BUS_out.output;

end architecture RTL2;

