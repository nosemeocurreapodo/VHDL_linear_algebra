library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Fixed_point_definition.all;
use work.FPU_utility_functions.all;

entity Fixed_point_Divider is
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
end entity Fixed_point_Divider;

--architecture RTL of My_Fixed_point_Divider is
--	constant number_of_stages : integer := 2;
--	type output_pipelined is array (number_of_stages - 1 downto 0) of fixed_point;
--	signal output_pipelined_reg : output_pipelined;
--	type request_id_pipelined is array (number_of_stages - 1 downto 0) of request_id;
--	signal request_id_pipelined_reg    : request_id_pipelined;
--	signal new_operation_pipelined_reg : std_logic_vector(number_of_stages - 1 downto 0) := std_logic_vector(to_unsigned(0, number_of_stages));
--begin
--	process(clk)
--		-- para dividir, lo que voy a hacer correr el opa 32 lugares a la izquierda
--		-- esto va a hacer que opa sea estrictamente mayor que opb
--		-- divido normal, y luego el resultado lo corro 32 lugares a la derecha
--		variable opa_aux    : signed(fixed_point_size * 2 - 1 downto 0):= to_signed(0, fixed_point_size*2);
--		variable opb_aux : signed(fixed_point_size * 2 - 1 downto 0):= to_signed(0, fixed_point_size*2);
--		variable output_aux : signed(fixed_point_size * 2 - 1 downto 0);
--	begin
--		if (rising_edge(clk)) then
--			output    <= output_pipelined_reg(number_of_stages - 1);
--			op_id_out <= request_id_pipelined_reg(number_of_stages - 1);
--			op_ready  <= new_operation_pipelined_reg(number_of_stages - 1);
--			if (new_op = '1') then
--				if (opb = to_signed(0, fixed_point_size)) then
--					output_pipelined_reg(0)        <= to_signed(0, fixed_point_size);
--					request_id_pipelined_reg(0)    <= to_signed(0, request_id_size);
--					new_operation_pipelined_reg(0) <= '1';
--				else
--					opa_aux(fixed_point_size-1 downto 0) := to_signed(0, fixed_point_size);
--					opa_aux(fixed_point_size*2-1 downto fixed_point_size) := opa;
--					opb_aux(fixed_point_size-1 downto 0):= opb;
--					output_aux := opa_aux / opb_aux;
--					output_pipelined_reg(0)        <= output_aux(fixed_point_size*2-fixed_point_fraction_size-1 downto fixed_point_size-fixed_point_fraction_size);
--					request_id_pipelined_reg(0)    <= op_id_in;
--					new_operation_pipelined_reg(0) <= '1';
--				end if;
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


architecture RTL of Fixed_point_Divider is
	constant number_of_stages : integer := fixed_point_size+2; --fixed_point_size+2;
	type output_pipelined is array (number_of_stages - 1 downto 0) of unsigned(fixed_point_size - 1 downto 0);
	signal output_pipelined_reg      : output_pipelined;
	signal output_sign_pipelined_reg : std_logic_vector(number_of_stages - 1 downto 0);
	signal dividend_pipelined_reg    : output_pipelined;
	signal divisor_pipelined_reg     : output_pipelined;
	type request_id_pipelined is array (number_of_stages - 1 downto 0) of request_id;
	signal request_id_pipelined_reg    : request_id_pipelined;
	signal new_operation_pipelined_reg : std_logic_vector(number_of_stages - 1 downto 0) := std_logic_vector(to_unsigned(0, number_of_stages));
	type exponent_difference_pipelined is array (number_of_stages - 1 downto 0) of signed(fixed_point_size - 1 downto 0);
	signal exponent_differente_pipelined_reg : exponent_difference_pipelined;

	signal dividend_slv_reg : std_logic_vector(fixed_point_size - 1 downto 0);
	signal divisor_slv_reg  : std_logic_vector(fixed_point_size - 1 downto 0);
