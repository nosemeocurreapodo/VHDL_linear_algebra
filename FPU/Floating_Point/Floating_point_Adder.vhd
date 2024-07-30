library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.request_id_pack.all;
use work.Floating_point_definition.all;
use work.FPU_utility_functions.all;

entity Floating_point_Adder is
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
end entity Floating_point_Adder;

architecture RTL of Floating_point_Adder is

	-- stage 1
	signal opa_sign_1      : std_logic;
	signal opb_sign_1      : std_logic;
	signal opa_exponent_1  : unsigned(exponent_size - 1 downto 0);
	signal opb_exponent_1  : unsigned(exponent_size - 1 downto 0);
	signal opa_mantissa_1  : unsigned(mantissa_size - 1 downto 0);
	signal opb_mantissa_1  : unsigned(mantissa_size - 1 downto 0);

	signal request_id_1      : request_id;
	signal new_operation_1   : std_logic;

	-- stage 2
	signal opa_exponent_2  : unsigned(exponent_size - 1 downto 0);
	signal opb_exponent_2  : unsigned(exponent_size - 1 downto 0);
	signal opa_mantissa_2  : signed(mantissa_size + 2 downto 0);
	signal opb_mantissa_2  : signed(mantissa_size + 2 downto 0);
	signal exponent_diff_2 : unsigned(exponent_size - 1 downto 0);

	signal request_id_2      : request_id;
	signal new_operation_2   : std_logic;

	-- stage 3
	signal opa_mantissa_3    : signed(mantissa_size + 2 downto 0);
	signal opb_mantissa_3    : signed(mantissa_size + 2 downto 0);
	signal output_exponent_3 : unsigned(exponent_size - 1 downto 0);

	signal request_id_3      : request_id;
	signal new_operation_3   : std_logic;

	-- stage 4
	signal output_mantissa_4 : signed(mantissa_size + 2 downto 0);
	signal output_exponent_4 : unsigned(exponent_size - 1 downto 0);

	signal request_id_4      : request_id;
	signal new_operation_4   : std_logic;

	-- stage 5
	signal output_sign_5     : std_logic;
	signal output_exponent_5 : unsigned(exponent_size - 1 downto 0);
	signal output_mantissa_5 : unsigned(mantissa_size + 2 downto 0);

	signal request_id_5    : request_id;
	signal new_operation_5 : std_logic;

	-- stage 6
	signal output_sign_6     : std_logic;
	signal output_exponent_6 : unsigned(exponent_size - 1 downto 0);
	signal output_mantissa_6 : unsigned(mantissa_size + 2 downto 0);

	signal output_mantissa_lz_6 : integer;

	signal request_id_6    : request_id;
	signal new_operation_6 : std_logic;

	-- stage 7
	signal output_sign_7     : std_logic;
	signal output_exponent_7 : unsigned(exponent_size - 1 downto 0);
	signal output_mantissa_7 : unsigned(mantissa_size + 2 downto 0);

	signal request_id_7    : request_id;
	signal new_operation_7 : std_logic;

begin
	process(clk)
	begin
		if (rising_edge(clk)) then
			-- stage 1
			if (opa.exponent >= opb.exponent) then
				opa_sign_1 <= opa.sign;
				opb_sign_1 <= opb.sign;
				opa_exponent_1 <= opa.exponent;
				opb_exponent_1 <= opb.exponent;
				opa_mantissa_1 <= opa.mantissa;
				opb_mantissa_1 <= opb.mantissa;
			else
				opa_sign_1 <= opb.sign;
				opb_sign_1 <= opa.sign;
				opa_exponent_1 <= opb.exponent;
				opb_exponent_1 <= opa.exponent;
				opa_mantissa_1 <= opb.mantissa;
				opb_mantissa_1 <= opa.mantissa;
			end if;

			if (new_op = '1') then
				request_id_1    <= op_id_in;
				new_operation_1 <= '1';
			else
				request_id_1    <= request_id_zero;
				new_operation_1 <= '0';
			end if;

			-- stage 2
			-- de normalizo
			exponent_diff_2 <= opa_exponent_1 - opb_exponent_1;

			if (opa_sign_1 = '0') then -- de normalized number
				opa_mantissa_2 <= signed("001" & std_logic_vector(opa_mantissa_1));
			else
				opa_mantissa_2 <= signed("111" & std_logic_vector(opa_mantissa_1));
			end if;

			if (opb_sign_1 = '0') then
				opb_mantissa_2 <= signed("001" & std_logic_vector(opb_mantissa_1));
			else
				opb_mantissa_2 <= signed("111" & std_logic_vector(opb_mantissa_1));
			end if;

			request_id_2    <= request_id_1;
			new_operation_2 <= new_operation_1;

			-- stage 3 shift_right
			opb_mantissa_3    <= shift_right(opb_mantissa_2, to_integer(exponent_diff_2));
			opa_mantissa_3    <= opa_mantissa_2;
			output_exponent_3 <= opa_exponent_2;

			request_id_3    <= request_id_2;
			new_operation_3 <= new_operation_2;

			-- stage 4 suma
			output_mantissa_4 <= opa_mantissa_3 + opb_mantissa_3;
			output_exponent_4 <= output_exponent_3;

			request_id_4    <= request_id_3;
			new_operation_4 <= new_operation_3;

			-- stage 5 calculo el signo
			if (output_mantissa_4 >= 0) then
				output_sign_5 <= '0';
			else
				output_sign_5 <= '1';
			end if;

			output_mantissa_5 <= unsigned(abs (output_mantissa_4));
			output_exponent_5 <= output_exponent_4;

			request_id_5    <= request_id_4;
			new_operation_5 <= new_operation_4;

			-- stage 6 computo lz
			output_sign_6        <= output_sign_5;
			output_mantissa_lz_6 <= count_l_zeros(output_mantissa_5);
			output_exponent_6    <= output_exponent_5;
			output_mantissa_6    <= output_mantissa_5;

			request_id_6    <= request_id_5;
			new_operation_6 <= new_operation_5;

			-- stage 7 normalizando
			output_sign_7      <= output_sign_6;
			output_mantissa_7  <= shift_left(output_mantissa_6, output_mantissa_lz_6 + 1);
			output_exponent_7  <= output_exponent_6 - output_mantissa_lz_6 + 2;

			request_id_7    <= request_id_6;
			new_operation_7 <= new_operation_6;

			-- stage 6 salida!
			output.sign     <= output_sign_7;
			output.exponent <= output_exponent_7;
			output.mantissa <= output_mantissa_7(mantissa_size + 2 downto 3);

			op_id_out <= request_id_7;
			op_ready  <= new_operation_7;
		end if;
	end process;
end architecture RTL;