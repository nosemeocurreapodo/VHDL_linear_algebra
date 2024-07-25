library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Fixed_point_definition.all;
use work.FPU_utility_functions.all;
use work.Synthesis_definitions_pack.all;

entity Fixed_point_Multiplier is
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
end entity Fixed_point_Multiplier;

--architecture RTL of My_Fixed_point_Multiplier is
--	constant number_of_stages : integer := 2;
--	type output_pipelined is array (number_of_stages - 1 downto 0) of fixed_point;
--	signal output_pipelined_reg : output_pipelined;
--	type request_id_pipelined is array (number_of_stages - 1 downto 0) of request_id;
--	signal request_id_pipelined_reg    : request_id_pipelined;
--	signal new_operation_pipelined_reg : std_logic_vector(number_of_stages - 1 downto 0) := std_logic_vector(to_unsigned(0, number_of_stages));
--begin
--	process(clk)
--		variable output_aux : signed(fixed_point_size * 2 - 1 downto 0);
--	begin
--		if (rising_edge(clk)) then
--			output    <= output_pipelined_reg(number_of_stages - 1);
--			op_id_out <= request_id_pipelined_reg(number_of_stages - 1);
--			op_ready  <= new_operation_pipelined_reg(number_of_stages - 1);
--			if (new_op = '1') then
--				output_aux                     := opa * opb;
--				output_pipelined_reg(0)        <= output_aux(fixed_point_size+fixed_point_fraction_size - 1 downto fixed_point_fraction_size);
--				request_id_pipelined_reg(0)    <= op_id_in;
--				new_operation_pipelined_reg(0) <= '1';
--			else
--				output_pipelined_reg(0)        <= to_signed(0, fixed_point_size);
--				request_id_pipelined_reg(0)    <= to_signed(0, request_id_size);
--				new_operation_pipelined_reg(0) <= '0';
--			end if;
--
--			for I in number_of_stages - 1 downto 1 loop
--				output_pipelined_reg(I)        <= output_pipelined_reg(I - 1);
--				request_id_pipelined_reg(I)    <= request_id_pipelined_reg(I - 1);
--				new_operation_pipelined_reg(I) <= new_operation_pipelined_reg(I - 1);
--			end loop;
--		end if;
--	end process;
--end architecture RTL;

architecture RTL of Fixed_point_Multiplier is
	-- LATENCIA = 5 clks
	constant number_of_stages : integer := 5;
	--type output_pipelined is array (number_of_stages - 1 downto 0) of fixed_point;
	--signal output_pipelined_reg : output_pipelined;
	type request_id_pipelined is array (number_of_stages - 1 downto 0) of request_id;
	signal request_id_pipelined_reg    : request_id_pipelined;
	signal new_operation_pipelined_reg : std_logic_vector(number_of_stages - 1 downto 0) := std_logic_vector(to_unsigned(0, number_of_stages));

	signal output_sign     : std_logic_vector(number_of_stages - 1 downto 0);
	signal operator_a_up   : unsigned(maximum_multiplier_width - 1 downto 0);
	signal operator_a_down : unsigned(maximum_multiplier_width - 1 downto 0);
	signal operator_b_up   : unsigned(maximum_multiplier_width - 1 downto 0);
	signal operator_b_down : unsigned(maximum_multiplier_width - 1 downto 0);

	signal a_downXb_down : unsigned(maximum_multiplier_width * 2 - 1 downto 0);
	signal a_upXb_down   : unsigned(maximum_multiplier_width * 2 - 1 downto 0);
	signal a_downXb_up   : unsigned(maximum_multiplier_width * 2 - 1 downto 0);
	signal a_upXb_up     : unsigned(maximum_multiplier_width * 2 - 1 downto 0);

	signal sum1 : unsigned(maximum_multiplier_width * 4 - 1 downto 0);
	signal sum2 : unsigned(maximum_multiplier_width * 4 - 1 downto 0);
	signal sum3 : unsigned(maximum_multiplier_width * 4 - 1 downto 0);