begin
	process(clk)
		variable sub_pipelined_reg        : output_pipelined;
		variable output_aux_pipelined_reg : output_pipelined;
		variable opa_power                : integer := 0;
		variable opb_power                : integer := 0;
		variable output_shift             : integer := 0;
	begin
		if (rising_edge(clk)) then
			-- 0 stage
			if (new_op = '1') then
				if (opb = to_signed(0, fixed_point_size)) then
					dividend_pipelined_reg(0)            <= to_unsigned(0, fixed_point_size);
					divisor_pipelined_reg(0)             <= to_unsigned(1, fixed_point_size);
					output_pipelined_reg(0)              <= to_unsigned(0, fixed_point_size);
					if(opa >= 0) then
						output_sign_pipelined_reg(0)         <= '0';
					else
						output_sign_pipelined_reg(0)         <= '0';
					end if;
					exponent_differente_pipelined_reg(0) <= to_signed(0, fixed_point_size);
					request_id_pipelined_reg(0)          <= op_id_in;
					new_operation_pipelined_reg(0)       <= '1';
				else
					dividend_pipelined_reg(0) <= unsigned(abs (opa));
					divisor_pipelined_reg(0)  <= unsigned(abs (opb));
					output_pipelined_reg(0)   <= to_unsigned(0, fixed_point_size);
					if (opa < 0 and opb < 0) then
						output_sign_pipelined_reg(0) <= '0';
					elsif (opa < 0 or opb < 0) then
						output_sign_pipelined_reg(0) <= '1';
					else
						output_sign_pipelined_reg(0) <= '0';
					end if;
					exponent_differente_pipelined_reg(0) <= to_signed(0, fixed_point_size);
					request_id_pipelined_reg(0)          <= op_id_in;
					new_operation_pipelined_reg(0)       <= '1';

					dividend_slv_reg <= std_logic_vector(abs(opa));
					divisor_slv_reg  <= std_logic_vector(abs(opb));

				end if;
			else
				dividend_pipelined_reg(0)            <= to_unsigned(0, fixed_point_size);
				divisor_pipelined_reg(0)             <= to_unsigned(0, fixed_point_size);
				output_pipelined_reg(0)              <= to_unsigned(0, fixed_point_size);
				output_sign_pipelined_reg(0)         <= '0';
				exponent_differente_pipelined_reg(0) <= to_signed(0, fixed_point_size);
				request_id_pipelined_reg(0)          <= to_signed(0, request_id_size);
				new_operation_pipelined_reg(0)       <= '0';
			end if;

			-- stage 1 

			opa_power := count_l_zeros(dividend_slv_reg);
			opb_power := count_l_zeros(divisor_slv_reg);
			if (opa_power > 0) then
				opa_power := opa_power - 1;
			end if;
			if (opb_power > 0) then
				opb_power := opb_power - 1;
			end if;

			--dividend_pipelined_reg(1)            <= signed(std_logic_vector(dividend_pipelined_reg(0)(fixed_point_size - opa_zeros - 1 downto 0)) & std_logic_vector(dividend_pipelined_reg(0)(fixed_point_size - 1 downto opa_zeros)));
			--divisor_pipelined_reg(1)             <= signed(std_logic_vector(divisor_pipelined_reg(0)(fixed_point_size - opb_zeros - 1 downto 0)) & std_logic_vector(divisor_pipelined_reg(0)(fixed_point_size - 1 downto opb_zeros)));
			dividend_pipelined_reg(1)            <= shift_left(dividend_pipelined_reg(0), opa_power);
			divisor_pipelined_reg(1)             <= shift_left(divisor_pipelined_reg(0), opb_power);
			--dividend_pipelined_reg(1)            <= dividend_pipelined_reg(0);
			--divisor_pipelined_reg(1)             <= divisor_pipelined_reg(0);
			output_pipelined_reg(1)              <= output_pipelined_reg(0);
			output_sign_pipelined_reg(1)         <= output_sign_pipelined_reg(0);
			exponent_differente_pipelined_reg(1) <= to_signed(opa_power - opb_power, fixed_point_size);
			request_id_pipelined_reg(1)          <= request_id_pipelined_reg(0);
			new_operation_pipelined_reg(1)       <= new_operation_pipelined_reg(0);

			-- stage 2 - 34

			for I in fixed_point_size + 1 downto 2 loop
				if (dividend_pipelined_reg(I - 1) < divisor_pipelined_reg(I - 1)) then
					output_aux_pipelined_reg(I - 1)                                 := output_pipelined_reg(I - 1);
					output_aux_pipelined_reg(I - 1)(fixed_point_size - 1 - (I - 2)) := '0';
					output_pipelined_reg(I)                                         <= output_aux_pipelined_reg(I - 1);
					dividend_pipelined_reg(I)                                       <= unsigned(std_logic_vector(dividend_pipelined_reg(I - 1)(fixed_point_size - 2 downto 0)) & '0');
				else
					output_aux_pipelined_reg(I - 1)                                 := output_pipelined_reg(I - 1);
					output_aux_pipelined_reg(I - 1)(fixed_point_size - 1 - (I - 2)) := '1';
					output_pipelined_reg(I)                                         <= output_aux_pipelined_reg(I - 1);
					sub_pipelined_reg(I - 1)                                        := dividend_pipelined_reg(I - 1) - divisor_pipelined_reg(I - 1);
					dividend_pipelined_reg(I)                                       <= unsigned(std_logic_vector(sub_pipelined_reg(I - 1)(fixed_point_size - 2 downto 0)) & '0');
				end if;
				output_sign_pipelined_reg(I)         <= output_sign_pipelined_reg(I - 1);
				divisor_pipelined_reg(I)             <= divisor_pipelined_reg(I - 1);
				exponent_differente_pipelined_reg(I) <= exponent_differente_pipelined_reg(I - 1);
				request_id_pipelined_reg(I)          <= request_id_pipelined_reg(I - 1);
				new_operation_pipelined_reg(I)       <= new_operation_pipelined_reg(I - 1);
			end loop;

			-- stage 35

			output_shift :=  fixed_point_size - fraction_size - 1 + to_integer(exponent_differente_pipelined_reg(number_of_stages - 1));
			if(output_shift < 0) then
				output_shift := 0;
			elsif(output_shift > 32) then
				output_shift := 32;
			end if;
			
			if (output_sign_pipelined_reg(number_of_stages - 1) = '0') then
				output <= signed(shift_right(output_pipelined_reg(number_of_stages - 1), output_shift));
			else
				output <= -signed(shift_right(output_pipelined_reg(number_of_stages - 1), output_shift));
			end if;
			--output <= signed(output_pipelined_reg(number_of_stages - 1));
			op_id_out <= request_id_pipelined_reg(number_of_stages - 1);
			op_ready  <= new_operation_pipelined_reg(number_of_stages - 1);

		end if;
	end process;
