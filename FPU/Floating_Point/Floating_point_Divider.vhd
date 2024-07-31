library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Floating_point_definition.all;
use work.FPU_utility_functions.all;
use work.request_id_pack.all;

entity Floating_Point_Divider is
	port(clk       : in  std_logic;
		 opa       : in  floating_point;
		 opb       : in  floating_point;
		 output    : out floating_point;
		 new_op    : in  std_logic;
		 op_id_in  : in  request_id;
		 op_id_out : out request_id;
		 op_ready  : out std_logic);
end entity Floating_Point_Divider;

architecture RTL of Floating_Point_Divider is
	constant number_of_stages : integer := mantissa_size+2; --mantissa_size+1;
	type output_mantissa_pipelined is array (number_of_stages - 1 downto 0) of unsigned(mantissa_size + 1 downto 0);
	signal output_mantissa_pipelined_reg   : output_mantissa_pipelined;
	signal output_sign_pipelined_reg       : std_logic_vector(number_of_stages - 1 downto 0);
	signal dividend_mantissa_pipelined_reg : output_mantissa_pipelined;
	signal divisor_mantissa_pipelined_reg  : output_mantissa_pipelined;
	type request_id_pipelined is array (number_of_stages - 1 downto 0) of request_id;
	signal request_id_pipelined_reg    : request_id_pipelined;
	signal new_operation_pipelined_reg : std_logic_vector(number_of_stages - 1 downto 0) := std_logic_vector(to_unsigned(0, number_of_stages));
	type output_exponent_pipelined is array (number_of_stages - 1 downto 0) of unsigned(exponent_size - 1 downto 0);
	signal output_exponent_pipelined_reg : output_exponent_pipelined;
begin
	process(clk)
		variable sub_pipelined_reg        : output_mantissa_pipelined;
		variable output_aux_pipelined_reg : output_mantissa_pipelined;
		variable output_mantissa_zeros    : integer := 0;
	begin
		if (rising_edge(clk)) then
			-- 0 stage
			if (new_op = '1') then
				if (opb.mantissa = 0 and opb.exponent = 0) then
					dividend_mantissa_pipelined_reg(0) <= to_unsigned(0, mantissa_size + 2);
					divisor_mantissa_pipelined_reg(0)  <= to_unsigned(0, mantissa_size + 2);
					output_mantissa_pipelined_reg(0)   <= to_unsigned(0, mantissa_size + 2);
					output_sign_pipelined_reg(0)       <= '0';
					output_exponent_pipelined_reg(0)   <= to_unsigned(0, exponent_size);

					request_id_pipelined_reg(0)    <= op_id_in;
					new_operation_pipelined_reg(0) <= '1';
				else
					dividend_mantissa_pipelined_reg(0) <= unsigned("01" & std_logic_vector(opa.mantissa));
					divisor_mantissa_pipelined_reg(0)  <= unsigned("01" & std_logic_vector(opb.mantissa));
					output_mantissa_pipelined_reg(0)   <= to_unsigned(0, mantissa_size + 2);

					output_sign_pipelined_reg(0) <= opa.sign xor opb.sign;

					output_exponent_pipelined_reg(0) <= opa.exponent - opb.exponent;

					request_id_pipelined_reg(0)    <= op_id_in;
					new_operation_pipelined_reg(0) <= '1';

				end if;
			else
				request_id_pipelined_reg(0)    <= request_id_zero;
				new_operation_pipelined_reg(0) <= '0';
			end if;

			-- stage 1 - 32  32 restas ??

			for I in mantissa_size downto 1 loop
				if (dividend_mantissa_pipelined_reg(I - 1) < divisor_mantissa_pipelined_reg(I - 1)) then
					output_aux_pipelined_reg(I - 1)                              := output_mantissa_pipelined_reg(I - 1);
					output_aux_pipelined_reg(I - 1)(mantissa_size + 1 - (I - 1)) := '0';
					output_mantissa_pipelined_reg(I)                             <= output_aux_pipelined_reg(I - 1);
					dividend_mantissa_pipelined_reg(I)                           <= unsigned(std_logic_vector(dividend_mantissa_pipelined_reg(I - 1)(mantissa_size downto 0)) & '0');
				else
					output_aux_pipelined_reg(I - 1)                              := output_mantissa_pipelined_reg(I - 1);
					output_aux_pipelined_reg(I - 1)(mantissa_size + 1 - (I - 1)) := '1';
					output_mantissa_pipelined_reg(I)                             <= output_aux_pipelined_reg(I - 1);
					sub_pipelined_reg(I - 1)                                     := dividend_mantissa_pipelined_reg(I - 1) - divisor_mantissa_pipelined_reg(I - 1);
					dividend_mantissa_pipelined_reg(I)                           <= unsigned(std_logic_vector(sub_pipelined_reg(I - 1)(mantissa_size downto 0)) & '0');
				end if;
				output_sign_pipelined_reg(I)      <= output_sign_pipelined_reg(I - 1);
				output_exponent_pipelined_reg(I)  <= output_exponent_pipelined_reg(I - 1);
				divisor_mantissa_pipelined_reg(I) <= divisor_mantissa_pipelined_reg(I - 1);
				request_id_pipelined_reg(I)       <= request_id_pipelined_reg(I - 1);
				new_operation_pipelined_reg(I)    <= new_operation_pipelined_reg(I - 1);
			end loop;

			-- stage 35  normalizo
			output_mantissa_zeros                               := count_l_zeros(output_mantissa_pipelined_reg(number_of_stages - 2));
			output_mantissa_pipelined_reg(number_of_stages - 1) <= shift_left(output_mantissa_pipelined_reg(number_of_stages - 2), output_mantissa_zeros);
			output_exponent_pipelined_reg(number_of_stages - 1) <= output_exponent_pipelined_reg(number_of_stages - 2) - output_mantissa_zeros;

			output_sign_pipelined_reg(number_of_stages - 1)     <= output_sign_pipelined_reg(number_of_stages - 2);
			output_exponent_pipelined_reg(number_of_stages - 1) <= output_exponent_pipelined_reg(number_of_stages - 2);
			request_id_pipelined_reg(number_of_stages - 1)      <= request_id_pipelined_reg(number_of_stages - 2);
			new_operation_pipelined_reg(number_of_stages - 1)   <= new_operation_pipelined_reg(number_of_stages - 2);

			-- stage 36 salida!
			output.sign     <= output_sign_pipelined_reg(number_of_stages - 1);
			output.exponent <= output_exponent_pipelined_reg(number_of_stages - 1);
			output.mantissa <= output_mantissa_pipelined_reg(number_of_stages - 1)(mantissa_size + 1 downto 2);

			op_id_out <= request_id_pipelined_reg(number_of_stages - 1);
			op_ready  <= new_operation_pipelined_reg(number_of_stages - 1);

		end if;
	end process;
end architecture RTL;