begin
	process(clk)
		variable opa_abs : unsigned(fixed_point_size - 1 downto 0);
		variable opb_abs : unsigned(fixed_point_size - 1 downto 0);
	begin
		if (rising_edge(clk)) then
			-- 1 stage
			if (new_op = '1') then
				if (opa >= 0 and opb >= 0) then
					output_sign(0) <= '0';
				elsif (opa >= 0 and opb < 0) then
					output_sign(0) <= '1';
				elsif (opa < 0 and opb >= 0) then
					output_sign(0) <= '1';
				else
					output_sign(0) <= '0';
				end if;

				opa_abs := unsigned(abs (opa));
				opb_abs := unsigned(abs (opb));

				operator_a_up   <= unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width - fixed_point_size + maximum_multiplier_width)) & std_logic_vector(opa_abs(fixed_point_size - 1 downto maximum_multiplier_width)));
				operator_a_down <= opa_abs(maximum_multiplier_width - 1 downto 0);
				operator_b_up   <= unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width - fixed_point_size + maximum_multiplier_width)) & std_logic_vector(opb_abs(fixed_point_size - 1 downto maximum_multiplier_width)));
				operator_b_down <= opb_abs(maximum_multiplier_width - 1 downto 0);

				request_id_pipelined_reg(0)    <= op_id_in;
				new_operation_pipelined_reg(0) <= '1';
			else
				request_id_pipelined_reg(0)    <= to_signed(0, request_id_size);
				new_operation_pipelined_reg(0) <= '0';
			end if;

			-- 2 stage
			output_sign(1) <= output_sign(0);

			a_downXb_down <= operator_a_down * operator_b_down;
			a_upXb_down   <= operator_a_up * operator_b_down;
			a_downXb_up   <= operator_a_down * operator_b_up;
			a_upXb_up     <= operator_a_up * operator_b_up;

			request_id_pipelined_reg(1)    <= request_id_pipelined_reg(0);
			new_operation_pipelined_reg(1) <= new_operation_pipelined_reg(0);
			-- 3 stage
			output_sign(2)                 <= output_sign(1);
			sum1                           <= unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width)) & std_logic_vector(a_upXb_down) & std_logic_vector(to_unsigned(0, maximum_multiplier_width))) + unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width * 2)) & std_logic_vector(a_downXb_down));
			request_id_pipelined_reg(2)    <= request_id_pipelined_reg(1);
			new_operation_pipelined_reg(2) <= new_operation_pipelined_reg(1);
			-- 4 stage
			output_sign(3)                 <= output_sign(2);
			sum2                           <= sum1 + unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width)) & std_logic_vector(a_downXb_up) & std_logic_vector(to_unsigned(0, maximum_multiplier_width)));
			request_id_pipelined_reg(3)    <= request_id_pipelined_reg(2);
			new_operation_pipelined_reg(3) <= new_operation_pipelined_reg(2);
			-- 5 stage
			output_sign(4)                 <= output_sign(3);
			sum3                           <= sum2 + unsigned(std_logic_vector(a_upXb_up) & std_logic_vector(to_unsigned(0, maximum_multiplier_width * 2)));
			request_id_pipelined_reg(4)    <= request_id_pipelined_reg(3);
			new_operation_pipelined_reg(4) <= new_operation_pipelined_reg(3);
			-- 6 stage

			if (output_sign(4) = '0') then
				output <= signed(sum3(fixed_point_size + fraction_size - 1 downto fraction_size));
			else
				output <= -signed(sum3(fixed_point_size + fraction_size - 1 downto fraction_size));
			end if;

			op_id_out <= request_id_pipelined_reg(4);
			op_ready  <= new_operation_pipelined_reg(4);

		end if;
	end process;
end architecture RTL;
