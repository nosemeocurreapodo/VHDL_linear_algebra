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
	constant number_of_stages : integer := 1;
	type output_pipelined is array (number_of_stages - 1 downto 0) of fixed_point;
	signal output_pipelined_reg : output_pipelined;
	type request_id_pipelined is array (number_of_stages - 1 downto 0) of request_id;
	signal request_id_pipelined_reg    : request_id_pipelined;
	signal new_operation_pipelined_reg : std_logic_vector(number_of_stages - 1 downto 0) := std_logic_vector(to_unsigned(0, number_of_stages));
begin
	process(clk)
		variable output_aux : signed(fixed_point_size - 1 downto 0);
	begin
		if (rising_edge(clk)) then
			output    <= output_pipelined_reg(number_of_stages - 1);
			op_id_out <= request_id_pipelined_reg(number_of_stages - 1);
			op_ready  <= new_operation_pipelined_reg(number_of_stages - 1);
			if (new_op = '1') then
				output_aux := opa + opb;
				output_pipelined_reg(0)        <= output_aux;
				request_id_pipelined_reg(0)    <= op_id_in;
				new_operation_pipelined_reg(0) <= '1';
			else
				output_pipelined_reg(0)        <= to_signed(0, fixed_point_size);
				request_id_pipelined_reg(0)    <= to_signed(0, request_id_size);
				new_operation_pipelined_reg(0) <= '0';
			end if;
		end if;
	end process;
end architecture RTL;
