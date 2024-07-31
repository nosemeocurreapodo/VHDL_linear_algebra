library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Fixed_point_definition.all;

entity Fixed_point_Adder is
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
end entity Fixed_point_Adder;

architecture RTL of Fixed_point_Adder is
	signal opa_1           : signed(fixed_point_size - 1 downto 0);
	signal opb_1           : signed(fixed_point_size - 1 downto 0);
	signal request_id_1    : request_id;
	signal new_operation_1 : std_logic;
begin
	process(clk)
	begin
		if (rising_edge(clk)) then
			-- stage 1
			opa_1 <= opa;
			opb_1 <= opb;
			if (new_op = '1') then
				request_id_1   <= op_id_in;
				new_operation_1 <= '1';
			else
				request_id_1   <= op_id_in;
				new_operation_1 <= '0';
			end if;

			-- stage 2
			output   <= opa_1 + opb_1;
			op_id_out <= request_id_1;
			op_ready  <= new_operation_1;
		end if;
	end process;
end architecture RTL;