end architecture RTL;

--			-- stage 2
--
--			if (dividend_pipelined_reg(0) < divisor_pipelined_reg(0)) then
--				output_pipelined_reg(0)(0) <= '0';
--				dividend_pipelined_reg(1)  <= signed(std_logic_vector(dividend_pipelined_reg(0)(fixed_point_size - 2 downto 0)) & '0');
--			else
--				output_pipelined_reg(0)(0) <= '1';
--				sub_pipelined_reg(0)       := dividend_pipelined_reg(0) - divisor_pipelined_reg(0);
--				dividend_pipelined_reg(1)  <= signed(std_logic_vector(sub_pipelined_reg(0)(fixed_point_size - 2 downto 0)) & '0');
--			end if;
--			divisor_pipelined_reg(1)       <= divisor_pipelined_reg(0);
--			output_pipelined_reg(1)        <= output_pipelined_reg(0);
--			request_id_pipelined_reg(1)    <= request_id_pipelined_reg(0);
--			new_operation_pipelined_reg(1) <= new_operation_pipelined_reg(0);
--
--			-- stage 3
--
--			if (dividend_pipelined_reg(1) < divisor_pipelined_reg(1)) then
--				output_pipelined_reg(1)(1) <= '0';
--				dividend_pipelined_reg(2)  <= signed(std_logic_vector(dividend_pipelined_reg(1)(fixed_point_size - 2 downto 0)) & '0');
--			else
--				output_pipelined_reg(1)(1) <= '1';
--				sub_pipelined_reg(1)       := dividend_pipelined_reg(1) - divisor_pipelined_reg(1);
--				dividend_pipelined_reg(2)  <= signed(std_logic_vector(sub_pipelined_reg(1)(fixed_point_size - 2 downto 0)) & '0');
--			end if;
--			divisor_pipelined_reg(2)       <= divisor_pipelined_reg(1);
--			output_pipelined_reg(2)        <= output_pipelined_reg(1);
--			request_id_pipelined_reg(2)    <= request_id_pipelined_reg(1);
--			new_operation_pipelined_reg(2) <= new_operation_pipelined_reg(1);

