library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Floating_point_definition.all;
use work.FPU_utility_functions.all;
use work.Synthesis_definitions_pack.all;
use work.request_id_pack.all;

entity Floating_Point_Multiplier is
	port(clk       : in  std_logic;
		 opa       : in  floating_point;
		 opb       : in  floating_point;
		 output    : out floating_point;
		 new_op    : in  std_logic;
		 op_id_in  : in  request_id;
		 op_id_out : out request_id;
		 op_ready  : out std_logic);
end entity Floating_Point_Multiplier;

architecture RTL of Floating_Point_Multiplier is
	-- LATENCIA = 5 clks
	constant number_of_stages : integer := 5;
	--type output_pipelined is array (number_of_stages - 1 downto 0) of fixed_point;
	--signal output_pipelined_reg : output_pipelined;
	type request_id_pipelined is array (number_of_stages - 1 downto 0) of request_id;
	signal request_id_pipelined_reg    : request_id_pipelined;
	signal new_operation_pipelined_reg : std_logic_vector(number_of_stages - 1 downto 0) := std_logic_vector(to_unsigned(0, number_of_stages));

	type exponent_pipelined_type is array (number_of_stages - 1 downto 0) of unsigned(exponent_size - 1 downto 0);

	signal sign_pipelined     : std_logic_vector(number_of_stages - 1 downto 0);
	signal exponent_pipelined : exponent_pipelined_type;

	signal operator_a_up   : unsigned(maximum_multiplier_width - 1 downto 0);
	signal operator_a_down : unsigned(maximum_multiplier_width - 1 downto 0);
	signal operator_b_up   : unsigned(maximum_multiplier_width - 1 downto 0);
	signal operator_b_down : unsigned(maximum_multiplier_width - 1 downto 0);

	signal a_downXb_down : unsigned(maximum_multiplier_width * 2 - 1 downto 0);
	signal a_upXb_down   : unsigned(maximum_multiplier_width * 2 - 1 downto 0);
	signal a_downXb_up   : unsigned(maximum_multiplier_width * 2 - 1 downto 0);
	signal a_upXb_up     : unsigned(maximum_multiplier_width * 2 - 1 downto 0);

	signal sum1     : unsigned(maximum_multiplier_width * 4 - 1 downto 0);
	signal sum2     : unsigned(maximum_multiplier_width * 4 - 1 downto 0);
	signal sum3     : unsigned(maximum_multiplier_width * 4 - 1 downto 0);
	signal sum3_slv : std_logic_vector(maximum_multiplier_width * 4 - 1 downto 0);

begin
	process(clk)
		variable sum3_leading_zeros : integer := 0;
	begin
		if (rising_edge(clk)) then
			-- 1 stage
			if (new_op = '1') then
				sign_pipelined(0)     <= opa.sign xor opb.sign;
				exponent_pipelined(0) <= opa.exponent + opb.exponent;

				operator_a_up   <= unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width - mantissa_size + maximum_multiplier_width - 1)) & '1' & std_logic_vector(opa.mantissa(mantissa_size - 1 downto maximum_multiplier_width)));
				operator_a_down <= opa.mantissa(maximum_multiplier_width - 1 downto 0);
				operator_b_up   <= unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width - mantissa_size + maximum_multiplier_width - 1)) & '1' & std_logic_vector(opb.mantissa(mantissa_size - 1 downto maximum_multiplier_width)));
				operator_b_down <= opb.mantissa(maximum_multiplier_width - 1 downto 0);

				request_id_pipelined_reg(0)    <= op_id_in;
				new_operation_pipelined_reg(0) <= '1';
			else
				request_id_pipelined_reg(0)    <= to_signed(0, request_id_size);
				new_operation_pipelined_reg(0) <= '0';
			end if;

			-- 2 stage
			a_downXb_down <= operator_a_down * operator_b_down;
			a_upXb_down   <= operator_a_up * operator_b_down;
			a_downXb_up   <= operator_a_down * operator_b_up;
			a_upXb_up     <= operator_a_up * operator_b_up;

			sign_pipelined(1)     <= sign_pipelined(0);
			exponent_pipelined(1) <= exponent_pipelined(0);

			request_id_pipelined_reg(1)    <= request_id_pipelined_reg(0);
			new_operation_pipelined_reg(1) <= new_operation_pipelined_reg(0);
			-- 3 stage
			sum1                           <= unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width)) & std_logic_vector(a_upXb_down) & std_logic_vector(to_unsigned(0, maximum_multiplier_width))
				) + unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width * 2)) & std_logic_vector(a_downXb_down));

			sign_pipelined(2)     <= sign_pipelined(1);
			exponent_pipelined(2) <= exponent_pipelined(1);

			request_id_pipelined_reg(2)    <= request_id_pipelined_reg(1);
			new_operation_pipelined_reg(2) <= new_operation_pipelined_reg(1);
			-- 4 stage
			sum2                           <= sum1 + unsigned(std_logic_vector(to_unsigned(0, maximum_multiplier_width)) & std_logic_vector(a_downXb_up) & std_logic_vector(to_unsigned(0, maximum_multiplier_width)));

			sign_pipelined(3)     <= sign_pipelined(2);
			exponent_pipelined(3) <= exponent_pipelined(2);

			request_id_pipelined_reg(3)    <= request_id_pipelined_reg(2);
			new_operation_pipelined_reg(3) <= new_operation_pipelined_reg(2);
			-- 5 stage
			sum3                           <= sum2 + unsigned(std_logic_vector(a_upXb_up) & std_logic_vector(to_unsigned(0, maximum_multiplier_width * 2)));
			sum3_slv                       <= std_logic_vector(sum2 + unsigned(std_logic_vector(a_upXb_up) & std_logic_vector(to_unsigned(0, maximum_multiplier_width * 2))));

			sign_pipelined(4)     <= sign_pipelined(3);
			exponent_pipelined(4) <= exponent_pipelined(3);

			request_id_pipelined_reg(4)    <= request_id_pipelined_reg(3);
			new_operation_pipelined_reg(4) <= new_operation_pipelined_reg(3);
			-- 6 stage

			sum3_leading_zeros := count_l_zeros(sum3_slv);
			output.sign        <= sign_pipelined(4);
			output.exponent    <= exponent_pipelined(4) - sum3_leading_zeros;
			output.mantissa    <= shift_left(sum3, sum3_leading_zeros + 1)(maximum_multiplier_width * 4 - 1 downto maximum_multiplier_width * 4 - mantissa_size);
			op_id_out          <= request_id_pipelined_reg(4);
			op_ready           <= new_operation_pipelined_reg(4);

		end if;
	end process;
end architecture RTL;

